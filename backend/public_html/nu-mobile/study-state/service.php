<?php
declare(strict_types=1);

final class NuStudyState {
    public function __construct(private PDO $pdo) {}

    private function course(string $courseCode): string {
        $code=strtoupper(str_replace(' ','',trim($courseCode)));
        if(!preg_match('/^[A-Z]{2,5}[0-9]{3}$/D',$code))throw new InvalidArgumentException('Choose a valid course code.');
        return $code;
    }

    public function get(int $accountId,string $courseCode): array {
        if($accountId<1)throw new InvalidArgumentException('Choose a valid account.');
        $code=$this->course($courseCode);
        $stmt=$this->pdo->prepare('SELECT state_json,revision,updated_at FROM nu_mobile_study_state WHERE account_id=? AND course_code=? LIMIT 1');
        $stmt->execute([$accountId,$code]);
        $row=$stmt->fetch(PDO::FETCH_ASSOC);
        if(!$row)return ['done'=>[],'notes'=>'','revision'=>0,'updated_at'=>null];
        $state=json_decode((string)$row['state_json'],true);
        if(!is_array($state))$state=[];
        return [
            'done'=>array_values(array_map('intval',is_array($state['done']??null)?$state['done']:[])),
            'notes'=>is_string($state['notes']??null)?$state['notes']:'',
            'revision'=>(int)$row['revision'],
            'updated_at'=>str_replace(' ','T',(string)$row['updated_at']).'Z',
        ];
    }

    public function save(int $accountId,string $courseCode,array $body): array {
        if($accountId<1)throw new InvalidArgumentException('Choose a valid account.');
        $code=$this->course($courseCode);
        $done=$body['done']??[];$notes=$body['notes']??'';
        $baseRevision=$body['base_revision']??null;
        if(!is_array($done)||!is_string($notes))throw new InvalidArgumentException('Send valid study progress.');
        if($baseRevision!==null&&(!is_int($baseRevision)||$baseRevision<0))throw new InvalidArgumentException('Send a valid study-state revision.');
        if(mb_strlen($notes)>20000)throw new InvalidArgumentException('Study notes are too long. Keep them below 20,000 characters.');
        if(count($done)>500)throw new InvalidArgumentException('Study progress contains too many completed units.');
        $clean=[];
        foreach($done as $value){
            if(!is_int($value)&&!(is_string($value)&&ctype_digit($value)))throw new InvalidArgumentException('Completed units must use valid indexes.');
            $index=(int)$value;
            if($index<0||$index>499)throw new InvalidArgumentException('Completed unit index is outside the supported range.');
            $clean[$index]=true;
        }
        $done=array_keys($clean);sort($done,SORT_NUMERIC);
        $state=json_encode(['done'=>$done,'notes'=>$notes],JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES|JSON_THROW_ON_ERROR);
        $this->pdo->beginTransaction();
        try{
            $stmt=$this->pdo->prepare('SELECT revision FROM nu_mobile_study_state WHERE account_id=? AND course_code=? LIMIT 1 FOR UPDATE');
            $stmt->execute([$accountId,$code]);
            $current=$stmt->fetchColumn();
            $currentRevision=$current===false?0:(int)$current;
            if($baseRevision!==null&&$baseRevision!==$currentRevision)throw new RuntimeException('STUDY_STATE_CONFLICT');
            $revision=$currentRevision+1;
            if($current===false){
                $insert=$this->pdo->prepare('INSERT INTO nu_mobile_study_state(account_id,course_code,state_json,revision,updated_at) VALUES(?,?,?,?,UTC_TIMESTAMP())');
                $insert->execute([$accountId,$code,$state,$revision]);
            }else{
                $update=$this->pdo->prepare('UPDATE nu_mobile_study_state SET state_json=?,revision=?,updated_at=UTC_TIMESTAMP() WHERE account_id=? AND course_code=?');
                $update->execute([$state,$revision,$accountId,$code]);
            }
            $this->pdo->commit();
        }catch(Throwable $e){if($this->pdo->inTransaction())$this->pdo->rollBack();throw $e;}
        return $this->get($accountId,$code);
    }
}
