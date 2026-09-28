<?php
declare(strict_types=1);
require_once __DIR__.'/../public_html/nu-mobile/saved-resources/service.php';
$pdo=new PDO('mysql:host=127.0.0.1;port='.(getenv('TEST_DB_PORT')?:'3306').';dbname=nu_mobile_test;charset=utf8mb4','root',getenv('TEST_DB_PASSWORD')?:'test-only-password',[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
$pdo->exec(file_get_contents(__DIR__.'/../sql/companion.sql'));
function ok_saved(bool $value,string $name):void{if(!$value)throw new RuntimeException('FAILED '.$name);echo "PASS $name\n";}
function reject_saved(callable $fn):void{try{$fn();}catch(InvalidArgumentException $e){return;}throw new RuntimeException('Expected validation rejection');}
$s=new NuSavedResources($pdo);
$pdo->exec('DELETE FROM nu_mobile_saved_resources WHERE account_id IN (501,502)');
$r=$s->save(501,['resource_key'=>'course:CIT411:material','saved'=>true,'resource_type'=>'course_material','title'=>'CIT411 Course Material','course_code'=>'CIT411','route'=>'/courses/CIT411']);
ok_saved($r['saved']===true,'save resource');
ok_saved(count($s->all(501)['items'])===1,'saved resource listed');
ok_saved(count($s->all(502)['items'])===0,'account isolation');
$s->save(501,['resource_key'=>'course:CIT411:material','saved'=>true,'resource_type'=>'course_material','title'=>'CIT411 Updated','course_code'=>'CIT411','route'=>'/courses/CIT411']);
ok_saved(count($s->all(501)['items'])===1&&$s->all(501)['items'][0]['title']==='CIT411 Updated','save is idempotent upsert');
$s->save(501,['resource_key'=>'course:CIT411:material','saved'=>false]);
ok_saved(count($s->all(501)['items'])===0,'remove saved resource');
reject_saved(fn()=>$s->save(501,['resource_key'=>'bad key','saved'=>true,'resource_type'=>'resource','title'=>'Bad']));
reject_saved(fn()=>$s->save(501,['resource_key'=>'ok','saved'=>true,'resource_type'=>'resource','title'=>'','route'=>'https://evil.example']));
