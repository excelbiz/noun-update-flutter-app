<?php
declare(strict_types=1);
require_once __DIR__.'/../public_html/nu-mobile/account-settings/service.php';
$pdo=new PDO('mysql:host=127.0.0.1;port='.(getenv('TEST_DB_PORT')?:'3306').';dbname=nu_mobile_test;charset=utf8mb4','root',getenv('TEST_DB_PASSWORD')?:'test-only-password',[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC]);
if($pdo->query('SELECT DATABASE()')->fetchColumn()!=='nu_mobile_test')throw new RuntimeException('Test DB required');
function settingsOk(bool $value,string $name):void{if(!$value)throw new RuntimeException('FAILED '.$name);echo "PASS $name\n";}
function settingsRejected(callable $fn,string $name):void{try{$fn();}catch(InvalidArgumentException $e){echo "PASS $name\n";return;}throw new RuntimeException('FAILED '.$name);}
$sql=file_get_contents(__DIR__.'/../sql/companion.sql');$pdo->exec($sql);$pdo->exec($sql);
$pdo->exec('DELETE FROM nu_mobile_account_settings');
$service=new NuAccountSettings($pdo);
$defaults=$service->get(501);
settingsOk($defaults['exists']===false,'new account has no stored settings yet');
settingsOk($defaults['settings']['automatic']===true&&$defaults['settings']['mode']==='system'&&$defaults['settings']['data_saver']===false,'new account gets safe appearance defaults');
settingsOk($defaults['settings']['notifications_enabled']===true&&$defaults['settings']['notify_tmas']===true&&$defaults['settings']['notify_exams']===true&&$defaults['settings']['notify_results']===true&&$defaults['settings']['notify_fees']===true&&$defaults['settings']['notify_general']===true,'new account receives all notification categories by default');
$first=$service->save(501,['settings'=>['automatic'=>false,'mode'=>'dark','text_size'=>'Large','font'=>'Classic serif','accent'=>'Ocean','data_saver'=>true]]);
settingsOk($first['exists']===true,'first save creates account settings');
settingsOk($first['settings']['mode']==='dark'&&$first['settings']['text_size']==='Large'&&$first['settings']['data_saver']===true,'valid appearance settings persist');
settingsOk($first['settings']['notify_exams']===true,'appearance-only save preserves notification defaults');
settingsOk($service->get(502)['exists']===false,'settings are account isolated');
$partial=$service->save(501,['accent'=>'Plum']);
settingsOk($partial['settings']['accent']==='Plum','partial update changes requested setting');
settingsOk($partial['settings']['mode']==='dark'&&$partial['settings']['font']==='Classic serif'&&$partial['settings']['data_saver']===true,'partial update preserves other settings');
$notifications=$service->save(501,['settings'=>['notify_tmas'=>false,'notify_fees'=>false,'notify_general'=>false]]);
settingsOk($notifications['settings']['notify_tmas']===false&&$notifications['settings']['notify_fees']===false&&$notifications['settings']['notify_general']===false,'notification category choices persist');
settingsOk($notifications['settings']['notify_exams']===true&&$notifications['settings']['notify_results']===true,'unchanged notification categories are preserved');
settingsOk($notifications['settings']['mode']==='dark'&&$notifications['settings']['accent']==='Plum','notification update preserves appearance settings');
settingsRejected(fn()=>$service->save(501,['mode'=>'sepia']),'reject invalid mode');
settingsRejected(fn()=>$service->save(501,['text_size'=>'Huge']),'reject invalid text size');
settingsRejected(fn()=>$service->save(501,['font'=>'Comic Sans']),'reject invalid font');
settingsRejected(fn()=>$service->save(501,['accent'=>'Invisible']),'reject invalid accent');
settingsRejected(fn()=>$service->save(501,['automatic'=>1]),'reject non-boolean automatic flag');
settingsRejected(fn()=>$service->save(501,['data_saver'=>'yes']),'reject non-boolean data saver');
settingsRejected(fn()=>$service->save(501,['notify_tmas'=>1]),'reject non-boolean notification category');
settingsRejected(fn()=>$service->save(501,['notifications_enabled'=>'yes']),'reject non-boolean notification master switch');
settingsOk((int)$pdo->query('SELECT COUNT(*) FROM nu_mobile_account_settings WHERE account_id=501')->fetchColumn()===1,'updates retain one row per account');
