<?php
declare(strict_types=1);
// Native controllers only. No HTML pages or browser sessions are executed.
function nu_register(NuStore $s,array $b,string $ip):array {
 $s->rate('register',$ip,5,3600);$email=strtolower(trim((string)($b['email']??'')));$name=trim((string)($b['name']??''));$password=(string)($b['password']??'');
 if(!filter_var($email,FILTER_VALIDATE_EMAIL)||strlen($email)>190||mb_strlen($name)<2||mb_strlen($name)>100||strlen($password)<10||strlen($password)>128)throw new NuFailure(422,'INVALID_ACCOUNT','Enter your name, a valid email and a password of 10–128 characters.');
 try{$s->run('INSERT INTO summary_users(name,email,password,balance) VALUES (?,?,?,0)',[$name,$email,password_hash($password,PASSWORD_DEFAULT)]);}catch(PDOException $e){if($e->getCode()==='23000')throw new NuFailure(409,'ACCOUNT_EXISTS','Unable to create this account. Try signing in or resetting your password.');throw $e;}
 return $s->login($email,$password,$ip);
}
function nu_reset_request(NuStore $s,array $b,string $ip):array {
 $email=strtolower(trim((string)($b['email']??'')));if(!filter_var($email,FILTER_VALIDATE_EMAIL)||strlen($email)>190)throw new NuFailure(422,'INVALID_EMAIL','Enter a valid email.');$s->rate('reset-ip',$ip,10,3600);$s->rate('reset-email',$email,3,3600);
 $u=$s->row('SELECT id FROM summary_users WHERE email=?',[$email]);
 if($u){$code=(string)random_int(10000000,99999999);$s->run('INSERT INTO nu_app_resets(user_id,code_hash,expires_at) VALUES (?,?,?) ON DUPLICATE KEY UPDATE code_hash=VALUES(code_hash),expires_at=VALUES(expires_at),attempts=0',[$u['id'],password_hash($code,PASSWORD_DEFAULT),gmdate('Y-m-d H:i:s',time()+600)]);
  mail($email,'NOUN Update password reset','Your app reset code is '.$code.'. It expires in 10 minutes. Ignore this email if you did not request it.',"From: info@nounupdate.com\r\nContent-Type: text/plain; charset=UTF-8");}
 return ['message'=>'If this email has an account, a reset code has been sent.'];
}
function nu_reset_finish(NuStore $s,array $b,string $ip):array {
 $s->rate('reset-verify-ip',$ip,20,3600);$email=strtolower(trim((string)($b['email']??'')));$password=(string)($b['password']??'');
 if(strlen($password)<10||strlen($password)>128)throw new NuFailure(422,'INVALID_PASSWORD','Use a password of 10–128 characters.');
 $s->db->beginTransaction();try{
 $u=$s->row('SELECT u.id,r.code_hash,r.expires_at,r.attempts FROM summary_users u JOIN nu_app_resets r ON r.user_id=u.id WHERE u.email=? FOR UPDATE',[$email]);
 if(!$u||$u['expires_at']<=gmdate('Y-m-d H:i:s')||(int)$u['attempts']>=5){throw new NuFailure(422,'INVALID_CODE','The reset code is invalid or expired.');}
 if(!password_verify((string)($b['code']??''),$u['code_hash'])){$s->run('UPDATE nu_app_resets SET attempts=attempts+1 WHERE user_id=?',[$u['id']]);$s->db->commit();throw new NuFailure(422,'INVALID_CODE','The reset code is invalid or expired.');}
 $s->run('UPDATE summary_users SET password=? WHERE id=?',[password_hash($password,PASSWORD_DEFAULT),$u['id']]);$s->run('DELETE FROM nu_app_resets WHERE user_id=?',[$u['id']]);$s->run('UPDATE nu_app_sessions SET revoked=1 WHERE user_id=?',[$u['id']]);$s->db->commit();return ['message'=>'Password changed. Sign in with your new password.'];
 }catch(Throwable $e){if($s->db->inTransaction())$s->db->rollBack();throw $e;}
}
function nu_materials(PDO $db,string $q,int $page):array {
 $cols=$db->query('SHOW COLUMNS FROM pdf_upload_cm')->fetchAll(PDO::FETCH_COLUMN);$title=in_array('course_title',$cols,true)?'course_title':'course_code';$page=max(1,min(10000,$page));
 $st=$db->prepare('SELECT id,course_code,'.$title.' AS title FROM pdf_upload_cm WHERE course_code LIKE ? OR '.$title.' LIKE ? ORDER BY course_code LIMIT 41 OFFSET '.(($page-1)*40));$st->execute(['%'.mb_substr($q,0,100).'%','%'.mb_substr($q,0,100).'%']);$rows=$st->fetchAll();return ['items'=>array_slice($rows,0,40),'has_more'=>count($rows)>40];
}
function nu_material_file(PDO $db,array $cfg,int $id):string {
 $q=$db->prepare('SELECT filename FROM pdf_upload_cm WHERE id=?');$q->execute([$id]);$name=$q->fetchColumn();$base=realpath($cfg['root'].'/file-course-materials');$path=$name&&$base?realpath($base.'/'.basename($name)):false;
 if(!$path||!str_starts_with($path,$base.DIRECTORY_SEPARATOR)||!is_file($path)||strtolower(pathinfo($path,PATHINFO_EXTENSION))!=='pdf')throw new NuFailure(404,'NOT_FOUND','This material is unavailable.');return $path;
}
function nu_fee_options(PDO $db):array {
 return ['items'=>$db->query('SELECT DISTINCT program,level,semester FROM fee_check ORDER BY program,level,semester')->fetchAll()];
}
function nu_fees(PDO $db,array $b):array {
 $q=$db->prepare('SELECT ccode,ctitle,cfee,efee,csfee,cstatus,cunit FROM fee_check WHERE program=? AND level=? AND semester=? ORDER BY ccode');$q->execute([(string)($b['program']??''),(string)($b['level']??''),(string)($b['semester']??'')]);$rows=$q->fetchAll();if(!$rows)throw new NuFailure(404,'NOT_FOUND','No fee records match this selection.');
 $items=[];$course=0;$exam=0;$units=0;$semester=[];
 foreach($rows as $r){$c=nu_money_to_kobo($r['cfee']);$e=nu_money_to_kobo($r['efee']);$semester[]=nu_money_to_kobo($r['csfee']);$course+=$c;$exam+=$e;$units+=(int)$r['cunit'];$items[]=['code'=>$r['ccode'],'title'=>$r['ctitle'],'course_kobo'=>$c,'exam_kobo'=>$e,'units'=>(int)$r['cunit'],'status'=>$r['cstatus'],'examinable'=>$e>0];}
 $sf=array_values(array_unique($semester));
 return ['items'=>$items,'course_kobo'=>$course,'exam_kobo'=>$exam,'semester_kobo'=>count($sf)===1?$sf[0]:null,'total_kobo'=>count($sf)===1?$course+$exam+$sf[0]:null,'units'=>$units,'notice'=>'Database-listed fees. Entry-mode and matric-year adjustments require the current fee calculation rules; confirm your final portal assessment.'];
}
function nu_study(NuStore $s,string $code):array {
 require_once __DIR__.'/course-environment.php';require_once $s->config['root'].'/course/lib/summary_engine.php';$code=normalise_course_code($code);$course=get_course_text($s->db,$code);
 if(!$course)throw new NuFailure(404,'NOT_FOUND','The readable material for this course is not available yet.');
 $sections=split_course_into_sections($course['text']);return ['course_code'=>$code,'source_hash'=>$course['source_hash'],'sections'=>$sections];
}
function nu_profile_details(NuStore $s,int $uid):array {return $s->row('SELECT programme,level,matric_number,preferences_json FROM nu_app_profiles WHERE user_id=?',[$uid])??['programme'=>'','level'=>'','matric_number'=>'','preferences_json'=>'{}'];}
function nu_profile_save(NuStore $s,int $uid,array $b):array {
 $name=trim((string)($b['name']??''));if($name!==''&&mb_strlen($name)<=100)$s->run('UPDATE summary_users SET name=? WHERE id=?',[$name,$uid]);
 $preferences=[];foreach(['academic','materials','payments','general'] as $k)$preferences[$k]=(bool)($b['preferences'][$k]??true);
 $s->run('INSERT INTO nu_app_profiles(user_id,programme,level,matric_number,preferences_json) VALUES (?,?,?,?,?) ON DUPLICATE KEY UPDATE programme=VALUES(programme),level=VALUES(level),matric_number=VALUES(matric_number),preferences_json=VALUES(preferences_json)',[$uid,mb_substr((string)($b['programme']??''),0,150),mb_substr((string)($b['level']??''),0,10),mb_substr((string)($b['matric_number']??''),0,40),json_encode($preferences)]);return nu_profile_details($s,$uid);
}
