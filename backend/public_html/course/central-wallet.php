<?php
declare(strict_types=1);
require_once __DIR__.'/central-common.php';
$error='';$order=null;
try{
 if($_SERVER['REQUEST_METHOD']==='POST'){
  nu_csrf();$ticket=$nuStore->downloadTicket((int)$nuUser['id'],(int)($_POST['item_id']??0));
  header('Location: '.$ticket['url'],true,303);exit;
 }
 if(isset($_GET['order']))$order=$nuStore->order((int)$nuUser['id'],(int)$_GET['order']);
 $wallet=$nuStore->wallet((int)$nuUser['id']);
 $orders=$nuStore->run('SELECT id,reference,total_kobo,created_at FROM nu_app_orders WHERE user_id=? ORDER BY id DESC LIMIT 100',[$nuUser['id']])->fetchAll();
}catch(Throwable $e){$error=$e instanceof NuFailure?$e->getMessage():'The wallet is temporarily unavailable. Please try again shortly.';}
nu_page('Your central wallet');
?>
<p>Welcome, <?=nu_e($nuUser['name'])?>. Sign into the app with this same account.</p>
<?php if($error):?><p class="notice error"><?=nu_e($error)?></p><?php endif;?>
<?php if(isset($wallet)):?><section><small>AVAILABLE BALANCE</small><div class="balance"><?=nu_cash($wallet['balance_kobo'])?></div><a class="button" href="wallet.php">Add money</a><p class="muted">Your existing Course Summary balance is already included.</p></section><?php endif;?>
<?php if($order):?><section><h2>Exam Summary order #<?=nu_e($order['id'])?></h2><p><?=nu_e($order['reference'])?></p>
<?php foreach($order['items'] as $item):?><div class="row"><span><?=nu_e($item['name'])?></span><form method="post"><input type="hidden" name="csrf_token" value="<?=nu_e(csrf_token())?>"><input type="hidden" name="item_id" value="<?=nu_e($item['id'])?>"><button>Download</button></form></div><?php endforeach;?></section><?php endif;?>
<section><h2>Exam Summary purchases</h2><p class="muted">Purchases made through the central wallet appear here and in the app. Earlier email orders retain their existing access links.</p>
<?php foreach($orders??[] as $o):?><div class="row"><span><a href="?order=<?=nu_e($o['id'])?>">Order #<?=nu_e($o['id'])?></a><br><small><?=nu_e($o['created_at'])?></small></span><b><?=nu_cash((int)$o['total_kobo'])?></b></div><?php endforeach;?>
<?php if(empty($orders)):?><p>No wallet purchases yet.</p><?php endif;?></section>
<section><h2>Recent wallet activity</h2><?php foreach($wallet['transactions']??[] as $t):?><div class="row"><span><?=nu_e($t['title'])?><br><small><?=nu_e($t['created_at'])?></small></span><b class="<?=$t['amount_kobo']<0?'negative':'positive'?>"><?=$t['amount_kobo']<0?'−':'+'?><?=nu_cash(abs($t['amount_kobo']))?></b></div><?php endforeach;?></section>
<?php nu_end(); ?>
