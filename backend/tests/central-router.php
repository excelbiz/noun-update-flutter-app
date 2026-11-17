<?php
declare(strict_types=1);

// HTTP contract tests with an explicitly isolated authentication fixture.
// This does not test production credentials or replace central-auth.php.
$pdo = new PDO('mysql:host=127.0.0.1;port=3306;charset=utf8mb4', 'root', 'test-only-password', [PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
$pdo->exec('CREATE DATABASE IF NOT EXISTS nu_mobile_router_test CHARACTER SET utf8mb4');
$pdo->exec('USE nu_mobile_router_test');
$pdo->exec(file_get_contents(dirname(__DIR__).'/sql/companion.sql'));
$root=sys_get_temp_dir().'/nu-central-router-'.bin2hex(random_bytes(8));
mkdir($root.'/api/central',0700,true);
mkdir($root.'/includes',0700,true);
copy(dirname(__DIR__).'/public_html/api/central/index.php',$root.'/api/central/index.php');
foreach(['workspace','account-settings'] as $module){
    mkdir($root.'/nu-mobile/'.$module,0700,true);
    copy(dirname(__DIR__).'/public_html/nu-mobile/'.$module.'/service.php',$root.'/nu-mobile/'.$module.'/service.php');
}
file_put_contents($root.'/includes/central-auth.php', <<<'PHP'
<?php
const NU_AUTH_COOKIE='nu_fixture_session';
function nu_auth_pdo(): PDO {
    return new PDO('mysql:host=127.0.0.1;port=3306;dbname=nu_mobile_router_test;charset=utf8mb4','root','test-only-password',[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
}
function nu_auth_login(string $identifier,string $password,bool $remember): void {
    if($identifier!=='fixture@example.test'||$password!=='fixture-password')throw new RuntimeException('Invalid fixture login');
    setcookie(NU_AUTH_COOKIE,str_repeat('a',64),['httponly'=>true,'samesite'=>'Strict']);
}
function nu_current_account(bool $touch=true): ?array {
    return ($_COOKIE[NU_AUTH_COOKIE]??'')===str_repeat('a',64)?['id'=>1,'email'=>'fixture@example.test','display_name'=>'Fixture Student']:null;
}
PHP);
// Emulate the deployed validation failure without installing wallet tables.
file_put_contents($root.'/includes/central-wallet-bootstrap.php', <<<'PHP'
<?php
function nu_cwallet_pdo(): PDO {throw new RuntimeException('Fixture: wallet tables unavailable');}
PHP);
$socket=stream_socket_server('tcp://127.0.0.1:0',$errno,$errstr);
if(!$socket)throw new RuntimeException($errstr);
$address=stream_socket_get_name($socket,false);
fclose($socket);
$log=$root.'/server.log';
$process=proc_open([PHP_BINARY,'-S',$address,'-t',$root],[0=>['pipe','r'],1=>['file',$log,'a'],2=>['file',$log,'a']],$pipes);
if(!is_resource($process))throw new RuntimeException('HTTP test server did not start');
fclose($pipes[0]);
$checks=0;
function check(bool $ok,string $message): void {global $checks;if(!$ok)throw new RuntimeException($message);$checks++;echo "PASS: $message\n";}
function request(string $route,string $method='GET',?array $body=null,bool $bearer=true,bool $cookie=false): array {
    global $address;
    $headers=['Content-Type: application/json','Connection: close'];
    if($bearer)$headers[]='Authorization: Bearer '.str_repeat('a',64);
    if($cookie)$headers[]='Cookie: nu_fixture_session='.str_repeat('a',64);
    $context=stream_context_create(['http'=>['method'=>$method,'header'=>implode("\r\n",$headers),'content'=>$body===null?'':json_encode($body),'ignore_errors'=>true,'timeout'=>5]]);
    $response=file_get_contents('http://'.$address.'/api/central/index.php?route='.rawurlencode($route),false,$context);
    preg_match('/\s(\d{3})\s/',$http_response_header[0]??'',$match);
    return [(int)($match[1]??0),json_decode((string)$response,true,512,JSON_THROW_ON_ERROR),$http_response_header];
}
try{
    $ready=false;
    for($i=0;$i<50;$i++){
        $connection=@stream_socket_client('tcp://'.$address,$errno,$errstr,0.1);
        if($connection){fclose($connection);$ready=true;break;}
        usleep(100000);
    }
    check($ready,'HTTP server starts');
    [$status]=request('/workspace','GET',null,false,true);
    check($status===401,'Ambient website cookie cannot authenticate the mobile API');
    [$status,$response,$headers]=request('/auth/login','POST',['email'=>'fixture@example.test','password'=>'fixture-password'],false);
    check($status===200&&$response['data']['access_token']===str_repeat('a',64),'Login remains available without wallet tables');
    check(count(array_filter($headers,fn($h)=>stripos($h,'Set-Cookie:')===0))===0,'Mobile login returns a bearer token without setting browser cookies');
    [$status]=request('/auth/login','POST',['email'=>'fixture@example.test','password'=>'wrong'],false);
    check($status===401,'Invalid login is rejected');
    [$status,$response]=request('/workspace');
    check($status===200&&$response['data']['account_id']==='1','Bearer-authenticated workspace remains available without wallet tables');
    [$status,$response]=request('/app/bootstrap');
    check($status===200&&$response['data']['profile']['id']===1,'Bootstrap returns the authenticated central account');
    check($response['data']['wallet']===null&&!empty($response['data']['wallet_warning']),'Unavailable wallet is null with a warning, never a zero balance');
    check($response['data']['workspace']['account_id']==='1'&&isset($response['data']['settings']['settings']),'Bootstrap preserves workspace and appearance settings during wallet failure');
    check($response['data']['feature_flags']['wallet_funding']===false&&$response['data']['feature_flags']['wallet_available']===false,'Unavailable wallet does not advertise funding or an available balance');
    [$status,$response]=request('/wallet');
    check($status===503&&$response['error']['code']==='UNAVAILABLE','Wallet access fails closed when its validated database is unavailable');
    [$status,$response]=request('/unknown');
    check($status===503&&$response['error']['code']==='NOT_AVAILABLE','Unsupported routes do not enter the wallet gate');
    echo "$checks central router checks passed.\n";
}finally{
    proc_terminate($process);proc_close($process);
    $files=new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root,FilesystemIterator::SKIP_DOTS),RecursiveIteratorIterator::CHILD_FIRST);
    foreach($files as $file){$file->isDir()?rmdir($file->getPathname()):unlink($file->getPathname());}
    rmdir($root);
}
