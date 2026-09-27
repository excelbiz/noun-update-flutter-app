<?php
declare(strict_types=1);
require_once __DIR__.'/../public_html/nu-mobile/companion/service.php';
$pdo=new PDO('mysql:host=127.0.0.1;port='.(getenv('TEST_DB_PORT')?:'3306').';dbname=nu_mobile_test;charset=utf8mb4','root',getenv('TEST_DB_PASSWORD')?:'test-only-password',[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
if($pdo->query('SELECT DATABASE()')->fetchColumn()!=='nu_mobile_test')throw new RuntimeException('Test DB required');
function ok(bool $v,string $name):void{if(!$v)throw new RuntimeException('FAILED '.$name);echo "PASS $name\n";}
function rejected(callable $f):void{try{$f();}catch(InvalidArgumentException $e){return;}throw new RuntimeException('Expected validation rejection');}
$sql=file_get_contents(__DIR__.'/../sql/companion.sql');$pdo->exec($sql);$pdo->exec($sql);
$s=new NuCompanion($pdo);$config=$s->configuration();
ok(count($config['plans'])===3,'exactly three initial plans');ok($config['plans'][1]['price_minor']===350000,'server price in minor units');ok(!$config['new_subscriptions_enabled'],'checkout remains disabled');
ok(!$s->entitlement(800)['active'],'no local/client grant');
rejected(fn()=>$s->savePreferences(800,['preferred_skin'=>'futureTech','active'=>true]));
$s->savePreferences(800,['birthday'=>['month'=>2,'day'=>29,'celebration_enabled'=>true]]);
ok($s->preferences(800)['birthday']['day']===29,'February 29 accepted without a birth year');
rejected(fn()=>$s->savePreferences(800,['birthday'=>['month'=>2,'day'=>30,'celebration_enabled'=>true]]));
ok($s->preferences(801)['birthday']['day']===null,'account isolation');
$pdo->exec("INSERT INTO nu_mobile_premium_subscriptions(account_id,plan_id,status,started_at,expires_at,regular_price_minor,amount_paid_minor) VALUES(800,'semester','active',DATE_SUB(UTC_TIMESTAMP(),INTERVAL 1 DAY),DATE_ADD(UTC_TIMESTAMP(),INTERVAL 1 DAY),350000,250000)");
ok($s->entitlement(800)['active'],'server subscription active');$s->savePreferences(800,['preferred_skin'=>'futureTech']);
$pdo->exec("UPDATE nu_mobile_premium_subscriptions SET expires_at=DATE_SUB(UTC_TIMESTAMP(),INTERVAL 1 SECOND) WHERE account_id=800");
ok(!$s->entitlement(800)['active'],'expired subscription rejected');ok($s->preferences(800)['preferred_skin']==='futureTech','expired preferred skin retained');
rejected(fn()=>$s->savePreferences(800,['preferred_skin'=>'premiumDark']));
$pdo->exec("UPDATE nu_mobile_premium_plans SET promo_enabled=1,promo_price_minor=250000,promo_starts_at=DATE_SUB(UTC_TIMESTAMP(),INTERVAL 1 DAY),promo_ends_at=DATE_ADD(UTC_TIMESTAMP(),INTERVAL 1 DAY) WHERE id='semester'");
ok($s->configuration()['plans'][1]['price_minor']===250000,'promotion uses server time');
$pdo->exec("UPDATE nu_mobile_premium_plans SET promo_ends_at=DATE_SUB(UTC_TIMESTAMP(),INTERVAL 1 SECOND) WHERE id='semester'");ok($s->configuration()['plans'][1]['price_minor']===350000,'expired promotion regular price');
ok($s->dailyQuote()===null,'empty collection has no fabricated quote');
$pdo->exec("INSERT INTO nu_mobile_motivation(quote,author) VALUES('Fixture motivation','Test'),('Second fixture','Test')");
$q=$s->dailyQuote();ok($q===$s->dailyQuote(),'daily quote stable');$s->saveQuote(800,(int)$q['id'],true);$s->saveQuote(800,(int)$q['id'],true);
ok(count($s->savedQuotes(800))===1,'save idempotent');ok(count($s->savedQuotes(801))===0,'saved quote account isolation');
$s->saveQuote(800,(int)$q['id'],false);ok(count($s->savedQuotes(800))===0,'remove saved quote');
$s->savePreferences(800,['birthday'=>['month'=>null,'day'=>null,'celebration_enabled'=>false]]);ok($s->preferences(800)['birthday']['month']===null,'birthday removal');
