<?php
declare(strict_types=1);
if(PHP_SAPI!=='cli'){http_response_code(404);exit;}
$root=rtrim($argv[1]??'','/');
if(!$root||!is_file($root.'/nu-mobile/bootstrap.php')){fwrite(STDERR,"Usage: php preflight.php /absolute/path/to/public_html\n");exit(1);}
try{
 require $root.'/nu-mobile/bootstrap.php';
 $db=nu_connect($nuConfig['wallet_db']);$content=nu_connect($nuConfig['content_db']);
 $store=new NuStore($db,$content,$nuConfig);
 $store->transactional(['summary_users','summary_transactions','payment_intents','wallet_credit_receipts','user_summaries','nu_app_sessions','nu_app_rate_limits','nu_app_quotes','nu_app_orders','nu_app_order_items','nu_app_downloads','nu_app_profiles','nu_app_resets','nu_app_study_state']);
 foreach(['news_upload'=>['id','title','message','ref_id'], 'guides_upload'=>['id','title','message','ref_id'],
  'scholarship_upload'=>['id','title','message','ref_id'],'files'=>['id','name','price','file_path'],'pdf_upload_cm'=>['id','course_code','filename'],'fee_check'=>['program','level','semester','ccode','ctitle','cfee','efee','csfee','cstatus','cunit']] as $table=>$required){
  $cols=$content->query('SHOW COLUMNS FROM `'.$table.'`')->fetchAll(PDO::FETCH_COLUMN);
  foreach($required as $col)if(!in_array($col,$cols,true))throw new RuntimeException($table.'.'.$col.' is missing');
  echo "OK: $table\n";
 }
 foreach(['config.php','paystack.php','paystack_webhook.php','lib/summary_engine.php'] as $name)if(!is_file($root.'/course/'.$name))throw new RuntimeException('course/'.$name.' is missing');
 echo "READY: API tables, shared wallet storage and content mappings.\n";
 echo "Next: verify /api/v1/health; test in Paystack test mode before live checkout.\n";
}catch(Throwable $e){fwrite(STDERR,'NOT READY: '.$e->getMessage()."\n");exit(1);}
