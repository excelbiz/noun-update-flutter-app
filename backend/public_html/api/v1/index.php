<?php
declare(strict_types=1);
ini_set('display_errors','0');
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');
header('Referrer-Policy: no-referrer');
function nu_send(array $data,int $status=200): never {
    http_response_code($status);echo json_encode(['data'=>$data],JSON_UNESCAPED_SLASHES|JSON_INVALID_UTF8_SUBSTITUTE);exit;
}
function nu_body(): array {
    if((int)($_SERVER['CONTENT_LENGTH']??0)>65536)throw new NuFailure(413,'TOO_LARGE','Request is too large.');
    $raw=file_get_contents('php://input',false,null,0,65537);
    if(strlen($raw?:'')>65536)throw new NuFailure(413,'TOO_LARGE','Request is too large.');
    try{$v=json_decode($raw?:'{}',true,64,JSON_THROW_ON_ERROR);}catch(Throwable $e){throw new NuFailure(400,'INVALID_JSON','Send a valid JSON object.');}
    if(!is_array($v)||array_is_list($v)&&$v!==[])throw new NuFailure(400,'INVALID_JSON','Send a JSON object.');return $v;
}
try {
    require_once dirname(__DIR__,2).'/nu-mobile/bootstrap.php';
    $method=$_SERVER['REQUEST_METHOD']??'GET';
    $path=parse_url($_SERVER['REQUEST_URI']??'',PHP_URL_PATH)?:'';
    $path='/'.trim(preg_replace('#^/api/v1(?:/index\.php)?#','',$path)??'','/');
    // Query-route fallback works on hosts where RewriteRule is unavailable.
    if(isset($_GET['route']))$path='/'.trim((string)$_GET['route'],'/');
    if($method==='GET'&&$path==='/')nu_send(['name'=>'NOUN Update mobile API','version'=>'1.0','health_url'=>'/api/v1/health','logo_url'=>$nuConfig['site_url'].'/images/logo.webp']);
    if($method==='GET'&&$path==='/services')nu_send(['items'=>nu_services($nuConfig)]);
    $db=nu_connect($nuConfig['wallet_db']);
    $content=nu_connect($nuConfig['content_db']);
    $store=new NuStore($db,$content,$nuConfig);
    if($method==='GET'&&$path==='/health'){
        $store->transactional(['summary_users','summary_transactions','nu_app_sessions','nu_app_orders','nu_app_order_items','nu_app_quotes']);
        nu_send(['status'=>'ok','version'=>'1.0']);
    }
    $ip=(string)($_SERVER['REMOTE_ADDR']??'unknown');
    if($method==='POST'&&$path==='/auth/login'){$b=nu_body();nu_send($store->login((string)($b['email']??''),(string)($b['password']??''),$ip));}
    if($method==='POST'&&$path==='/auth/refresh'){$store->rate('refresh',$ip,60,900);$b=nu_body();nu_send($store->refresh((string)($b['refresh_token']??'')));}
    if($method==='GET'&&preg_match('#^/posts/([a-z]+)(?:/([0-9]+))?$#D',$path,$m)){
        nu_send(nu_posts($content,$nuConfig,$m[1],(int)($_GET['page']??1),isset($m[2])?(int)$m[2]:null));
    }
    if($method==='GET'&&$path==='/exam-summaries')nu_send(nu_exam_catalogue($content,(string)($_GET['q']??''),(int)($_GET['page']??1)));
    if($method==='GET'&&$path==='/calendar'){
        $file=$nuConfig['root'].'/academic-calendar-core/calendar.php';
        if(!is_file($file))throw new NuFailure(503,'UNAVAILABLE','The calendar is temporarily unavailable.');
        require_once $file;nu_send(nac_public(nac_read()));
    }
    if($method==='GET'&&$path==='/download'){
        $file=$store->takeDownload((string)($_GET['ticket']??''));
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="'.preg_replace('/[^A-Za-z0-9._-]/','_',$file['name']).'"');
        header('Content-Length: '.filesize($file['path']));readfile($file['path']);exit;
    }
    $header=(string)($_SERVER['HTTP_AUTHORIZATION']??$_SERVER['REDIRECT_HTTP_AUTHORIZATION']??'');
    $token=preg_match('/^Bearer ([a-f0-9]+)$/D',$header,$m)?$m[1]:'';
    $u=$token!==''?$store->authenticate($token):null;
    if($method==='GET'&&$path==='/app/bootstrap'){
        nu_send(['profile'=>$u?$store->profile($u):null,'services'=>nu_services($nuConfig),
            'logo_url'=>$nuConfig['site_url'].'/images/logo.webp',
            'wallet'=>$u?$store->wallet((int)$u['id']):null,'feature_flags'=>['quizly'=>false,'live_content'=>true,'exam_summary_wallet'=>true,'course_summary_wallet'=>true]]);
    }
    if(!$u)throw new NuFailure(401,'LOGIN_REQUIRED','Sign in using your Course Summary account.');
    $uid=(int)$u['id'];
    if($method==='POST'&&$path==='/auth/logout'){$store->run('UPDATE nu_app_sessions SET revoked=1 WHERE id=?',[$u['session_id']]);nu_send(['signed_out'=>true]);}
    if($method==='GET'&&$path==='/wallet')nu_send($store->wallet($uid));
    if($method==='POST'&&$path==='/wallet/fund'){
        $store->rate('fund',(string)$uid,15,900);$b=nu_body();
        if(!is_int($b['amount_kobo']??null))throw new NuFailure(422,'INVALID_AMOUNT','amount_kobo must be an integer.');
        nu_send($store->fund($u,$b['amount_kobo'],(string)($_SERVER['HTTP_IDEMPOTENCY_KEY']??'')));
    }
    if($method==='POST'&&preg_match('#^/wallet/fund/(NUW-[0-9]+-[A-F0-9]{20})/verify$#D',$path,$m)){
        $store->rate('verify',(string)$uid,30,900);nu_send($store->verifyFunding($uid,$m[1]));
    }
    if($method==='POST'&&$path==='/exam-summaries/quote'){
        $store->rate('quote',(string)$uid,60,900);$b=nu_body();
        if(!is_array($b['file_ids']??null))throw new NuFailure(422,'INVALID_CART','file_ids must be an array.');
        nu_send($store->quote($uid,$b['file_ids']));
    }
    if($method==='POST'&&$path==='/exam-summaries/purchase'){
        $b=nu_body();nu_send($store->purchase($uid,(string)($b['quote_id']??''),(string)($_SERVER['HTTP_IDEMPOTENCY_KEY']??'')));
    }
    if($method==='GET'&&$path==='/orders')nu_send(['items'=>$store->run('SELECT id,reference,total_kobo,created_at FROM nu_app_orders WHERE user_id=? ORDER BY id DESC LIMIT 100',[$uid])->fetchAll()]);
    if($method==='GET'&&preg_match('#^/orders/([0-9]+)$#D',$path,$m))nu_send($store->order($uid,(int)$m[1]));
    if($method==='POST'&&preg_match('#^/downloads/([0-9]+)$#D',$path,$m))nu_send($store->downloadTicket($uid,(int)$m[1]));
    throw new NuFailure(404,'NOT_FOUND','API route not found.');
}catch(Throwable $e){
    $known=$e instanceof NuFailure;$status=$known?$e->status:503;
    $requestId=bin2hex(random_bytes(8));
    if(!$known)error_log('NU mobile request '.$requestId.' failed: '.get_class($e));
    http_response_code($status);
    if($status===429)header('Retry-After: 900');
    echo json_encode(['error'=>['code'=>$known?$e->reason:'SERVICE_UNAVAILABLE',
        'message'=>$known?$e->getMessage():'This service is temporarily unavailable. Please retry shortly.', 'request_id'=>$requestId]]);
}
