<?php
declare(strict_types=1);
require_once __DIR__.'/../public_html/nu-mobile/workspace/service.php';
$pdo=new PDO('mysql:host=127.0.0.1;port='.(getenv('TEST_DB_PORT')?:'3306').';dbname=nu_mobile_test;charset=utf8mb4','root',getenv('TEST_DB_PASSWORD')?:'test-only-password',[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
if($pdo->query('SELECT DATABASE()')->fetchColumn()!=='nu_mobile_test')throw new RuntimeException('Test DB required');
function wok(bool $value,string $name):void{if(!$value)throw new RuntimeException('FAILED '.$name);echo "PASS $name\n";}
function invalid(callable $fn,string $name):void{try{$fn();}catch(InvalidArgumentException $e){echo "PASS $name\n";return;}throw new RuntimeException('FAILED '.$name);}
$sql=file_get_contents(__DIR__.'/../sql/companion.sql');$pdo->exec($sql);$pdo->exec($sql);
$pdo->exec('DELETE FROM nu_mobile_student_workspaces WHERE account_id IN (9700,9701)');
$service=new NuStudentWorkspace($pdo);
$empty=$service->get(9700);
wok($empty['exists']===false&&$empty['revision']===0,'new account has empty workspace');
$first=$service->save(9700,[
 'details'=>['Name'=>'Test Student','Programme'=>'B.Sc Chemistry','Level'=>'300 Level','Study centre'=>'Abeokuta'],
 'courses'=>['CHM301','chm303','CHM301'],
 'pins'=>['fees','calendar'],
 'base_revision'=>0,
]);
wok($first['exists']===true&&$first['revision']===1,'first save creates revision one');
wok($first['courses']===['CHM301','CHM303'],'courses are normalised and deduplicated');
wok($first['details']['Programme']==='B.Sc Chemistry','student details round trip');
wok($service->get(9701)['exists']===false,'workspace is isolated by account');
$second=$service->save(9700,[
 'details'=>['Name'=>'Test Student','Programme'=>'B.Sc Chemistry','Level'=>'300 Level'],
 'courses'=>['CHM301','CHM303','CHM305'],
 'pins'=>['fees'],
 'base_revision'=>1,
]);
wok($second['revision']===2&&count($second['courses'])===3,'matching revision updates workspace');
try{
 $service->save(9700,['details'=>[],'courses'=>['CHM401'],'pins'=>[],'base_revision'=>1]);
 throw new RuntimeException('FAILED stale revision rejected');
}catch(RuntimeException $e){
 if($e->getMessage()!=='WORKSPACE_CONFLICT')throw $e;
 echo "PASS stale revision rejected\n";
}
wok($service->get(9700)['courses']===['CHM301','CHM303','CHM305'],'stale write cannot overwrite newer workspace');
invalid(fn()=>$service->save(9701,['details'=>[],'courses'=>['not-a-course'],'pins'=>[],'base_revision'=>0]),'invalid course rejected');
invalid(fn()=>$service->save(9701,['details'=>[],'courses'=>[],'pins'=>['Bad Pin!'],'base_revision'=>0]),'invalid pin rejected');
invalid(fn()=>$service->save(9701,['details'=>['Name'=>str_repeat('x',121)],'courses'=>[],'pins'=>[],'base_revision'=>0]),'oversized detail rejected');
echo "All workspace tests passed.\n";
