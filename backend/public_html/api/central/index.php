<?php
declare(strict_types=1);
ini_set('display_errors', '0');
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');
function response(array $data, int $status = 200): never {
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_SLASHES | JSON_INVALID_UTF8_SUBSTITUTE);
    exit;
}
function failure(int $status, string $code, string $message): never {
    response(['error'=>['code'=>$code,'message'=>$message]], $status);
}
function optionalWalletSnapshot(PDO $pdo,int $accountId): array {
    $link=$pdo->prepare('SELECT wallet_user_id FROM nu_account_wallet_links WHERE account_id=?');
    $link->execute([$accountId]);
    $walletId=(int)$link->fetchColumn();
    if($walletId<1)return ['wallet_id'=>0,'wallet'=>null];
    $stmt=$pdo->prepare("SELECT a.balance_minor,a.currency,a.status FROM nu_cwallet_accounts a JOIN nu_cwallet_users u ON u.id=a.wallet_user_id WHERE a.wallet_user_id=? AND a.currency='NGN' AND u.status='active'");
    $stmt->execute([$walletId]);
    $wallet=$stmt->fetch(PDO::FETCH_ASSOC);
    if(!$wallet)return ['wallet_id'=>$walletId,'wallet'=>null];
    $history=$pdo->prepare('SELECT ledger_reference,entry_type,amount_minor,currency,description,service_code,created_at FROM nu_cwallet_ledger WHERE wallet_user_id=? ORDER BY id DESC LIMIT 50');
    $history->execute([$walletId]);
    $transactions=[];
    foreach($history->fetchAll(PDO::FETCH_ASSOC) as $row){
        $transactions[]=['reference'=>$row['ledger_reference'],'type'=>$row['entry_type'],'amount_kobo'=>(int)$row['amount_minor'],'currency'=>$row['currency'],'title'=>$row['description'] ?: $row['entry_type'],'service'=>$row['service_code'],'created_at'=>$row['created_at'],'status'=>'posted'];
    }
    return ['wallet_id'=>$walletId,'wallet'=>['balance_kobo'=>(int)$wallet['balance_minor'],'currency'=>$wallet['currency'],'status'=>$wallet['status'],'transactions'=>$transactions]];
}
try {
    $root = dirname(__DIR__, 2);
    require_once $root.'/includes/central-auth.php';
    require_once $root.'/includes/central-wallet-bootstrap.php';
    $pdo = nu_cwallet_pdo();
    $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
    $route = '/'.trim((string)($_GET['route'] ?? ''), '/');
    // Mobile endpoint accepts bearer tokens only, never ambient browser cookies.
    unset($_COOKIE[NU_AUTH_COOKIE]);
    $body = [];
    if ($method === 'POST') {
        $raw = file_get_contents('php://input', false, null, 0, 65537);
        if (strlen($raw ?: '') > 65536) failure(413, 'TOO_LARGE', 'Request is too large.');
        try { $body = json_decode($raw ?: '{}', true, 32, JSON_THROW_ON_ERROR); }
        catch (Throwable $e) { failure(400, 'INVALID_JSON', 'Send a valid request.'); }
        if (!is_array($body)) failure(400, 'INVALID_JSON', 'Send a valid request.');
    }
    if ($method === 'POST' && $route === '/auth/login') {
        $identifier = $body['email'] ?? '';
        $password = $body['password'] ?? '';
        if (!is_string($identifier) || !is_string($password) || strlen($identifier)>191 || strlen($password)>4096) {
            failure(422, 'INVALID_LOGIN', 'Enter your email or matric number and password.');
        }
        try { nu_auth_login($identifier, $password, true); }
        catch (RuntimeException $e) { failure(401, 'LOGIN_FAILED', 'Unable to sign in. Check your details, or wait a few minutes before trying again.'); }
        $token = '';
        foreach (headers_list() as $header) {
            if (preg_match('/^Set-Cookie:\s*'.preg_quote(NU_AUTH_COOKIE, '/').'=([a-f0-9]{64})(?:;|$)/i', $header, $m)) $token = $m[1];
        }
        header_remove('Set-Cookie');
        if ($token === '') throw new RuntimeException('Central session was not issued.');
        response(['data'=>['access_token'=>$token,'refresh_token'=>'','identity'=>'central']]);
    }
    if (str_starts_with($route,'/premium') || str_starts_with($route,'/motivation') || $route==='/profile/preferences') {
        require_once $root.'/nu-mobile/companion/service.php';
        $companion=new NuCompanion($pdo);
        if($method==='GET' && $route==='/premium/config') response(['data'=>$companion->configuration()]);
        if($method==='GET' && $route==='/motivation/today') response(['data'=>['quote'=>$companion->dailyQuote()]]);
    }
    $header = (string)($_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '');
    if (!preg_match('/^Bearer ([a-f0-9]{64})$/D', $header, $match)) failure(401,'LOGIN_REQUIRED','Sign in to your NOUN Update account.');
    $_COOKIE[NU_AUTH_COOKIE] = $match[1];
    $account = nu_current_account(true);
    header_remove('Set-Cookie');
    if (!$account) failure(401,'LOGIN_REQUIRED','Your session has expired. Please sign in again.');
    $accountId=(int)$account['id'];
    if ($method === 'POST' && $route === '/auth/logout') {
        $stmt=$pdo->prepare('UPDATE nu_auth_sessions SET revoked_at=NOW() WHERE token_hash=? AND account_id=?');
        $stmt->execute([hash('sha256',$match[1]),$accountId]);
        response(['data'=>['signed_out'=>true]]);
    }
    if ($route==='/workspace') {
        require_once $root.'/nu-mobile/workspace/service.php';
        $workspace=new NuStudentWorkspace($pdo);
        if ($method==='GET') response(['data'=>$workspace->get($accountId)]);
        if ($method==='POST') {
            try { response(['data'=>$workspace->save($accountId,$body)]); }
            catch (RuntimeException $e) {
                if ($e->getMessage()==='WORKSPACE_CONFLICT') failure(409,'WORKSPACE_CONFLICT','Your student workspace changed on another device. Refresh and save again.');
                throw $e;
            }
        }
        failure(405,'METHOD_NOT_ALLOWED','This workspace request is not supported.');
    }
    if ($route==='/profile/settings') {
        require_once $root.'/nu-mobile/account-settings/service.php';
        $settings=new NuAccountSettings($pdo);
        try {
            if($method==='GET')response(['data'=>$settings->get($accountId)]);
            if($method==='POST')response(['data'=>$settings->save($accountId,$body)]);
        } catch(InvalidArgumentException $e) {
            failure(422,'INVALID_ACCOUNT_SETTINGS',$e->getMessage());
        }
        failure(405,'METHOD_NOT_ALLOWED','This settings request is not supported.');
    }
    if (preg_match('#^/study/([A-Z]{2,5}[0-9]{3})/state$#D',$route,$studyMatch)) {
        require_once $root.'/nu-mobile/study-state/service.php';
        $studyState=new NuStudyState($pdo);
        try {
            if($method==='GET')response(['data'=>$studyState->get($accountId,$studyMatch[1])]);
            if($method==='POST')response(['data'=>$studyState->save($accountId,$studyMatch[1],$body)]);
        } catch(InvalidArgumentException $e) {
            failure(422,'INVALID_STUDY_STATE',$e->getMessage());
        } catch(RuntimeException $e) {
            if($e->getMessage()==='STUDY_STATE_CONFLICT')failure(409,'STUDY_STATE_CONFLICT','Your study progress changed on another device. Review the latest notes before saving again.');
            throw $e;
        }
        failure(405,'METHOD_NOT_ALLOWED','This study progress request is not supported.');
    }
    if(isset($companion)) {
        if($method==='GET' && $route==='/premium/status') response(['data'=>$companion->entitlement($accountId)]);
        if($method==='GET' && $route==='/profile/preferences') response(['data'=>$companion->preferences($accountId)]);
        if($method==='POST' && $route==='/profile/preferences') response(['data'=>$companion->savePreferences($accountId,$body)]);
        if($method==='GET' && $route==='/motivation/saved') response(['data'=>['items'=>$companion->savedQuotes($accountId)]]);
        if($method==='POST' && $route==='/motivation/saved') {
            if(!is_int($body['quote_id']??null)||!is_bool($body['saved']??null))throw new InvalidArgumentException('Send a valid quote selection.');
            $companion->saveQuote($accountId,$body['quote_id'],$body['saved']);
            response(['data'=>['saved'=>$body['saved']]]);
        }
        if($method==='GET' && ($route==='/premium/analytics/mock' || $route==='/premium/analytics/pop')) {
            $entitlement=$companion->entitlement($accountId);
            $feature=$route==='/premium/analytics/mock'?'mock_analytics':'pop_analytics';
            if(empty($entitlement['active']) || empty($entitlement['features'][$feature])) {
                failure(403,'PREMIUM_FEATURE_REQUIRED','Active NOUN Update Premium is required for this analytics view. Your exam practice remains available without this analytics layer.');
            }
            $email=trim((string)($account['email']??''));
            if(!filter_var($email,FILTER_VALIDATE_EMAIL))failure(409,'ACCOUNT_EMAIL_REQUIRED','Add a valid email to your central account before loading analytics.');
            require_once $root.'/nu-mobile/companion/analytics.php';
            $analytics=new NuPremiumAnalytics($pdo,NuPremiumAnalytics::mockPdoFromEnvironment());
            response(['data'=>$feature==='mock_analytics'?$analytics->mock($email):$analytics->pop($email)]);
        }
    }
    if ($method==='GET' && $route==='/app/bootstrap') {
        require_once $root.'/nu-mobile/workspace/service.php';
        require_once $root.'/nu-mobile/account-settings/service.php';
        $bootstrapWorkspace=(new NuStudentWorkspace($pdo))->get($accountId);
        $bootstrapSettings=(new NuAccountSettings($pdo))->get($accountId);
        $walletSnapshot=optionalWalletSnapshot($pdo,$accountId);
        response(['data'=>[
            'profile'=>['id'=>$accountId,'name'=>$account['display_name'] ?: 'Student','email'=>$account['email']],
            'wallet'=>$walletSnapshot['wallet'],
            'workspace'=>$bootstrapWorkspace,
            'settings'=>$bootstrapSettings,
            'feature_flags'=>[
                'central_account'=>true,
                'wallet_linked'=>$walletSnapshot['wallet_id']>0,
                'wallet_available'=>$walletSnapshot['wallet']!==null,
                'wallet_funding'=>false,
                'wallet_purchases'=>false,
                'premium_wallet_purchase'=>true,
                'premium_analytics'=>true,
                'workspace_sync'=>true,
                'study_progress_sync'=>true,
                'account_settings_sync'=>true,
            ]
        ]]);
    }
    // Wallet and purchase operations below this point require an established link.
    $walletSnapshot=optionalWalletSnapshot($pdo,$accountId);
    $walletId=(int)$walletSnapshot['wallet_id'];
    if ($walletId < 1) failure(409,'WALLET_LINK_REQUIRED','Your account needs a wallet link. Please contact support.');
    $result=$walletSnapshot['wallet'];
    if (!is_array($result)) failure(409,'WALLET_UNAVAILABLE','Your wallet is not available. Please contact support.');
    if(isset($companion) && $method==='POST' && $route==='/premium/purchase') {
        $plan=$body['plan_id']??null;$price=$body['expected_price_minor']??null;$currency=$body['expected_currency']??null;
        $requestKey=(string)($_SERVER['HTTP_IDEMPOTENCY_KEY']??'');
        if(!is_string($plan)||!is_int($price)||!is_string($currency))failure(422,'INVALID_PURCHASE','Refresh Premium plans and try again.');
        $purchase=$companion->purchase($accountId,$walletId,$plan,$price,$currency,$requestKey);
        $purchase['entitlement']=$companion->entitlement($accountId);
        response(['data'=>$purchase]);
    }
    if ($method==='GET' && $route==='/wallet') response(['data'=>$result]);
    failure(503,'NOT_AVAILABLE','This feature is being connected to your central account. Please try again later.');
} catch (NuCompanionException $e) {
    failure($e->status,$e->reason,$e->getMessage());
} catch (InvalidArgumentException $e) {
    failure(422,'INVALID_PREFERENCE',$e->getMessage());
} catch (Throwable $e) {
    error_log('[CENTRAL MOBILE API] '.$e->getMessage());
    failure(503,'UNAVAILABLE','The account service is temporarily unavailable. Please try again shortly.');
}
