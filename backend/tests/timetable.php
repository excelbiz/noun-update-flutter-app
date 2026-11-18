<?php
declare(strict_types=1);
require_once __DIR__.'/../public_html/nu-mobile/core.php';
require_once __DIR__.'/../public_html/nu-mobile/content.php';
$pdo=new PDO('mysql:host=127.0.0.1;port='.(getenv('TEST_DB_PORT')?:'3306').';dbname=nu_mobile_test;charset=utf8mb4','root',getenv('TEST_DB_PASSWORD')?:'test-only-password',[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC]);
if($pdo->query('SELECT DATABASE()')->fetchColumn()!=='nu_mobile_test')throw new RuntimeException('Test DB required');
function timetableOk(bool $value,string $name):void{if(!$value)throw new RuntimeException('FAILED '.$name);echo "PASS $name\n";}
$pdo->exec('DROP TABLE IF EXISTS personalized_timetable');
$pdo->exec("CREATE TABLE personalized_timetable(id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,day VARCHAR(40) NOT NULL,course_code VARCHAR(20) NOT NULL,course_title VARCHAR(255) NOT NULL,date VARCHAR(120) NOT NULL,time VARCHAR(80) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
$year=(int)date('Y');$month=(int)date('n');$futureMonth=$month<=6?6:12;
$future=sprintf('%04d-%02d-28',$year,$futureMonth);
$past=sprintf('%04d-%02d-01',$year,$month<=6?1:7);
$stmt=$pdo->prepare('INSERT INTO personalized_timetable(day,course_code,course_title,date,time) VALUES(?,?,?,?,?)');
$stmt->execute(['Day 2','CIT411','Internet Programming',$future,'9:00 am']);
$stmt->execute(['Day 1','GST302','Business Creation and Growth',$past,'8:00 am']);
$stmt->execute(['Day 3','CHM192','Chemistry Practical',$future,'1:00 pm']);
$data=nu_timetable($pdo,' cit411, GST302 CHM192, CIT411 ');
timetableOk(count($data['items'])===3,'deduplicates submitted courses');
timetableOk($data['items'][0]['course_code']==='GST302','sorts by parsed exam datetime');
timetableOk($data['items'][0]['exam_type']==='CBT','keeps GST302 CBT exception');
timetableOk(array_values(array_filter($data['items'],fn($r)=>$r['course_code']==='CHM192'))[0]['exam_type']==='Practical','keeps practical course exception');
timetableOk(array_values(array_filter($data['items'],fn($r)=>$r['course_code']==='CIT411'))[0]['exam_type']==='POP','uses level rule for CIT411');
timetableOk($data['current_period']===nu_academic_period(),'returns automatic current period');
timetableOk($data['source_period']===nu_academic_period(new DateTimeImmutable($future,new DateTimeZone('Africa/Lagos'))),'infers source period from timetable dates');
$missing=nu_timetable($pdo,'CIT411,CIT999');
timetableOk($missing['missing_courses']===['CIT999'],'returns missing registered course codes');
try{nu_timetable($pdo,'BAD!');throw new RuntimeException('Expected invalid course rejection');}catch(NuFailure $e){timetableOk($e->reason==='INVALID_COURSE','rejects invalid course codes');}
try{nu_timetable($pdo,'');throw new RuntimeException('Expected empty course rejection');}catch(NuFailure $e){timetableOk($e->reason==='COURSES_REQUIRED','requires registered courses');}
