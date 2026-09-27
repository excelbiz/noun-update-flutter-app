<?php
declare(strict_types=1);
/** Additive Premium/personalisation service. Wallet debits are server-authoritative and transactional. */
final class NuCompanionException extends RuntimeException {
    public function __construct(public readonly int $status, public readonly string $reason, string $message) { parent::__construct($message); }
}
final class NuCompanion {
    public const SKINS = ['defaultNoun','smartCampus','premiumDark','glassmorphism','studentFriendly','minimalAcademic','elegantEditorial','productivityDashboard','friendlyModern','futureTech','boldPremium'];
    public function __construct(private PDO $pdo, private ?string $websiteQuoteFile=null) {}
    private function rows(string $sql,array $args=[]): array {
        $s=$this->pdo->prepare($sql);$s->execute($args);return $s->fetchAll(PDO::FETCH_ASSOC);
    }
    private function pricedPlan(array $p): array {
        $now=gmdate('Y-m-d H:i:s');
        $promo=(bool)$p['promo_enabled'] && $p['promo_starts_at']!==null && $p['promo_ends_at']!==null && $p['promo_starts_at']<=$now && $p['promo_ends_at']>$now && $p['promo_price_minor']!==null && (int)$p['promo_price_minor']<(int)$p['regular_price_minor'];
        return ['id'=>$p['id'],'name'=>$p['name'],'currency'=>$p['currency'],'regular_price_minor'=>(int)$p['regular_price_minor'],
            'price_minor'=>(int)($promo?$p['promo_price_minor']:$p['regular_price_minor']),'promotion_active'=>$promo,
            'promotion_name'=>$promo?$p['promo_name']:null,'promotion_text'=>$promo?$p['promo_text']:null,
            'billing_period'=>$p['billing_period'],'duration_months'=>(int)$p['duration_months'],'badge'=>$p['badge']];
    }
    public function configuration(): array {
        $c=$this->rows('SELECT * FROM nu_mobile_configuration WHERE id=1')[0]??[];
        $features=json_decode($c['features_json']??'{}',true)?:[];
        $plans=$this->rows('SELECT * FROM nu_mobile_premium_plans WHERE enabled=1 ORDER BY sort_order,id');
        foreach($plans as &$p)$p=$this->pricedPlan($p);
        return ['premium_enabled'=>(bool)($c['premium_enabled']??false),'new_subscriptions_enabled'=>(bool)($c['new_subscriptions_enabled']??false),
            'renewals_enabled'=>(bool)($c['renewals_enabled']??false),'plans'=>$plans,'premium_features'=>$features,'server_time'=>gmdate('c')];
    }
    public function entitlement(int $account): array {
        $c=$this->configuration();
        $s=$this->rows("SELECT plan_id,status,started_at,expires_at,auto_renew FROM nu_mobile_premium_subscriptions WHERE account_id=? AND status='active' AND started_at<=UTC_TIMESTAMP() AND expires_at>UTC_TIMESTAMP() ORDER BY expires_at DESC LIMIT 1",[$account])[0]??null;
        return ['active'=>$c['premium_enabled'] && $s!==null,'plan'=>$s['plan_id']??null,'status'=>$s?'active':'inactive',
            'started_at'=>isset($s['started_at'])?str_replace(' ','T',$s['started_at']).'Z':null,
            'expires_at'=>isset($s['expires_at'])?str_replace(' ','T',$s['expires_at']).'Z':null,
            'auto_renew'=>(bool)($s['auto_renew']??false),'features'=>$c['premium_features'],'server_time'=>gmdate('c')];
    }
    public function purchase(int $account,int $walletUserId,string $planId,int $expectedPriceMinor,string $expectedCurrency,string $requestKey): array {
        $planId=trim($planId);$expectedCurrency=strtoupper(trim($expectedCurrency));$requestKey=trim($requestKey);
        if($account<1||$walletUserId<1)throw new NuCompanionException(409,'WALLET_LINK_REQUIRED','Your account needs an active central wallet link.');
        if(!preg_match('/^[a-z0-9_-]{1,50}$/D',$planId))throw new NuCompanionException(422,'INVALID_PLAN','Choose a valid Premium plan.');
        if($expectedPriceMinor<1||$expectedCurrency!=='NGN')throw new NuCompanionException(422,'INVALID_PRICE','Refresh Premium plans and try again.');
        if(!preg_match('/^[A-Za-z0-9._:-]{16,120}$/D',$requestKey))throw new NuCompanionException(422,'INVALID_REQUEST_KEY','Refresh the page and try the purchase again.');
        $idempotency='premium:'.$account.':'.$requestKey;
        try {
            $this->pdo->beginTransaction();
            // Successful retries must remain recoverable even if pricing or sale switches change later.
            $existingStmt=$this->pdo->prepare("SELECT * FROM nu_cwallet_orders WHERE idempotency_key=? LIMIT 1 FOR UPDATE");
            $existingStmt->execute([$idempotency]);$existing=$existingStmt->fetch(PDO::FETCH_ASSOC)?:null;
            if($existing){
                if((int)$existing['wallet_user_id']!==$walletUserId || (string)$existing['service_code']!=='mobile_premium' || (string)$existing['product_code']!==$planId)
                    throw new NuCompanionException(409,'REQUEST_KEY_REUSED','This purchase request was already used for something else. Refresh and try again.');
                if((string)$existing['status']!=='fulfilled')throw new NuCompanionException(409,'PURCHASE_PENDING','This Premium purchase is still being processed. Please check access before trying again.');
                $subStmt=$this->pdo->prepare("SELECT plan_id,started_at,expires_at,amount_paid_minor,currency FROM nu_mobile_premium_subscriptions WHERE account_id=? AND payment_provider='central_wallet' AND payment_reference=? LIMIT 1");
                $subStmt->execute([$account,$existing['order_reference']]);$sub=$subStmt->fetch(PDO::FETCH_ASSOC);
                $walletStmt=$this->pdo->prepare("SELECT balance_minor FROM nu_cwallet_accounts WHERE wallet_user_id=? AND currency='NGN' LIMIT 1");
                $walletStmt->execute([$walletUserId]);$balance=(int)($walletStmt->fetchColumn()?:0);
                if(!$sub)throw new RuntimeException('Premium purchase exists without its subscription record.');
                $this->pdo->commit();
                return ['duplicate'=>true,'order_reference'=>$existing['order_reference'],'plan_id'=>$sub['plan_id'],'amount_minor'=>(int)$sub['amount_paid_minor'],'currency'=>$sub['currency'],
                    'started_at'=>str_replace(' ','T',$sub['started_at']).'Z','expires_at'=>str_replace(' ','T',$sub['expires_at']).'Z','wallet_balance_minor'=>$balance];
            }
            $configStmt=$this->pdo->query('SELECT * FROM nu_mobile_configuration WHERE id=1 FOR UPDATE');$config=$configStmt->fetch(PDO::FETCH_ASSOC)?:[];
            if(empty($config['premium_enabled']))throw new NuCompanionException(409,'PREMIUM_DISABLED','Premium is currently unavailable. No money has been deducted.');
            $planStmt=$this->pdo->prepare('SELECT * FROM nu_mobile_premium_plans WHERE id=? AND enabled=1 LIMIT 1 FOR UPDATE');
            $planStmt->execute([$planId]);$rawPlan=$planStmt->fetch(PDO::FETCH_ASSOC);
            if(!$rawPlan)throw new NuCompanionException(422,'PLAN_UNAVAILABLE','That Premium plan is not currently available.');
            $plan=$this->pricedPlan($rawPlan);
            if($plan['currency']!=='NGN'||$expectedCurrency!==$plan['currency']||$expectedPriceMinor!==$plan['price_minor'])
                throw new NuCompanionException(409,'PRICE_CHANGED','The Premium price changed before payment. Refresh the plans and confirm the new price; no money has been deducted.');
            $latestStmt=$this->pdo->prepare("SELECT id,plan_id,started_at,expires_at FROM nu_mobile_premium_subscriptions WHERE account_id=? AND status='active' AND expires_at>UTC_TIMESTAMP() ORDER BY expires_at DESC LIMIT 1 FOR UPDATE");
            $latestStmt->execute([$account]);$latest=$latestStmt->fetch(PDO::FETCH_ASSOC)?:null;
            $isRenewal=$latest!==null;
            if($isRenewal && empty($config['renewals_enabled']))throw new NuCompanionException(409,'RENEWALS_DISABLED','Premium renewals are not open right now. No money has been deducted.');
            if(!$isRenewal && empty($config['new_subscriptions_enabled']))throw new NuCompanionException(409,'SUBSCRIPTIONS_DISABLED','New Premium subscriptions are not open right now. No money has been deducted.');
            $walletStmt=$this->pdo->prepare("SELECT id,balance_minor,status FROM nu_cwallet_accounts WHERE wallet_user_id=? AND currency='NGN' LIMIT 1 FOR UPDATE");
            $walletStmt->execute([$walletUserId]);$wallet=$walletStmt->fetch(PDO::FETCH_ASSOC);
            if(!$wallet||(string)$wallet['status']!=='active')throw new NuCompanionException(409,'WALLET_UNAVAILABLE','Your central wallet is not available for this purchase. No money has been deducted.');
            $before=(int)$wallet['balance_minor'];$amount=(int)$plan['price_minor'];
            if($before<$amount)throw new NuCompanionException(402,'INSUFFICIENT_BALANCE','Your wallet balance is too low for this Premium plan. Fund your wallet, then retry the same purchase.');
            $after=$before-$amount;$orderReference='NUP-'.strtoupper(bin2hex(random_bytes(8)));$ledgerReference='NUL-PR-'.strtoupper(bin2hex(random_bytes(8)));
            $metadata=json_encode(['account_id'=>$account,'plan_id'=>$planId,'regular_price_minor'=>$plan['regular_price_minor'],'promotion_active'=>$plan['promotion_active'],'promotion_name'=>$plan['promotion_name']],JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);
            $orderStmt=$this->pdo->prepare("INSERT INTO nu_cwallet_orders(order_reference,wallet_user_id,wallet_account_id,service_code,product_code,amount_minor,currency,payment_source,status,idempotency_key,metadata_json,created_at,updated_at) VALUES(?,?,?,'mobile_premium',?,?,'NGN','wallet','processing',?,?,UTC_TIMESTAMP(),UTC_TIMESTAMP())");
            $orderStmt->execute([$orderReference,$walletUserId,(int)$wallet['id'],$planId,$amount,$idempotency,$metadata]);
            $orderId=(int)$this->pdo->lastInsertId();
            $ledgerStmt=$this->pdo->prepare("INSERT INTO nu_cwallet_ledger(wallet_account_id,wallet_user_id,ledger_reference,entry_type,amount_minor,currency,balance_before_minor,balance_after_minor,service_code,service_reference,payment_provider,payment_reference,idempotency_key,description,metadata_json,created_at) VALUES(?,?,?,'debit',?,'NGN',?,?,'mobile_premium',?,NULL,NULL,?,'NOUN Update Premium purchase',?,UTC_TIMESTAMP())");
            $ledgerStmt->execute([(int)$wallet['id'],$walletUserId,$ledgerReference,$amount,$before,$after,$orderReference,'premium-order:'.$orderReference,$metadata]);
            $update=$this->pdo->prepare('UPDATE nu_cwallet_accounts SET balance_minor=?,updated_at=UTC_TIMESTAMP() WHERE id=? AND balance_minor=?');
            $update->execute([$after,(int)$wallet['id'],$before]);if($update->rowCount()!==1)throw new RuntimeException('Wallet balance changed concurrently. Premium purchase was rolled back.');
            $now=new DateTimeImmutable('now',new DateTimeZone('UTC'));
            $starts=$latest?new DateTimeImmutable((string)$latest['expires_at'],new DateTimeZone('UTC')):$now;if($starts<$now)$starts=$now;
            $months=max(1,(int)$plan['duration_months']);$expires=$starts->add(new DateInterval('P'.$months.'M'));
            $promotionId=$plan['promotion_active']?($plan['promotion_name']?:$planId.'-promotion'):null;
            $subStmt=$this->pdo->prepare("INSERT INTO nu_mobile_premium_subscriptions(account_id,plan_id,status,started_at,expires_at,regular_price_minor,amount_paid_minor,currency,payment_provider,payment_reference,promotion_id,auto_renew,created_at) VALUES(?,?,'active',?,?,?,?,?,'central_wallet',?,?,0,UTC_TIMESTAMP())");
            $subStmt->execute([$account,$planId,$starts->format('Y-m-d H:i:s'),$expires->format('Y-m-d H:i:s'),(int)$plan['regular_price_minor'],$amount,'NGN',$orderReference,$promotionId]);
            $finish=$this->pdo->prepare("UPDATE nu_cwallet_orders SET status='fulfilled',paid_at=UTC_TIMESTAMP(),fulfilled_at=UTC_TIMESTAMP(),updated_at=UTC_TIMESTAMP() WHERE id=? AND status='processing'");
            $finish->execute([$orderId]);if($finish->rowCount()!==1)throw new RuntimeException('Premium order changed concurrently. Purchase was rolled back.');
            $this->pdo->commit();
            return ['duplicate'=>false,'order_reference'=>$orderReference,'plan_id'=>$planId,'amount_minor'=>$amount,'currency'=>'NGN',
                'started_at'=>$starts->format('Y-m-d\\TH:i:s\\Z'),'expires_at'=>$expires->format('Y-m-d\\TH:i:s\\Z'),'wallet_balance_minor'=>$after];
        } catch(Throwable $e) {
            if($this->pdo->inTransaction())$this->pdo->rollBack();throw $e;
        }
    }
    public function preferences(int $account): array {
        $p=$this->rows('SELECT * FROM nu_mobile_preferences WHERE account_id=?',[$account])[0]??[];
        return ['preferred_skin'=>$p['preferred_skin']??'defaultNoun','birthday'=>[
            'month'=>isset($p['birthday_month'])?(int)$p['birthday_month']:null,'day'=>isset($p['birthday_day'])?(int)$p['birthday_day']:null,
            'celebration_enabled'=>(bool)($p['birthday_celebration_enabled']??true)]];
    }
    public function savePreferences(int $account,array $body): array {
        // Validate the entire patch before any write. Account ID comes only from auth.
        $updates=[];$values=[];
        if(array_key_exists('preferred_skin',$body)){
            $skin=$body['preferred_skin'];
            if(!is_string($skin)||!in_array($skin,self::SKINS,true))throw new InvalidArgumentException('Choose a valid skin.');
            $e=$this->entitlement($account);
            if($skin!=='defaultNoun' && (!$e['active'] || empty($e['features']['premium_skins'])))throw new InvalidArgumentException('Active Premium access is required to apply this skin.');
            $updates[]='preferred_skin=?';$values[]=$skin;
        }
        if(array_key_exists('birthday',$body)){
            $b=$body['birthday'];
            if(!is_array($b))throw new InvalidArgumentException('Send a valid birthday.');
            $m=$b['month']??null;$d=$b['day']??null;$enabled=$b['celebration_enabled']??true;
            if(!is_bool($enabled)||(($m!==null||$d!==null)&&(!is_int($m)||!is_int($d)||!checkdate($m,$d,2000))))throw new InvalidArgumentException('Choose a valid month and day.');
            array_push($updates,'birthday_month=?','birthday_day=?','birthday_celebration_enabled=?');array_push($values,$m,$d,(int)$enabled);
        }
        if($updates){
            $this->pdo->prepare('INSERT IGNORE INTO nu_mobile_preferences(account_id) VALUES(?)')->execute([$account]);
            $this->pdo->prepare('UPDATE nu_mobile_preferences SET '.implode(',',$updates).' WHERE account_id=?')->execute([...$values,$account]);
        }
        return $this->preferences($account);
    }
    private function websiteQuote(): ?int {
        $path=$this->websiteQuoteFile??dirname(__DIR__,2).'/power-space/quote.json';
        if(!is_file($path)||!is_readable($path)||filesize($path)>16384)return null;
        $data=json_decode(file_get_contents($path)?:'',true);
        if(!is_array($data)||!is_string($data['text']??null)||!is_string($data['author']??null))return null;
        $text=trim($data['text']);$author=trim($data['author'])?:'NOUN Update';
        if($text===''||mb_strlen($text)>2000||mb_strlen($author)>150)return null;
        $hash=hash('sha256',$text.'|'.$author);
        $this->pdo->prepare('INSERT IGNORE INTO nu_mobile_motivation(source_hash,quote,author) VALUES(?,?,?)')->execute([$hash,$text,$author]);
        $row=$this->rows('SELECT id FROM nu_mobile_motivation WHERE source_hash=? AND active=1',[$hash])[0]??null;
        return $row?(int)$row['id']:null;
    }
    public function dailyQuote(): ?array {
        $date=(new DateTimeImmutable('now',new DateTimeZone('Africa/Lagos')))->format('Y-m-d');
        $eligible="active=1 AND (schedule_date IS NULL OR schedule_date=?) AND (starts_at IS NULL OR starts_at<=UTC_TIMESTAMP()) AND (ends_at IS NULL OR ends_at>UTC_TIMESTAMP())";
        $id=$this->rows('SELECT quote_id FROM nu_mobile_daily_motivation WHERE quote_date=?',[$date])[0]['quote_id']??null;
        if($id){$q=$this->rows("SELECT id,quote,author,category FROM nu_mobile_motivation WHERE id=? AND $eligible",[$id,$date])[0]??null;if($q)return $q+['date'=>$date];}
        $websiteId=$this->websiteQuote();
        $q=$this->rows("SELECT id,quote,author,category FROM nu_mobile_motivation WHERE $eligible ORDER BY (schedule_date IS NOT NULL) DESC,featured DESC,(id=?) DESC,SHA2(CONCAT(id,?),256) LIMIT 1",[$date,$websiteId??0,$date])[0]??null;
        if(!$q)return null;
        $this->pdo->prepare('INSERT INTO nu_mobile_daily_motivation(quote_date,quote_id) VALUES(?,?) ON DUPLICATE KEY UPDATE quote_id=VALUES(quote_id)')->execute([$date,$q['id']]);
        return $q+['date'=>$date];
    }
    public function savedQuotes(int $account): array {
        return $this->rows('SELECT q.id,q.quote,q.author,q.category FROM nu_mobile_saved_motivation s JOIN nu_mobile_motivation q ON q.id=s.quote_id WHERE s.account_id=? AND q.active=1 ORDER BY s.created_at DESC LIMIT 200',[$account]);
    }
    public function saveQuote(int $account,int $id,bool $saved): void {
        if($id<1)throw new InvalidArgumentException('Choose a valid quote.');
        if($saved)$this->pdo->prepare('INSERT IGNORE INTO nu_mobile_saved_motivation(account_id,quote_id) SELECT ?,id FROM nu_mobile_motivation WHERE id=? AND active=1')->execute([$account,$id]);
        else $this->pdo->prepare('DELETE FROM nu_mobile_saved_motivation WHERE account_id=? AND quote_id=?')->execute([$account,$id]);
    }
}
