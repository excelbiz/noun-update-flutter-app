<?php
declare(strict_types=1);
// The return URL performs NO crediting. Only authenticated verification or the
// existing signed Paystack webhook can credit a locally stored funding intent.
require_once __DIR__.'/central-common.php';
$message='Return to the app and tap Recheck payment, or open your website wallet.';
$reference=(string)($_GET['reference']??'');
if($reference!==''){
 try{
  $result=$nuStore->verifyFunding((int)$nuUser['id'],$reference);
  $message=$result['status']==='credited'?'Payment verified. Your central wallet is updated. Return to the app and refresh your wallet.':'Payment is not confirmed yet. Recheck the same payment; do not pay again.';
 }catch(Throwable $e){$message='Payment verification is still pending. Recheck the same reference from your wallet; do not pay again.';}
}
nu_page('Wallet payment');?><section><p><?=nu_e($message)?></p><a class="button" href="central-wallet.php">Open wallet</a></section><?php nu_end(); ?>
