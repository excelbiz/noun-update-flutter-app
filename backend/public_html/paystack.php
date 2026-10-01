<?php
declare(strict_types=1);
// New Exam Summary purchases use the shared wallet. The old callback.php is
// deliberately left available to settle already-in-flight legacy payments.
session_start();
$ids=array_values(array_unique(array_filter(array_map('intval',$_SESSION['cart']??[]),static fn($id)=>$id>0)));
if(!$ids){header('Location: /exam-summary',true,303);exit;}
header('Location: /course/exam-checkout.php?items='.rawurlencode(implode(',',$ids)),true,303);
exit;
