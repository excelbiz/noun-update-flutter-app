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
        // Reuse the website's password validation, rate limits and session issuance.
        // Its helper emits an opaque token as a cookie; expose it only in this
        // authenticated JSON response, and suppress browser cookie side effects.
        $token = '';
        foreach (headers_list() as $header) {
            if (preg_match('/^Set-Cookie:\s*'.preg_quote(NU_AUTH_COOKIE, '/').'=([a-f0-9]{64})(?:;|$)/i', $header, $m)) $token = $m[1];
        }
        header_remove('Set-Cookie');
        if ($token === '') throw new RuntimeException('Central session was not issued.');
        response(['data'=>['access_token'=>$token,'refresh_token'=>'','identity'=>'central']]);
    }
    $header = (string)($_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '');
    if (!preg_match('/^Bearer ([a-f0-9]{64})$/D', $header, $match)) failure(401,'LOGIN_REQUIRED','Sign in to your NOUN Update account.');
    $_COOKIE[NU_AUTH_COOKIE] = $match[1];
    $account = nu_current_account(true);
    header_remove('Set-Cookie');
    if (!$account) failure(401,'LOGIN_REQUIRED','Your session has expired. Please sign in again.');
    if ($method === 'POST' && $route === '/auth/logout') {
        $stmt=$pdo->prepare('UPDATE nu_auth_sessions SET revoked_at=NOW() WHERE token_hash=? AND account_id=?');
        $stmt->execute([hash('sha256',$match[1]),$account['id']]);
        response(['data'=>['signed_out'=>true]]);
    }
    // Use only an established account-wallet link; never infer ownership by email.
    $stmt=$pdo->prepare('SELECT wallet_user_id FROM nu_account_wallet_links WHERE account_id=?');
    $stmt->execute([$account['id']]);
    $walletId=(int)$stmt->fetchColumn();
    if ($walletId < 1) failure(409,'WALLET_LINK_REQUIRED','Your account needs a wallet link. Please contact support.');
    $stmt=$pdo->prepare("SELECT a.balance_minor,a.currency,a.status FROM nu_cwallet_accounts a JOIN nu_cwallet_users u ON u.id=a.wallet_user_id WHERE a.wallet_user_id=? AND a.currency='NGN' AND u.status='active'");
    $stmt->execute([$walletId]);
    $wallet=$stmt->fetch(PDO::FETCH_ASSOC);
    if (!$wallet) failure(409,'WALLET_UNAVAILABLE','Your wallet is not available. Please contact support.');
    $stmt=$pdo->prepare('SELECT ledger_reference,entry_type,amount_minor,currency,description,service_code,created_at FROM nu_cwallet_ledger WHERE wallet_user_id=? ORDER BY id DESC LIMIT 50');
    $stmt->execute([$walletId]);
    $transactions=[];
    foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $transactions[]=['reference'=>$row['ledger_reference'],'type'=>$row['entry_type'],'amount_kobo'=>(int)$row['amount_minor'],'currency'=>$row['currency'],'title'=>$row['description'] ?: $row['entry_type'],'service'=>$row['service_code'],'created_at'=>$row['created_at'],'status'=>'posted'];
    }
    $result=['balance_kobo'=>(int)$wallet['balance_minor'],'currency'=>$wallet['currency'],'status'=>$wallet['status'],'transactions'=>$transactions];
    if ($method==='GET' && $route==='/wallet') response(['data'=>$result]);
    if ($method==='GET' && $route==='/app/bootstrap') response(['data'=>[
        'profile'=>['id'=>$account['id'],'name'=>$account['display_name'] ?: 'Student','email'=>$account['email']],
        'wallet'=>$result,'feature_flags'=>['central_account'=>true,'wallet_funding'=>false,'wallet_purchases'=>false]
    ]]);
    failure(503,'NOT_AVAILABLE','This feature is being connected to your central account. Please try again later.');
} catch (Throwable $e) {
    error_log('[CENTRAL MOBILE API] '.$e->getMessage());
    failure(503,'UNAVAILABLE','The account service is temporarily unavailable. Please try again shortly.');
}
