<?php
declare(strict_types=1);
ini_set('display_errors','0');
header('Cache-Control: no-store');
header('X-Frame-Options: DENY');
header('X-Content-Type-Options: nosniff');
require_once dirname(__DIR__,2).'/includes/central-wallet-auth.php';
require_once dirname(__DIR__,2).'/nu-mobile/companion/service.php';
// Explicit central-account allowlist: no inference from email, legacy IDs or client fields.
$account=nu_current_account(true);
$allowed=array_filter(array_map('trim',explode(',',(string)getenv('NU_MOBILE_ADMIN_ACCOUNT_IDS'))),static fn($v)=>ctype_digit($v));
if(!$account||!in_array((string)$account['id'],$allowed,true)){http_response_code(403);exit('Authorised mobile administrators only.');}
$pdo=nu_auth_pdo();$service=new NuCompanion($pdo);
function h(mixed $v):string{return htmlspecialchars((string)$v,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8');}
function textInput(string $key,int $max=500):string{$v=$_POST[$key]??'';if(!is_string($v)||mb_strlen($v)>$max)throw new InvalidArgumentException('Invalid '.$key);return trim($v);}
function moneyInput(string $key):int{$v=textInput($key,16);if(!preg_match('/^\d{1,9}(?:\.\d{1,2})?$/D',$v))throw new InvalidArgumentException('Enter a valid price.');$p=explode('.',$v);return (int)$p[0]*100+(int)str_pad($p[1]??'',2,'0');}
function dateInput(string $key,bool $dateOnly=false):?string{$v=textInput($key,25);if($v==='')return null;$format=$dateOnly?'Y-m-d':'Y-m-d\TH:i';$d=DateTimeImmutable::createFromFormat('!'.$format,$v,new DateTimeZone('UTC'));if(!$d||$d->format($format)!==$v)throw new InvalidArgumentException('Enter a valid date.');return $d->format($dateOnly?'Y-m-d':'Y-m-d H:i:s');}
function row(PDO $db,string $sql,array $args=[]):array{$s=$db->prepare($sql);$s->execute($args);return $s->fetch(PDO::FETCH_ASSOC)?:[];}
$message='';
if(($_SERVER['REQUEST_METHOD']??'GET')==='POST'){
 try{
  nu_wallet_verify_csrf(textInput('csrf',100),'mobile-admin');
  $reason=textInput('reason');if($reason==='')throw new InvalidArgumentException('Enter an audit reason.');
  $action=textInput('action',50);$target=null;$old=[];$new=[];
  $pdo->beginTransaction();
  if($action==='configuration'){
   $old=row($pdo,'SELECT * FROM nu_mobile_configuration WHERE id=1 FOR UPDATE');
   $features=json_decode($old['features_json']??'{}',true)?:[];
   // Only implemented benefits may currently be enabled in this administrator UI.
   foreach(['ad_free','premium_skins'] as $feature)$features[$feature]=isset($_POST[$feature]);
   $new=['premium_enabled'=>isset($_POST['premium_enabled']),'features'=>$features];
   $pdo->prepare('UPDATE nu_mobile_configuration SET premium_enabled=?,features_json=? WHERE id=1')->execute([(int)$new['premium_enabled'],json_encode($features)]);
  }elseif($action==='plan'){
   $id=textInput('plan_id',50);$old=row($pdo,'SELECT * FROM nu_mobile_premium_plans WHERE id=? FOR UPDATE',[$id]);if(!$old)throw new InvalidArgumentException('Plan not found.');
   $regular=moneyInput('regular_price');$promo=textInput('promo_price',16)===''?null:moneyInput('promo_price');
   $start=dateInput('promo_starts_at');$end=dateInput('promo_ends_at');$promoEnabled=isset($_POST['promo_enabled']);
   $duration=filter_var($_POST['duration_months']??null,FILTER_VALIDATE_INT,['options'=>['min_range'=>1,'max_range'=>24]]);
   $sort=filter_var($_POST['sort_order']??null,FILTER_VALIDATE_INT,['options'=>['min_range'=>0,'max_range'=>999]]);
   if(!$duration||$sort===false||$regular<1||($promoEnabled&&($promo===null||$promo<1||$promo>=$regular||!$start||!$end||$end<=$start)))throw new InvalidArgumentException('Check duration, price and promotion dates.');
   $new=['enabled'=>(int)isset($_POST['enabled']),'regular_price_minor'=>$regular,'promo_price_minor'=>$promo,'promo_enabled'=>(int)$promoEnabled,'promo_starts_at'=>$start,'promo_ends_at'=>$end,'promo_name'=>textInput('promo_name',100),'promo_text'=>textInput('promo_text',250),'badge'=>textInput('badge',100),'duration_months'=>$duration,'sort_order'=>$sort];
   $pdo->prepare('UPDATE nu_mobile_premium_plans SET enabled=?,regular_price_minor=?,promo_price_minor=?,promo_enabled=?,promo_starts_at=?,promo_ends_at=?,promo_name=?,promo_text=?,badge=?,duration_months=?,sort_order=? WHERE id=?')->execute([...array_values($new),$id]);
  }elseif($action==='quote'){
   $id=(int)textInput('quote_id',20);$old=$id?row($pdo,'SELECT * FROM nu_mobile_motivation WHERE id=? FOR UPDATE',[$id]):[];
   if($id&&!$old)throw new InvalidArgumentException('Quote not found.');
   $quote=textInput('quote',2000);$author=textInput('author',150);if($quote==='')throw new InvalidArgumentException('Enter quote text.');
   $category=textInput('category',50);if(!preg_match('/^[a-z_]{1,50}$/D',$category))throw new InvalidArgumentException('Use a lowercase category.');
   $start=dateInput('starts_at');$end=dateInput('ends_at');if($start&&$end&&$end<=$start)throw new InvalidArgumentException('End must follow start.');
   $new=['quote'=>$quote,'author'=>$author?:'NOUN Update','category'=>$category,'active'=>(int)isset($_POST['active']),'featured'=>(int)isset($_POST['featured']),'schedule_date'=>dateInput('schedule_date',true),'starts_at'=>$start,'ends_at'=>$end];
   if($id)$pdo->prepare('UPDATE nu_mobile_motivation SET quote=?,author=?,category=?,active=?,featured=?,schedule_date=?,starts_at=?,ends_at=? WHERE id=?')->execute([...array_values($new),$id]);
   else {$pdo->prepare('INSERT INTO nu_mobile_motivation(quote,author,category,active,featured,schedule_date,starts_at,ends_at) VALUES(?,?,?,?,?,?,?,?)')->execute(array_values($new));$id=(int)$pdo->lastInsertId();}
   $new['id']=$id;
  }elseif($action==='access'){
   $target=filter_var($_POST['account_id']??null,FILTER_VALIDATE_INT,['options'=>['min_range'=>1]]);
   if(!$target||!row($pdo,'SELECT id FROM nu_accounts WHERE id=?',[$target]))throw new InvalidArgumentException('Central account not found.');
   // Lock the central account to serialize manual access changes.
   row($pdo,'SELECT id FROM nu_accounts WHERE id=? FOR UPDATE',[$target]);
   $old=$service->entitlement($target);$mode=textInput('mode',30);
   if($mode==='expire'){
    $pdo->prepare("UPDATE nu_mobile_premium_subscriptions SET status='cancelled' WHERE account_id=? AND status='active'")->execute([$target]);
   }elseif($mode==='grant'){
    $plan=textInput('plan_id',50);if(!row($pdo,'SELECT id FROM nu_mobile_premium_plans WHERE id=?',[$plan]))throw new InvalidArgumentException('Plan not found.');
    $expires=dateInput('expires_at');$now=gmdate('Y-m-d H:i:s');if(!$expires||$expires<=$now)throw new InvalidArgumentException('Expiry must be in the future.');
    $pdo->prepare("INSERT INTO nu_mobile_premium_subscriptions(account_id,plan_id,status,started_at,expires_at,regular_price_minor,amount_paid_minor,payment_provider,payment_reference) VALUES(?,?,'active',?,?,0,0,'complimentary',?)")->execute([$target,$plan,$now,$expires,'admin-'.bin2hex(random_bytes(16))]);
   }else throw new InvalidArgumentException('Invalid access action.');
   $new=$service->entitlement($target);
  }else throw new InvalidArgumentException('Invalid action.');
  $pdo->prepare('INSERT INTO nu_mobile_admin_audit(admin_id,account_id,action,old_value,new_value,reason) VALUES(?,?,?,?,?,?)')->execute([(string)$account['id'],$target,$action,json_encode($old),json_encode($new),$reason]);
  $pdo->commit();header('Location: ./?saved=1',true,303);exit;
 }catch(Throwable $e){if($pdo->inTransaction())$pdo->rollBack();error_log('[MOBILE ADMIN] '.$e->getMessage());$message=$e instanceof InvalidArgumentException?$e->getMessage():'The change could not be saved. Reload and try again.';}
}
$csrf=nu_wallet_csrf_token('mobile-admin');
$config=$service->configuration();$plans=$pdo->query('SELECT * FROM nu_mobile_premium_plans ORDER BY sort_order')->fetchAll(PDO::FETCH_ASSOC);
$quotes=$pdo->query('SELECT * FROM nu_mobile_motivation ORDER BY id DESC LIMIT 100')->fetchAll(PDO::FETCH_ASSOC);
$active=(int)$pdo->query("SELECT COUNT(DISTINCT account_id) FROM nu_mobile_premium_subscriptions WHERE status='active' AND started_at<=UTC_TIMESTAMP() AND expires_at>UTC_TIMESTAMP()")->fetchColumn();
function hiddenFields(string $action):void{global $csrf;echo '<input type="hidden" name="csrf" value="'.h($csrf).'"><input type="hidden" name="action" value="'.h($action).'">';}
function reason():void{echo '<label>Reason for this change<input name="reason" required maxlength="500"></label><button>Save changes</button>';}
function dateValue(?string $v):string{return $v?substr(str_replace(' ','T',$v),0,16):'';}
?><!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Mobile App Management | NOUN Update</title><style>
body{font:16px system-ui;background:#f4f7f2;color:#173a2a;margin:0}main{max-width:1000px;margin:auto;padding:24px}section,details{background:white;padding:22px;border:1px solid #d9e4dc;border-radius:14px;margin:16px 0}h1,h2{line-height:1.2}label{display:block;margin:12px 0}input,textarea,select{display:block;padding:10px;border:1px solid #a7bbb0;border-radius:6px;width:100%;box-sizing:border-box;font:inherit}input[type=checkbox]{display:inline;width:auto}button{background:#005538;color:white;border:0;border-radius:8px;padding:12px 20px;cursor:pointer}small{color:#53685e}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:16px}.notice{padding:15px;background:#fff0c0}table{width:100%;border-collapse:collapse}td,th{text-align:left;padding:10px;border-bottom:1px solid #ddd}</style></head><body><main>
<h1>Mobile App Management</h1><p>Premium personalisation and free student motivation.</p>
<?php if($message):?><p class="notice"><?=h($message)?></p><?php endif;?><?php if(isset($_GET['saved'])):?><p class="notice">Changes saved and audited.</p><?php endif;?>
<p><strong><?=$active?></strong> active Premium accounts. Dates and promotion times below use UTC. Quotes use the Nigerian calendar date.</p>
<section><h2>Premium master control</h2><form method="post"><?php hiddenFields('configuration');?><label><input type="checkbox" name="premium_enabled" <?=$config['premium_enabled']?'checked':''?>> Premium system enabled</label><?php foreach(['ad_free'=>'Ad-free','premium_skins'=>'Premium skins'] as $k=>$label):?><label><input type="checkbox" name="<?=h($k)?>" <?=!empty($config['premium_features'][$k])?'checked':''?>> <?=h($label)?></label><?php endforeach;?><p>New subscriptions and renewals stay disabled until the verified purchase integration is installed. Unimplemented benefits are not advertised.</p><?php reason();?></form></section>
<h2>Plans and promotions</h2><div class="grid"><?php foreach($plans as $p):?><section><h3><?=h($p['name'])?></h3><form method="post"><?php hiddenFields('plan');?><input type="hidden" name="plan_id" value="<?=h($p['id'])?>"><label><input type="checkbox" name="enabled" <?=$p['enabled']?'checked':''?>> Enabled</label><label>Regular price (NGN)<input name="regular_price" value="<?=h(number_format((int)$p['regular_price_minor']/100,2,'.',''))?>" required></label><label>Duration (calendar months)<input type="number" name="duration_months" min="1" max="24" value="<?=h($p['duration_months'])?>"></label><label>Display order<input type="number" name="sort_order" min="0" max="999" value="<?=h($p['sort_order'])?>"></label><label>Badge<input name="badge" value="<?=h($p['badge'])?>" maxlength="100"></label><label><input type="checkbox" name="promo_enabled" <?=$p['promo_enabled']?'checked':''?>> Promotion enabled</label><label>Promo price (NGN)<input name="promo_price" value="<?=$p['promo_price_minor']===null?'':h(number_format((int)$p['promo_price_minor']/100,2,'.',''))?>"></label><label>Promotion name<input name="promo_name" value="<?=h($p['promo_name'])?>" maxlength="100"></label><label>Promotion text<input name="promo_text" value="<?=h($p['promo_text'])?>" maxlength="250"></label><label>Starts (UTC)<input type="datetime-local" name="promo_starts_at" value="<?=h(dateValue($p['promo_starts_at']))?>"></label><label>Ends (UTC)<input type="datetime-local" name="promo_ends_at" value="<?=h(dateValue($p['promo_ends_at']))?>"></label><?php reason();?></form></section><?php endforeach;?></div>
<section><h2>Complimentary access / payment reconciliation</h2><p>Never records a new payment or changes wallet balances. Use a verified central account ID.</p><form method="post"><?php hiddenFields('access');?><label>Central account ID<input type="number" min="1" name="account_id" required></label><label>Action<select name="mode"><option value="grant">Grant / extend complimentary access</option><option value="expire">Expire active access</option></select></label><label>Plan<select name="plan_id"><?php foreach($plans as $p):?><option value="<?=h($p['id'])?>"><?=h($p['name'])?></option><?php endforeach;?></select></label><label>Access expires (UTC)<input type="datetime-local" name="expires_at"></label><?php reason();?></form></section>
<h2>Free motivational quotes</h2><p>Until the existing website quote source is mapped, this editor manages the mobile quote collection. No sample quotes are seeded.</p>
<?php array_unshift($quotes,['id'=>0,'quote'=>'','author'=>'NOUN Update','category'=>'general','active'=>1,'featured'=>0,'schedule_date'=>null,'starts_at'=>null,'ends_at'=>null]);foreach($quotes as $q):?><details><summary><?= $q['id']?h(mb_substr($q['quote'],0,90)):'Add a new quote'?></summary><form method="post"><?php hiddenFields('quote');?><input type="hidden" name="quote_id" value="<?=h($q['id'])?>"><label>Quote<textarea name="quote" required maxlength="2000" rows="4"><?=h($q['quote'])?></textarea></label><label>Author / source<input name="author" value="<?=h($q['author'])?>" maxlength="150"></label><label>Category<input name="category" value="<?=h($q['category'])?>" pattern="[a-z_]{1,50}" required></label><label><input type="checkbox" name="active" <?=$q['active']?'checked':''?>> Active</label><label><input type="checkbox" name="featured" <?=$q['featured']?'checked':''?>> Featured</label><label>Schedule date (Nigeria)<input type="date" name="schedule_date" value="<?=h($q['schedule_date'])?>"></label><label>Starts (UTC)<input type="datetime-local" name="starts_at" value="<?=h(dateValue($q['starts_at']))?>"></label><label>Ends (UTC)<input type="datetime-local" name="ends_at" value="<?=h(dateValue($q['ends_at']))?>"></label><?php reason();?></form></details><?php endforeach;?>
<section><h2>Recent administration changes</h2><div style="overflow:auto"><table><tr><th>When</th><th>Admin</th><th>Action</th><th>Account</th><th>Reason</th></tr><?php foreach($pdo->query('SELECT admin_id,account_id,action,reason,created_at FROM nu_mobile_admin_audit ORDER BY id DESC LIMIT 50') as $a):?><tr><?php foreach(['created_at','admin_id','action','account_id','reason'] as $k):?><td><?=h($a[$k])?></td><?php endforeach;?></tr><?php endforeach;?></table></div></section>
</main></body></html>
