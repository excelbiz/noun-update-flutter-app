<?php
declare(strict_types=1);
require_once __DIR__.'/../public_html/nu-mobile/study-state/service.php';
$pdo=new PDO('mysql:host=127.0.0.1;port='.(getenv('TEST_DB_PORT')?:'3306').';dbname=nu_mobile_test;charset=utf8mb4','root',getenv('TEST_DB_PASSWORD')?:'test-only-password',[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC]);
if($pdo->query('SELECT DATABASE()')->fetchColumn()!=='nu_mobile_test')throw new RuntimeException('Test DB required');
function studyOk(bool $value,string $name):void{if(!$value)throw new RuntimeException('FAILED '.$name);echo "PASS $name\n";}
function studyRejected(callable $fn,string $name):void{try{$fn();}catch(InvalidArgumentException $e){echo "PASS $name\n";return;}throw new RuntimeException('FAILED '.$name);}
$sql=file_get_contents(__DIR__.'/../sql/companion.sql');$pdo->exec($sql);$pdo->exec($sql);
$pdo->exec('DELETE FROM nu_mobile_study_state');
$state=new NuStudyState($pdo);
$empty=$state->get(700,'CIT411');
studyOk($empty['done']===[]&&$empty['notes']===''&&$empty['revision']===0,'new course starts empty');
$first=$state->save(700,'cit 411',['done'=>[3,1,3,0],'notes'=>'My first revision note']);
studyOk($first['done']===[0,1,3],'completed indexes are sorted and deduplicated');
studyOk($first['notes']==='My first revision note'&&$first['revision']===1,'first save stores notes and revision');
$again=$state->get(700,'CIT411');
studyOk($again['done']===[0,1,3]&&$again['revision']===1,'saved state restores for same account and course');
studyOk($state->get(701,'CIT411')['revision']===0,'study state is account isolated');
studyOk($state->get(700,'GST302')['revision']===0,'study state is course isolated');
$second=$state->save(700,'CIT411',['done'=>[0,1,2,3],'notes'=>'Updated notes']);
studyOk($second['revision']===2&&$second['notes']==='Updated notes','subsequent save increments revision');
studyRejected(fn()=>$state->get(700,'INVALID'),'reject invalid course');
studyRejected(fn()=>$state->save(700,'CIT411',['done'=>'bad','notes'=>'x']),'reject invalid completed list');
studyRejected(fn()=>$state->save(700,'CIT411',['done'=>[-1],'notes'=>'x']),'reject negative unit index');
studyRejected(fn()=>$state->save(700,'CIT411',['done'=>[500],'notes'=>'x']),'reject excessive unit index');
studyOk((int)$pdo->query("SELECT COUNT(*) FROM nu_mobile_study_state WHERE account_id=700 AND course_code='CIT411'")->fetchColumn()===1,'updates keep one row per account course');
