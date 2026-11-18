<?php
declare(strict_types=1);
require_once __DIR__.'/central-common.php';
$error='';$quote=null;
try{
 if($_SERVER['REQUEST_METHOD']==='POST'){
  nu_csrf();$quoteId=(string)($_POST['quote_id']??'');
  $order=$nuStore->purchase((int)$nuUser['id'],$quoteId,'web-'.hash('sha256',$quoteId));
  header('Location: central-wallet.php?order='.(int)$order['id'],true,303);exit;
 }
 $items=explode(',',(string)($_GET['items']??''));
 $quote=$nuStore->quote((int)$nuUser['id'],$items);
}catch(Throwable $e){$error=$e instanceof NuFailure?$e->getMessage():'Checkout is temporarily unavailable. No new order was completed. Check your purchases before retrying.';}
nu_page('Exam Summary checkout');
?>
<?php if($error):?><p class="notice error"><?=nu_e($error)?></p><p><a href="<?=nu_e($_SERVER['REQUEST_URI']??'central-wallet.php')?>">Refresh checkout</a></p><?php endif;?>
<?php if($quote):?><section><h2>Review your order</h2>
<?php foreach($quote['items'] as $i):?><div class="row"><span><?=nu_e($i['name'])?></span><b><?=nu_cash($i['price_kobo'])?></b></div><?php endforeach;?>
<div class="row"><span>Subtotal</span><b><?=nu_cash($quote['subtotal_kobo'])?></b></div><div class="row"><span>Service charge</span><b><?=nu_cash($quote['fee_kobo'])?></b></div><div class="row total"><span>Total</span><span><?=nu_cash($quote['total_kobo'])?></span></div>
<p>Your balance: <strong><?=nu_cash(nu_money_to_kobo($nuUser['balance']))?></strong>. This quote is valid for 10 minutes.</p>
<form method="post"><input type="hidden" name="csrf_token" value="<?=nu_e(csrf_token())?>"><input type="hidden" name="quote_id" value="<?=nu_e($quote['quote_id'])?>"><button type="submit">Pay <?=nu_cash($quote['total_kobo'])?> from wallet</button></form><p class="muted">Your purchased files become available immediately in Wallet & purchases and in the app.</p></section><?php endif;?>
<?php nu_end(); ?>
