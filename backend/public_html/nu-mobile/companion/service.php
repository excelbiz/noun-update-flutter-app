<?php
declare(strict_types=1);
/** Additive read/configuration service. Never credits a wallet or trusts client payment claims. */
final class NuCompanion {
    public const SKINS = ['defaultNoun','smartCampus','premiumDark','glassmorphism','studentFriendly','minimalAcademic','elegantEditorial','productivityDashboard','friendlyModern','futureTech','boldPremium'];
    public function __construct(private PDO $pdo, private ?string $websiteQuoteFile=null) {}
    private function rows(string $sql,array $args=[]): array {
        $s=$this->pdo->prepare($sql);$s->execute($args);return $s->fetchAll(PDO::FETCH_ASSOC);
    }
    public function configuration(): array {
        $c=$this->rows('SELECT * FROM nu_mobile_configuration WHERE id=1')[0]??[];
        $features=json_decode($c['features_json']??'{}',true)?:[];
        $plans=$this->rows('SELECT * FROM nu_mobile_premium_plans WHERE enabled=1 ORDER BY sort_order,id');
        $now=gmdate('Y-m-d H:i:s');
        foreach($plans as &$p){
            $promo=(bool)$p['promo_enabled'] && $p['promo_starts_at']!==null && $p['promo_ends_at']!==null && $p['promo_starts_at']<=$now && $p['promo_ends_at']>$now && $p['promo_price_minor']!==null && (int)$p['promo_price_minor']<(int)$p['regular_price_minor'];
            $p=['id'=>$p['id'],'name'=>$p['name'],'currency'=>$p['currency'],'regular_price_minor'=>(int)$p['regular_price_minor'],
                'price_minor'=>(int)($promo?$p['promo_price_minor']:$p['regular_price_minor']),'promotion_active'=>$promo,
                'promotion_text'=>$promo?$p['promo_text']:null,'billing_period'=>$p['billing_period'],'duration_months'=>(int)$p['duration_months'],'badge'=>$p['badge']];
        }
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
