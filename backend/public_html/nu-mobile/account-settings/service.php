<?php
declare(strict_types=1);

final class NuAccountSettings {
    private const MODES=['system','light','dark'];
    private const TEXT_SIZES=['Small','Default','Large','Extra Large'];
    private const FONTS=['Modern sans','Classic serif','Device font'];
    private const ACCENTS=['Emerald','Ocean','Plum','Terracotta'];
    private const BOOLEAN_KEYS=['automatic','data_saver','notifications_enabled','notify_tmas','notify_exams','notify_results','notify_fees','notify_general'];

    public function __construct(private PDO $pdo) {}

    private function defaults(): array {
        return [
            'automatic'=>true,
            'mode'=>'system',
            'text_size'=>'Default',
            'font'=>'Modern sans',
            'accent'=>'Emerald',
            'data_saver'=>false,
            'notifications_enabled'=>true,
            'notify_tmas'=>true,
            'notify_exams'=>true,
            'notify_results'=>true,
            'notify_fees'=>true,
            'notify_general'=>true,
        ];
    }

    public function get(int $accountId): array {
        if($accountId<1)throw new InvalidArgumentException('Choose a valid account.');
        $stmt=$this->pdo->prepare('SELECT settings_json,updated_at FROM nu_mobile_account_settings WHERE account_id=? LIMIT 1');
        $stmt->execute([$accountId]);
        $row=$stmt->fetch(PDO::FETCH_ASSOC);
        if(!$row)return ['exists'=>false,'settings'=>$this->defaults(),'updated_at'=>null];
        $stored=json_decode((string)$row['settings_json'],true);
        if(!is_array($stored))$stored=[];
        return [
            'exists'=>true,
            'settings'=>array_replace($this->defaults(),$stored),
            'updated_at'=>str_replace(' ','T',(string)$row['updated_at']).'Z',
        ];
    }

    public function save(int $accountId,array $body): array {
        if($accountId<1)throw new InvalidArgumentException('Choose a valid account.');
        $input=$body['settings']??$body;
        if(!is_array($input))throw new InvalidArgumentException('Send valid account settings.');
        $current=$this->get($accountId)['settings'];
        $next=array_replace($current,$input);
        foreach(self::BOOLEAN_KEYS as $key){
            if(!is_bool($next[$key]??null))throw new InvalidArgumentException('Choose a valid '.str_replace('_',' ',$key).' setting.');
        }
        if(!is_string($next['mode']??null)||!in_array($next['mode'],self::MODES,true))throw new InvalidArgumentException('Choose a valid display mode.');
        if(!is_string($next['text_size']??null)||!in_array($next['text_size'],self::TEXT_SIZES,true))throw new InvalidArgumentException('Choose a valid text size.');
        if(!is_string($next['font']??null)||!in_array($next['font'],self::FONTS,true))throw new InvalidArgumentException('Choose a valid reading font.');
        if(!is_string($next['accent']??null)||!in_array($next['accent'],self::ACCENTS,true))throw new InvalidArgumentException('Choose a valid accent colour.');
        $clean=[
            'automatic'=>$next['automatic'],
            'mode'=>$next['mode'],
            'text_size'=>$next['text_size'],
            'font'=>$next['font'],
            'accent'=>$next['accent'],
            'data_saver'=>$next['data_saver'],
            'notifications_enabled'=>$next['notifications_enabled'],
            'notify_tmas'=>$next['notify_tmas'],
            'notify_exams'=>$next['notify_exams'],
            'notify_results'=>$next['notify_results'],
            'notify_fees'=>$next['notify_fees'],
            'notify_general'=>$next['notify_general'],
        ];
        $json=json_encode($clean,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR);
        $stmt=$this->pdo->prepare('INSERT INTO nu_mobile_account_settings(account_id,settings_json,updated_at) VALUES(?,?,UTC_TIMESTAMP()) ON DUPLICATE KEY UPDATE settings_json=VALUES(settings_json),updated_at=UTC_TIMESTAMP()');
        $stmt->execute([$accountId,$json]);
        return $this->get($accountId);
    }
}
