<?php
declare(strict_types=1);

final class NuFailure extends RuntimeException {
    public function __construct(public readonly int $status, public readonly string $reason, string $message) {
        parent::__construct($message);
    }
}
function nu_money_to_kobo(mixed $value): int {
    $value = (string)$value;
    if (!preg_match('/^(0|[1-9][0-9]{0,9})(?:\.([0-9]{1,2}))?$/D', $value, $m)) {
        throw new NuFailure(422, 'INVALID_AMOUNT', 'Invalid monetary amount.');
    }
    return (int)$m[1] * 100 + (int)str_pad($m[2] ?? '', 2, '0');
}
function nu_decimal(int $kobo): string {
    if ($kobo < 0) throw new InvalidArgumentException('Negative amount.');
    return intdiv($kobo,100).'.'.str_pad((string)($kobo%100),2,'0',STR_PAD_LEFT);
}
function nu_key(string $key): string {
    if (!preg_match('/^[A-Za-z0-9_-]{16,96}$/D', $key)) {
        throw new NuFailure(400,'IDEMPOTENCY_REQUIRED','A valid Idempotency-Key is required.');
    }
    return $key;
}
function nu_safe_checkout(string $url): bool {
    $p = parse_url($url); $h = strtolower($p['host'] ?? '');
    return ($p['scheme'] ?? '') === 'https' && !isset($p['user']) && !isset($p['pass'])
        && ($h === 'paystack.com' || str_ends_with($h,'.paystack.com'));
}

final class NuStore {
    public function __construct(public PDO $db, public PDO $content, public array $config) {}

    public function row(string $sql, array $args = []): ?array {
        $s=$this->db->prepare($sql); $s->execute($args); return $s->fetch() ?: null;
    }
    public function run(string $sql, array $args = []): PDOStatement {
        $s=$this->db->prepare($sql); $s->execute($args); return $s;
    }
    public function transactional(array $tables): void {
        foreach ($tables as $table) {
            $r=$this->row('SELECT ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=?',[$table]);
            if (strtoupper($r['ENGINE']??'')!=='INNODB') {
                throw new NuFailure(503,'SCHEMA_NOT_READY','The wallet upgrade needs administrator setup. No payment was deducted.');
            }
        }
    }
    public function rate(string $scope, string $identity, int $limit, int $seconds): void {
        $bucket=hash('sha256',$scope.'|'.$identity.'|'.intdiv(time(),$seconds));
        $this->run('INSERT INTO nu_app_rate_limits(bucket,hits,expires_at) VALUES (?,1,?) ON DUPLICATE KEY UPDATE hits=hits+1',
            [$bucket,gmdate('Y-m-d H:i:s',(intdiv(time(),$seconds)+1)*$seconds)]);
        $row=$this->row('SELECT hits FROM nu_app_rate_limits WHERE bucket=?',[$bucket]);
        if ((int)$row['hits']>$limit) throw new NuFailure(429,'RATE_LIMIT','Too many attempts. Please try again later.');
    }
    public function profile(array $u): array {
        return ['id'=>(string)$u['id'],'name'=>$u['name'],'email'=>$u['email'],
            'account_type'=>'shared_course_summary_account'];
    }
    private function newTokens(array $u, ?int $sessionId = null): array {
        $access=bin2hex(random_bytes(32)); $refresh=bin2hex(random_bytes(40));
        $args=[hash('sha256',$access),hash('sha256',$refresh),hash('sha256',$u['password']),
            gmdate('Y-m-d H:i:s',time()+900),gmdate('Y-m-d H:i:s',time()+2592000)];
        if ($sessionId === null) {
            $this->run('INSERT INTO nu_app_sessions(access_hash,refresh_hash,password_fingerprint,access_expires,refresh_expires,user_id) VALUES (?,?,?,?,?,?)', [...$args,(int)$u['id']]);
        } else {
            $this->run('UPDATE nu_app_sessions SET access_hash=?,refresh_hash=?,password_fingerprint=?,access_expires=?,refresh_expires=? WHERE id=?',[...$args,$sessionId]);
        }
        return ['access_token'=>$access,'refresh_token'=>$refresh,'expires_in'=>900,'profile'=>$this->profile($u)];
    }
    public function login(string $email, string $password, string $ip): array {
        $email=strtolower(trim($email));
        $this->rate('login-ip',$ip,30,900); $this->rate('login-email',$email,10,900);
        if (strlen($email)>190 || strlen($password)>1024) throw new NuFailure(401,'INVALID_LOGIN','Email or password is incorrect.');
        $u=$this->row('SELECT id,name,email,password FROM summary_users WHERE email=? LIMIT 1',[$email]);
        // A fixed real bcrypt hash keeps nonexistent-user failures comparable.
        $hash=$u['password']??'$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.';
        if (!password_verify($password,$hash) || !$u) throw new NuFailure(401,'INVALID_LOGIN','Email or password is incorrect.');
        return $this->newTokens($u);
    }
    public function refresh(string $token): array {
        if (!preg_match('/^[a-f0-9]{80}$/D',$token)) throw new NuFailure(401,'SESSION_EXPIRED','Please sign in again.');
        $this->db->beginTransaction();
        try {
            $s=$this->row('SELECT * FROM nu_app_sessions WHERE refresh_hash=? FOR UPDATE',[hash('sha256',$token)]);
            $u=$s?$this->row('SELECT id,name,email,password FROM summary_users WHERE id=?',[$s['user_id']]):null;
            if (!$s || !$u || $s['revoked'] || $s['refresh_expires']<=gmdate('Y-m-d H:i:s') ||
                !hash_equals($s['password_fingerprint'],hash('sha256',$u['password']))) {
                throw new NuFailure(401,'SESSION_EXPIRED','Please sign in again.');
            }
            $result=$this->newTokens($u,(int)$s['id']); $this->db->commit(); return $result;
        } catch (Throwable $e) { if($this->db->inTransaction())$this->db->rollBack(); throw $e; }
    }
    public function authenticate(string $token): array {
        if (!preg_match('/^[a-f0-9]{64}$/D',$token)) throw new NuFailure(401,'LOGIN_REQUIRED','Please sign in.');
        $s=$this->row('SELECT s.id AS session_id,s.password_fingerprint,u.id,u.name,u.email,u.password FROM nu_app_sessions s JOIN summary_users u ON u.id=s.user_id WHERE s.access_hash=? AND s.revoked=0 AND s.access_expires>?',
            [hash('sha256',$token),gmdate('Y-m-d H:i:s')]);
        if (!$s || !hash_equals($s['password_fingerprint'],hash('sha256',$s['password']))) throw new NuFailure(401,'SESSION_EXPIRED','Please sign in again.');
        return $s;
    }
    public function wallet(int $uid): array {
        $u=$this->row('SELECT balance FROM summary_users WHERE id=?',[$uid]);
        if (!$u) throw new NuFailure(401,'LOGIN_REQUIRED','Please sign in.');
        $transactions=$this->run('SELECT id,amount,type,description,reference,created_at FROM summary_transactions WHERE user_id=? ORDER BY id DESC LIMIT 50',[$uid])->fetchAll();
        $items=[];
        foreach($transactions as $t) $items[]=['id'=>(string)$t['id'],'title'=>$t['description'],
            'amount_kobo'=>nu_money_to_kobo($t['amount'])*($t['type']==='debit'?-1:1),
            'reference'=>$t['reference'],'created_at'=>$t['created_at']];
        return ['balance_kobo'=>nu_money_to_kobo($u['balance']),'currency'=>'NGN','transactions'=>$items,
            'shared_services'=>['course-summary','exam-summary'],
            'funding_url'=>$this->config['site_url'].'/course/wallet.php'];
    }
    private function payments(): void {
        require_once $this->config['root'].'/course/paystack.php';
        wallet_assert_transactional_storage($this->db);
    }
    public function fund(array $u, int $amount, string $key): array {
        nu_key($key); $this->payments();
        $min=max(100,(int)env_value('PAYSTACK_MIN_TOPUP','500'))*100;
        $max=max(intdiv($min,100),(int)env_value('PAYSTACK_MAX_TOPUP','200000'))*100;
        if ($amount<$min || $amount>$max || $amount%100!==0) throw new NuFailure(422,'INVALID_AMOUNT','Enter a whole-naira amount within the wallet funding limits.');
        $ref='NUW-'.(int)$u['id'].'-'.strtoupper(substr(hash('sha256',$u['id'].'|'.$key),0,20));
        $lock='nu-fund-'.substr(hash('sha256',$ref),0,48);
        if (!(int)$this->row('SELECT GET_LOCK(?,0) AS acquired',[$lock])['acquired']) throw new NuFailure(409,'IN_PROGRESS','This funding request is already processing. Retry with the same key.');
        try {
            $intent=$this->row('SELECT * FROM payment_intents WHERE reference=?',[$ref]);
            if ($intent && ((int)$intent['user_id']!==(int)$u['id'] || (int)$intent['amount_kobo']!==$amount)) throw new NuFailure(409,'KEY_REUSED','Use a new request key for a different amount.');
            if ($intent && !empty($intent['authorization_url'])) return ['reference'=>$ref,'authorization_url'=>$intent['authorization_url'],'status'=>$intent['status']];
            if (!$intent) $this->run('INSERT INTO payment_intents(user_id,customer_email,reference,amount_naira,amount_kobo,currency,status,created_at,updated_at) VALUES (?,?,?,?,?,"NGN","pending",NOW(),NOW())',
                [$u['id'],strtolower($u['email']),$ref,nu_decimal($amount),$amount]);
            // The SAME reference is used on retry. A timeout cannot create a second credit.
            $response=paystack_request('POST','/transaction/initialize',[
                'email'=>$u['email'],'amount'=>(string)$amount,'currency'=>'NGN','reference'=>$ref,
                'callback_url'=>$this->config['site_url'].'/course/central-wallet-return.php',
                'metadata'=>['purpose'=>'NOUN Update central wallet','user_id'=>(int)$u['id']]]);
            $d=$response['data']??[];
            if (!nu_safe_checkout((string)($d['authorization_url']??'')) || ($d['reference']??'')!==$ref) throw new NuFailure(502,'GATEWAY_ERROR','Payment provider returned an unexpected response. Recheck the same request.');
            $this->run('UPDATE payment_intents SET authorization_url=?,access_code=?,status=CASE WHEN status="credited" THEN status ELSE "initialized" END,updated_at=NOW() WHERE reference=?',
                [$d['authorization_url'],$d['access_code']??'',$ref]);
            return ['reference'=>$ref,'authorization_url'=>$d['authorization_url'],'status'=>'initialized'];
        } finally { $this->run('SELECT RELEASE_LOCK(?)',[$lock]); }
    }
    public function verifyFunding(int $uid, string $reference): array {
        $intent=$this->row('SELECT reference,status FROM payment_intents WHERE reference=? AND user_id=?',[$reference,$uid]);
        if (!$intent) throw new NuFailure(404,'NOT_FOUND','Payment not found.');
        $this->payments();
        if ($intent['status']!=='credited') {
            $r=paystack_request('GET','/transaction/verify/'.rawurlencode($reference));
            if (($r['data']['status']??'')==='success') finalize_wallet_payment($this->db,$r['data']);
        }
        return ['reference'=>$reference,'status'=>$this->row('SELECT status FROM payment_intents WHERE reference=?',[$reference])['status'], 'wallet'=>$this->wallet($uid)];
    }
    public function localFile(string $stored): string {
        $root=$this->config['root'];
        $url=parse_url($stored);
        if (isset($url['scheme'])) {
            if (($url['scheme']??'')!=='https' || ($url['host']??'')!==parse_url($this->config['site_url'],PHP_URL_HOST)) throw new NuFailure(422,'FILE_UNAVAILABLE','This resource needs a local download mapping before wallet purchase.');
            $stored=rawurldecode($url['path']??'');
        }
        // Existing admin stores ../file_storage/name.pdf relative to power-space.
        $stored=preg_replace('#^\.\./#','',$stored);
        $candidate=realpath($root.'/'.ltrim($stored,'/'));
        foreach($this->config['download_roots'] as $allowed) {
            $base=realpath($allowed);
            if ($candidate && $base && str_starts_with($candidate,$base.DIRECTORY_SEPARATOR) && is_file($candidate) && is_readable($candidate)) return $candidate;
        }
        throw new NuFailure(422,'FILE_UNAVAILABLE','The resource is temporarily unavailable. Your wallet has not been charged.');
    }
    public function quote(int $uid, array $ids): array {
        $ids=array_values(array_unique(array_map('intval',$ids))); sort($ids);
        if (!$ids || count($ids)>30 || min($ids)<1) throw new NuFailure(422,'INVALID_CART','Choose between 1 and 30 valid Exam Summaries.');
        $sql='SELECT id,name,price,file_path FROM files WHERE id IN ('.implode(',',array_fill(0,count($ids),'?')).') ORDER BY id';
        $s=$this->content->prepare($sql); $s->execute($ids); $files=$s->fetchAll();
        if(count($files)!==count($ids))throw new NuFailure(422,'INVALID_CART','One or more summaries are no longer available.');
        $subtotal=0; $items=[];
        foreach($files as $file) {
            $this->localFile($file['file_path']);
            $price=nu_money_to_kobo($file['price']);
            $subtotal+=$price;
            $items[]=['file_id'=>(int)$file['id'],'name'=>$file['name'],'price_kobo'=>$price,'file_path'=>$file['file_path']];
        }
        $fee=intdiv($subtotal*(int)$this->config['exam_fee_basis_points']+5000,10000);
        if($subtotal+$fee>200000000)throw new NuFailure(422,'CART_LIMIT','Please reduce the size of this order.');
        $id=bin2hex(random_bytes(16)); $expires=gmdate('Y-m-d H:i:s',time()+600);
        $this->run('INSERT INTO nu_app_quotes(id,user_id,items_json,subtotal_kobo,fee_kobo,total_kobo,expires_at) VALUES (?,?,?,?,?,?,?)',
            [$id,$uid,json_encode($items,JSON_THROW_ON_ERROR),$subtotal,$fee,$subtotal+$fee,$expires]);
        return ['quote_id'=>$id,'items'=>array_map(static function($i){unset($i['file_path']);return $i;},$items),
            'subtotal_kobo'=>$subtotal,'fee_kobo'=>$fee,'total_kobo'=>$subtotal+$fee,'expires_at'=>$expires.'Z'];
    }
    public function purchase(int $uid, string $quote, string $key): array {
        nu_key($key);
        $this->transactional(['summary_users','summary_transactions','nu_app_quotes','nu_app_orders','nu_app_order_items']);
        $this->db->beginTransaction();
        try {
            // Every new debit serialises on the SAME existing wallet account row.
            $wallet=$this->row('SELECT balance FROM summary_users WHERE id=? FOR UPDATE',[$uid]);
            if(!$wallet)throw new NuFailure(401,'LOGIN_REQUIRED','Please sign in.');
            $old=$this->row('SELECT id,quote_id FROM nu_app_orders WHERE user_id=? AND request_key=?',[$uid,$key]);
            if($old && $old['quote_id']!==$quote)throw new NuFailure(409,'KEY_REUSED','This request key belongs to a different order.');
            if(!$old)$old=$this->row('SELECT id FROM nu_app_orders WHERE user_id=? AND quote_id=?',[$uid,$quote]);
            if($old){$this->db->commit();return $this->order($uid,(int)$old['id']);}
            $q=$this->row('SELECT * FROM nu_app_quotes WHERE id=? AND user_id=? FOR UPDATE',[$quote,$uid]);
            if(!$q || $q['expires_at']<=gmdate('Y-m-d H:i:s'))throw new NuFailure(409,'QUOTE_EXPIRED','Refresh your order total before paying.');
            $items=json_decode($q['items_json'],true,512,JSON_THROW_ON_ERROR);
            foreach($items as $i)$this->localFile($i['file_path']);
            $total=(int)$q['total_kobo'];
            if(nu_money_to_kobo($wallet['balance'])<$total)throw new NuFailure(402,'INSUFFICIENT_BALANCE','Your wallet balance is insufficient. Fund it and retry this order.');
            $reference='NU-EXAM-'.strtoupper(bin2hex(random_bytes(16)));
            $this->run('INSERT INTO nu_app_orders(user_id,quote_id,request_key,reference,subtotal_kobo,fee_kobo,total_kobo) VALUES (?,?,?,?,?,?,?)',
                [$uid,$quote,$key,$reference,$q['subtotal_kobo'],$q['fee_kobo'],$total]);
            $id=(int)$this->db->lastInsertId();
            foreach($items as $i)$this->run('INSERT INTO nu_app_order_items(order_id,file_id,name,file_path,price_kobo) VALUES (?,?,?,?,?)',
                [$id,$i['file_id'],$i['name'],$i['file_path'],$i['price_kobo']]);
            if($total>0){
                $debit=$this->run('UPDATE summary_users SET balance=balance-? WHERE id=? AND balance>=?',[nu_decimal($total),$uid,nu_decimal($total)]);
                if($debit->rowCount()!==1)throw new NuFailure(409,'BALANCE_CHANGED','Your balance changed. Please retry.');
                $this->run('INSERT INTO summary_transactions(user_id,amount,type,description,reference) VALUES (?,?,"debit",?,?)',
                    [$uid,nu_decimal($total),'Exam Summary order #'.$id,$reference]);
            }
            $this->db->commit();return $this->order($uid,$id);
        } catch(Throwable $e){if($this->db->inTransaction())$this->db->rollBack();throw $e;}
    }
    public function order(int $uid,int $id): array {
        $o=$this->row('SELECT id,reference,subtotal_kobo,fee_kobo,total_kobo,created_at FROM nu_app_orders WHERE id=? AND user_id=?',[$id,$uid]);
        if(!$o)throw new NuFailure(404,'NOT_FOUND','Order not found.');
        $o['items']=$this->run('SELECT id,file_id,name,price_kobo FROM nu_app_order_items WHERE order_id=?',[$id])->fetchAll();
        return $o;
    }
    public function downloadTicket(int $uid,int $item): array {
        $r=$this->row('SELECT i.file_path FROM nu_app_order_items i JOIN nu_app_orders o ON o.id=i.order_id WHERE i.id=? AND o.user_id=?',[$item,$uid]);
        if(!$r)throw new NuFailure(404,'NOT_FOUND','Purchased resource not found.');
        $this->localFile($r['file_path']); $token=bin2hex(random_bytes(32));
        $this->run('INSERT INTO nu_app_downloads(token_hash,user_id,item_id,expires_at) VALUES (?,?,?,?)',
            [hash('sha256',$token),$uid,$item,gmdate('Y-m-d H:i:s',time()+120)]);
        return ['url'=>$this->config['site_url'].'/api/v1/download?ticket='.$token,'expires_in'=>120];
    }
    public function takeDownload(string $token): array {
        if(!preg_match('/^[a-f0-9]{64}$/D',$token))throw new NuFailure(404,'NOT_FOUND','Download link expired.');
        $this->db->beginTransaction();
        try {
            $r=$this->row('SELECT d.token_hash,i.file_path,i.name FROM nu_app_downloads d JOIN nu_app_order_items i ON i.id=d.item_id JOIN nu_app_orders o ON o.id=i.order_id AND o.user_id=d.user_id WHERE d.token_hash=? AND d.used_at IS NULL AND d.expires_at>? FOR UPDATE',
                [hash('sha256',$token),gmdate('Y-m-d H:i:s')]);
            if(!$r)throw new NuFailure(404,'NOT_FOUND','Download link expired. Open your purchase to get another.');
            $path=$this->localFile($r['file_path']);
            $this->run('UPDATE nu_app_downloads SET used_at=NOW() WHERE token_hash=?',[$r['token_hash']]);
            $this->db->commit();return ['path'=>$path,'name'=>basename($path)];
        }catch(Throwable $e){if($this->db->inTransaction())$this->db->rollBack();throw $e;}
    }
}
