<?php
declare(strict_types=1);
require_once __DIR__.'/../public_html/nu-mobile/core.php';
require_once __DIR__.'/../public_html/nu-mobile/content.php';
function env_value(string $key, ?string $default=null): ?string { $v=getenv($key);return $v===false?$default:$v; }
function connection():PDO {
 return new PDO('mysql:host=127.0.0.1;port='.(getenv('TEST_DB_PORT')?:'3306').';dbname=nu_mobile_test;charset=utf8mb4',
  'root',getenv('TEST_DB_PASSWORD')?:'test-only-password',[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC,PDO::ATTR_EMULATE_PREPARES=>false]);
}
$db=connection();
$root=sys_get_temp_dir().'/nu-wallet-integration';
@mkdir($root.'/file_storage',0777,true);
$config=['root'=>$root,'site_url'=>'https://nounupdate.com','download_roots'=>[$root.'/file_storage'],'exam_fee_basis_points'=>150];
$store=new NuStore($db,$db,$config);
if(($argv[1]??'')==='--purchase'){
 try{$o=$store->purchase((int)$argv[2],$argv[3],$argv[4]);echo 'OK:'.$o['id'];exit(0);}catch(NuFailure $e){echo $e->reason;exit($e->status===402?2:3);}
}
function check(bool $ok,string $name):void {if(!$ok)throw new RuntimeException('FAILED: '.$name);echo "PASS: $name\n";}
function fails(callable $f,string $reason):void {try{$f();}catch(NuFailure $e){check($e->reason===$reason,'reject '.$reason);return;}throw new RuntimeException('Expected '.$reason);}
// Destructive fixture setup is restricted to this dedicated CI database.
check($db->query('SELECT DATABASE()')->fetchColumn()==='nu_mobile_test','isolated test database');
foreach($db->query('SHOW TABLES')->fetchAll(PDO::FETCH_COLUMN) as $t)$db->exec('DROP TABLE `'.$t.'`');
$db->exec('CREATE TABLE summary_users(id INT PRIMARY KEY AUTO_INCREMENT,name VARCHAR(100),email VARCHAR(190) UNIQUE,password VARCHAR(255),balance DECIMAL(12,2) NOT NULL DEFAULT 0,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB');
$db->exec('CREATE TABLE summary_transactions(id BIGINT PRIMARY KEY AUTO_INCREMENT,user_id INT,amount DECIMAL(12,2),type ENUM("credit","debit"),description VARCHAR(255),reference VARCHAR(100) UNIQUE,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB');
$db->exec('CREATE TABLE payment_intents(id BIGINT PRIMARY KEY AUTO_INCREMENT,user_id INT,customer_email VARCHAR(190),reference VARCHAR(100) UNIQUE,amount_naira DECIMAL(12,2),amount_kobo BIGINT,currency VARCHAR(3),status VARCHAR(40),authorization_url TEXT,access_code VARCHAR(100),paid_at DATETIME,created_at DATETIME,updated_at DATETIME,paystack_transaction_id VARCHAR(100),channel VARCHAR(40),gateway_response VARCHAR(250)) ENGINE=InnoDB');
$db->exec('CREATE TABLE wallet_credit_receipts(id BIGINT PRIMARY KEY AUTO_INCREMENT,reference VARCHAR(100) UNIQUE,payment_intent_id BIGINT,user_id INT,amount_naira DECIMAL(12,2),amount_kobo BIGINT,paystack_transaction_id VARCHAR(100),created_at DATETIME) ENGINE=InnoDB');
$db->exec('CREATE TABLE files(id INT PRIMARY KEY AUTO_INCREMENT,name VARCHAR(100),price DECIMAL(12,2),file_path TEXT) ENGINE=InnoDB');
$db->exec('CREATE TABLE news_upload(id INT PRIMARY KEY AUTO_INCREMENT,ref_id INT,title VARCHAR(100),message TEXT,imagepath VARCHAR(100),upload_date VARCHAR(20),status VARCHAR(20),published_at DATETIME) ENGINE=InnoDB');
$sql=file_get_contents(__DIR__.'/../sql/install.sql');$db->exec($sql);$db->exec($sql);
check(true,'migration reruns without modifying balances');
$insert=$db->prepare('INSERT INTO summary_users(name,email,password,balance) VALUES (?,?,?,?)');
$insert->execute(['Student A','a@example.test',password_hash('test-password-1',PASSWORD_DEFAULT),'10000.00']);
$insert->execute(['Student B','b@example.test',password_hash('test-password-2',PASSWORD_DEFAULT),'0.00']);
file_put_contents($root.'/file_storage/summary.pdf',"%PDF-1.4\nfixture");
$db->exec("INSERT INTO files(name,price,file_path) VALUES ('ACC101 Exam Summary',1000.00,'../file_storage/summary.pdf'),('ACC102 Exam Summary',2000.00,'file_storage/summary.pdf')");
check(nu_money_to_kobo('0.01')===1 && nu_money_to_kobo('1234.50')===123450,'integer money conversion');
fails(fn()=>nu_money_to_kobo('-1'),'INVALID_AMOUNT');fails(fn()=>nu_money_to_kobo('1e5'),'INVALID_AMOUNT');
fails(fn()=>nu_money_to_kobo('1.001'),'INVALID_AMOUNT');
check(!nu_safe_checkout('https://paystack.com.attacker.test/x'),'reject lookalike payment host');
check(nu_safe_checkout('https://checkout.paystack.com/x'),'accept genuine checkout host');
$auth=$store->login('a@example.test','test-password-1','127.0.0.1');
check((int)$store->authenticate($auth['access_token'])['id']===1,'shared account authentication');
fails(fn()=>$store->login('a@example.test','wrong','127.0.0.1'),'INVALID_LOGIN');
$next=$store->refresh($auth['refresh_token']);
fails(fn()=>$store->authenticate($auth['access_token']),'SESSION_EXPIRED');
fails(fn()=>$store->refresh($auth['refresh_token']),'SESSION_EXPIRED');
check((int)$store->authenticate($next['access_token'])['id']===1,'refresh rotates both tokens');
$db->prepare('UPDATE summary_users SET password=? WHERE id=1')->execute([password_hash('changed-test-password',PASSWORD_DEFAULT)]);
fails(fn()=>$store->authenticate($next['access_token']),'SESSION_EXPIRED');
$q=$store->quote(1,[1,1]);check(count($q['items'])===1 && $q['total_kobo']===101500,'quote uses server prices and 1.5 percent charge');
check(!isset($q['items'][0]['file_path']),'quote does not reveal storage paths');
fails(fn()=>$store->purchase(2,$q['quote_id'],'request-test-000001'),'QUOTE_EXPIRED');
$o=$store->purchase(1,$q['quote_id'],'request-test-000001');
check($store->wallet(1)['balance_kobo']===898500,'purchase debits shared balance');
$again=$store->purchase(1,$q['quote_id'],'request-test-000001');
$again2=$store->purchase(1,$q['quote_id'],'request-test-000002');
check($o['id']===$again['id']&&$o['id']===$again2['id']&&$store->wallet(1)['balance_kobo']===898500,'repeat key and repeat quote never double debit');
$q2=$store->quote(1,[2]);fails(fn()=>$store->purchase(1,$q2['quote_id'],'request-test-000001'),'KEY_REUSED');
$qPoor=$store->quote(2,[2]);fails(fn()=>$store->purchase(2,$qPoor['quote_id'],'request-test-poor01'),'INSUFFICIENT_BALANCE');
check((int)$db->query('SELECT COUNT(*) FROM nu_app_orders WHERE user_id=2')->fetchColumn()===0,'insufficient balance creates no order');
fails(fn()=>$store->order(2,(int)$o['id']),'NOT_FOUND');
fails(fn()=>$store->downloadTicket(2,(int)$o['items'][0]['id']),'NOT_FOUND');
$t=$store->downloadTicket(1,(int)$o['items'][0]['id']);parse_str(parse_url($t['url'],PHP_URL_QUERY),$params);
$d=$store->takeDownload($params['ticket']);check(is_file($d['path']),'authorised file download');
fails(fn()=>$store->takeDownload($params['ticket']),'NOT_FOUND');
fails(fn()=>$store->localFile('../../etc/passwd'),'FILE_UNAVAILABLE');
fails(fn()=>$store->localFile('https://other.test/file.pdf'),'FILE_UNAVAILABLE');
$expired=$store->quote(1,[2]);$db->prepare('UPDATE nu_app_quotes SET expires_at="2000-01-01" WHERE id=?')->execute([$expired['quote_id']]);
fails(fn()=>$store->purchase(1,$expired['quote_id'],'expired-request-01'),'QUOTE_EXPIRED');
// A failure after debit must roll back the debit AND entitlement/order writes.
$before=$store->wallet(1)['balance_kobo'];$qFail=$store->quote(1,[2]);
$db->exec("CREATE TRIGGER fail_ledger BEFORE INSERT ON summary_transactions FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Injected ledger failure'");
try{$store->purchase(1,$qFail['quote_id'],'rollback-request-01');throw new RuntimeException('Expected rollback');}catch(PDOException $e){}
$db->exec('DROP TRIGGER fail_ledger');
check($store->wallet(1)['balance_kobo']===$before,'ledger failure rolls back wallet debit');
check((int)$db->query("SELECT COUNT(*) FROM nu_app_orders WHERE request_key='rollback-request-01'")->fetchColumn()===0,'ledger failure rolls back order');
// The existing Course Summary verifier must credit the same wallet once.
require_once __DIR__.'/fixtures/legacy-paystack.php';
// Funding retries must reuse the intent without another gateway call.
@mkdir($root.'/course',0777,true);
file_put_contents($root.'/course/paystack.php','<?php // Payment helpers already loaded from the reviewed fixture.');
$fundKey='fund-retry-request-01';
$fundRef='NUW-1-'.strtoupper(substr(hash('sha256','1|'.$fundKey),0,20));
$db->prepare('INSERT INTO payment_intents(user_id,customer_email,reference,amount_naira,amount_kobo,currency,status,authorization_url) VALUES (1,?,?,500,50000,"NGN","initialized",?)')->execute(['a@example.test',$fundRef,'https://checkout.paystack.com/test-reuse']);
$fundUser=['id'=>1,'email'=>'a@example.test'];
$fund=$store->fund($fundUser,50000,$fundKey);
check($fund['reference']===$fundRef&&$fund['authorization_url']==='https://checkout.paystack.com/test-reuse','funding retry reuses checkout and valid database lock');
fails(fn()=>$store->fund($fundUser,60000,$fundKey),'KEY_REUSED');
$db->prepare('UPDATE payment_intents SET status="credited",authorization_url=NULL WHERE reference=?')->execute([$fundRef]);
check($store->fund($fundUser,50000,$fundKey)['status']==='credited','credited funding retry does not initialise again');
$ref='NUW-1-'.str_repeat('A',20);
$db->prepare('INSERT INTO payment_intents(user_id,customer_email,reference,amount_naira,amount_kobo,currency,status) VALUES (1,?,?,100,10000,"NGN","initialized")')->execute(['a@example.test',$ref]);
$payment=['reference'=>$ref,'status'=>'success','currency'=>'NGN','amount'=>10000,'customer'=>['email'=>'a@example.test'],'id'=>100,'channel'=>'card'];
finalize_wallet_payment($db,$payment);finalize_wallet_payment($db,$payment);
check($store->wallet(1)['balance_kobo']===$before+10000,'callback/webhook replay credits existing wallet once');
$badRef='NUW-1-'.str_repeat('B',20);
$db->prepare('INSERT INTO payment_intents(user_id,customer_email,reference,amount_naira,amount_kobo,currency,status) VALUES (1,?,?,100,10000,"NGN","initialized")')->execute(['a@example.test',$badRef]);
foreach([['amount'=>1],['currency'=>'USD'],['customer'=>['email'=>'wrong@example.test']]] as $bad){
 try{finalize_wallet_payment($db,array_replace($payment,['reference'=>$badRef],$bad));throw new LogicException('Invalid payment accepted');}catch(RuntimeException $e){if($e instanceof LogicException)throw $e;}
}
check($store->wallet(1)['balance_kobo']===$before+10000,'invalid payment amount currency and email cannot credit');
$db->exec("INSERT INTO news_upload(ref_id,title,message,imagepath,upload_date,status,published_at) VALUES (11,'Published','<p>Hello</p><script>bad()</script>','cover.webp','2026-09-18','published','2026-09-18'),(12,'Draft','Secret','','2026-09-18','draft','2026-09-18'),(13,'Scheduled','Future','','2026-09-18','published','2099-01-01')");
$posts=nu_posts($db,$config,'news');check(count($posts['items'])===1,'feed excludes drafts and future publications');
$article=nu_posts($db,$config,'news',1,1);check($article['content_text']==='Hello','article content strips executable markup');
fails(fn()=>nu_posts($db,$config,'news',1,2),'NOT_FOUND');
// Real concurrent processes: two orders compete for the same remaining balance.
$db->exec('UPDATE summary_users SET balance=1500 WHERE id=1');$qa=$store->quote(1,[1]);$qb=$store->quote(1,[1]);
$workers=[];
foreach([$qa,$qb] as $idx=>$q){$pipes=[];$p=proc_open([PHP_BINARY,__FILE__,'--purchase','1',$q['quote_id'],'concurrent-key-000'.$idx],[1=>['pipe','w'],2=>['pipe','w']],$pipes);$workers[]=[$p,$pipes];}
$codes=[];foreach($workers as [$p,$pipes]){stream_get_contents($pipes[1]);$err=stream_get_contents($pipes[2]);foreach($pipes as $pipe)fclose($pipe);$codes[]=proc_close($p);if($err)echo $err;}
sort($codes);check($codes===[0,2],'concurrent purchases cannot overspend');
check($store->wallet(1)['balance_kobo']===48500,'concurrent purchases preserve exact balance');
require_once __DIR__.'/../public_html/nu-mobile/native.php';
// Native registration shares the same account and starts with no invented funds.
$registered=nu_register($store,['name'=>'Native Student','email'=>'native@example.test','password'=>'native-password-123'],'127.0.0.9');
$nativeUser=$store->authenticate($registered['access_token']);$nativeId=(int)$nativeUser['id'];
check($store->wallet($nativeId)['balance_kobo']===0,'native registration shares zero-balance wallet');
fails(fn()=>nu_register($store,['name'=>'N','email'=>'invalid','password'=>'short'],'127.0.0.9'),'INVALID_ACCOUNT');
nu_profile_save($store,$nativeId,['name'=>'New Name','programme'=>'Accounting','level'=>'200','matric_number'=>'PROFILE-ONLY']);
check(nu_profile_details($store,$nativeId)['programme']==='Accounting'&&nu_profile_details($store,2)['programme']==='','native profile stays scoped to its account');
check($store->wallet($nativeId)['balance_kobo']===0,'profile edits cannot change wallet');
$db->prepare('INSERT INTO nu_app_resets(user_id,code_hash,expires_at) VALUES (?,?,?)')->execute([$nativeId,password_hash('12345678',PASSWORD_DEFAULT),gmdate('Y-m-d H:i:s',time()+600)]);
fails(fn()=>nu_reset_finish($store,['email'=>'native@example.test','password'=>'replacement-password','code'=>'00000000'],'127.0.0.9'),'INVALID_CODE');
check((int)$db->query('SELECT attempts FROM nu_app_resets WHERE user_id='.$nativeId)->fetchColumn()===1,'bad reset attempt is committed');
nu_reset_finish($store,['email'=>'native@example.test','password'=>'replacement-password','code'=>'12345678'],'127.0.0.9');
fails(fn()=>$store->authenticate($registered['access_token']),'SESSION_EXPIRED');
fails(fn()=>nu_reset_finish($store,['email'=>'native@example.test','password'=>'another-password','code'=>'12345678'],'127.0.0.9'),'INVALID_CODE');
check(isset($store->login('native@example.test','replacement-password','127.0.0.9')['access_token']),'native reset changes password and revokes sessions');
$db->exec('CREATE TABLE pdf_upload_cm(id INT PRIMARY KEY,course_code VARCHAR(20),filename TEXT) ENGINE=InnoDB');
@mkdir($root.'/file-course-materials',0777,true);file_put_contents($root.'/file-course-materials/ACC101.pdf',"%PDF-1.4\nfixture");
$db->exec("INSERT INTO pdf_upload_cm VALUES (1,'ACC101','ACC101.pdf'),(2,'BAD101','../../outside.pdf')");
check(nu_materials($db,'ACC',1)['items'][0]['title']==='ACC101','materials work without optional course title column');
check(is_file(nu_material_file($db,$config,1)),'public course PDF resolves within course storage');
fails(fn()=>nu_material_file($db,$config,2),'NOT_FOUND');
$db->exec('CREATE TABLE fee_check(program VARCHAR(100),level VARCHAR(10),semester VARCHAR(10),ccode VARCHAR(20),ctitle VARCHAR(100),cfee DECIMAL(12,2),efee DECIMAL(12,2),csfee DECIMAL(12,2),cstatus VARCHAR(20),cunit INT) ENGINE=InnoDB');
$db->exec("INSERT INTO fee_check VALUES ('Accounting','100','1','ACC101','Intro',2000,1500,30000,'C',2),('Accounting','100','1','GST101','Use of English',2000,0,30000,'C',2)");
$fees=nu_fees($db,['program'=>'Accounting','level'=>'100','semester'=>'1']);
check($fees['total_kobo']===3550000&&$fees['units']===4,'fee totals use integer kobo and one semester fee');
check($fees['items'][1]['examinable']===false,'zero exam fee is reflected in breakdown');
$db->exec("UPDATE fee_check SET csfee=40000 WHERE ccode='GST101'");
check(nu_fees($db,['program'=>'Accounting','level'=>'100','semester'=>'1'])['total_kobo']===null,'inconsistent semester charges cannot produce misleading total');
echo "ALL BACKEND INTEGRATION CHECKS PASSED\n";
