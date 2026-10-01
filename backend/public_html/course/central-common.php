<?php
declare(strict_types=1);
require_once __DIR__.'/config.php';
require_once dirname(__DIR__).'/nu-mobile/bootstrap.php';
require_login();
$nuStore=new NuStore($pdo,nu_connect($nuConfig['content_db']),$nuConfig);
$nuUser=$nuStore->row('SELECT id,name,email,balance FROM summary_users WHERE id=?',[(int)$_SESSION['user_id']]);
if(!$nuUser){unset($_SESSION['user_id']);header('Location: auth.php',true,303);exit;}
function nu_e(mixed $v):string{return htmlspecialchars((string)$v,ENT_QUOTES|ENT_SUBSTITUTE,'UTF-8');}
function nu_cash(int $v):string{return '₦'.number_format($v/100,2);}
function nu_page(string $title):void{ ?>
<!doctype html><html lang="en-GB"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title><?=nu_e($title)?> | NOUN Update</title><link rel="icon" href="/images/logo.webp"><link rel="stylesheet" href="/course/central-wallet.css"></head><body><main>
<header><a href="/"><img src="/images/logo.webp" width="64" height="64" alt="NOUN Update"></a><div><small>NOUN UPDATE</small><h1><?=nu_e($title)?></h1></div></header><nav><a href="central-wallet.php">Wallet & purchases</a><a href="wallet.php">Add money</a><a href="summary.php">Course Summary</a><a href="/exam-summary">Exam Summary</a></nav>
<?php }
function nu_end():void{echo '<footer>One balance for Course Summary, Exam Summary wallet purchases and the NOUN Update app.</footer></main></body></html>';}
function nu_csrf():void{
 if(!verify_csrf_token(isset($_POST['csrf_token'])?(string)$_POST['csrf_token']:null))throw new NuFailure(419,'CSRF','Your session expired. Refresh the page and try again.');
}
