<?php
declare(strict_types=1);

final class NuSavedResources {
    public function __construct(private PDO $pdo) {}

    public function all(int $accountId): array {
        if ($accountId < 1) throw new InvalidArgumentException('A valid account is required.');
        $stmt=$this->pdo->prepare(
            'SELECT resource_key,resource_type,title,course_code,route,saved_at '
            .'FROM nu_mobile_saved_resources WHERE account_id=? ORDER BY saved_at DESC,resource_key ASC LIMIT 500'
        );
        $stmt->execute([$accountId]);
        $items=[];
        foreach($stmt->fetchAll(PDO::FETCH_ASSOC) as $row){
            $items[]=[
                'resource_key'=>(string)$row['resource_key'],
                'resource_type'=>(string)$row['resource_type'],
                'title'=>(string)$row['title'],
                'course_code'=>$row['course_code']!==null?(string)$row['course_code']:null,
                'route'=>$row['route']!==null?(string)$row['route']:null,
                'saved_at'=>str_replace(' ','T',(string)$row['saved_at']).'Z',
            ];
        }
        return ['account_id'=>(string)$accountId,'items'=>$items];
    }

    public function save(int $accountId,array $body): array {
        if ($accountId < 1) throw new InvalidArgumentException('A valid account is required.');
        // Optional for old clients; new clients bind every queued write to its owner.
        if(isset($body['account_id']) && $body['account_id']!==(string)$accountId)
            throw new InvalidArgumentException('The signed-in account changed. Reopen saved resources.');
        $key=$body['resource_key']??null;
        $saved=$body['saved']??null;
        if(!is_string($key)||!preg_match('/^[A-Za-z0-9._:\/-]{1,191}$/D',$key))
            throw new InvalidArgumentException('Choose a valid saved resource.');
        if(!is_bool($saved))throw new InvalidArgumentException('Choose whether this resource is saved.');
        if(!$saved){
            $stmt=$this->pdo->prepare('DELETE FROM nu_mobile_saved_resources WHERE account_id=? AND resource_key=?');
            $stmt->execute([$accountId,$key]);
            return ['account_id'=>(string)$accountId,'saved'=>false,'resource_key'=>$key];
        }

        $type=$body['resource_type']??null;
        $title=$body['title']??null;
        $course=$body['course_code']??null;
        $route=$body['route']??null;
        if(!is_string($type)||!preg_match('/^[a-z0-9_-]{1,40}$/D',$type))
            throw new InvalidArgumentException('Choose a valid resource type.');
        if(!is_string($title)||trim($title)===''||mb_strlen($title)>200)
            throw new InvalidArgumentException('Choose a valid resource title.');
        $title=trim($title);
        if($course!==null){
            if(!is_string($course))throw new InvalidArgumentException('Choose a valid course code.');
            $course=strtoupper(str_replace(' ','',trim($course)));
            if($course==='' )$course=null;
            elseif(!preg_match('/^[A-Z]{2,5}[0-9]{3}$/D',$course))throw new InvalidArgumentException('Choose a valid course code.');
        }
        if($route!==null){
            if(!is_string($route))throw new InvalidArgumentException('Choose a valid resource route.');
            $route=trim($route);
            if($route==='')$route=null;
            elseif(strlen($route)>255||$route[0]!=='/'||str_contains($route,'://'))throw new InvalidArgumentException('Choose a valid app resource route.');
        }

        $exists=$this->pdo->prepare('SELECT 1 FROM nu_mobile_saved_resources WHERE account_id=? AND resource_key=?');
        $exists->execute([$accountId,$key]);
        if(!$exists->fetchColumn()){
            $count=$this->pdo->prepare('SELECT COUNT(*) FROM nu_mobile_saved_resources WHERE account_id=?');
            $count->execute([$accountId]);
            if((int)$count->fetchColumn()>=500)throw new InvalidArgumentException('You can save up to 500 resources. Remove an older bookmark before adding another.');
        }

        $stmt=$this->pdo->prepare(
            'INSERT INTO nu_mobile_saved_resources(account_id,resource_key,resource_type,title,course_code,route,saved_at) '
            .'VALUES(?,?,?,?,?,?,UTC_TIMESTAMP()) ON DUPLICATE KEY UPDATE resource_type=VALUES(resource_type),title=VALUES(title),course_code=VALUES(course_code),route=VALUES(route),saved_at=UTC_TIMESTAMP()'
        );
        $stmt->execute([$accountId,$key,$type,$title,$course,$route]);
        return [
            'account_id'=>(string)$accountId,'saved'=>true,'resource_key'=>$key,'resource_type'=>$type,'title'=>$title,
            'course_code'=>$course,'route'=>$route,'saved_at'=>gmdate('c'),
        ];
    }
}
