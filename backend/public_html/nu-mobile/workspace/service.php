<?php
declare(strict_types=1);

final class NuStudentWorkspace {
    private const DETAIL_KEYS = ['Name','Programme','Faculty','Level','Study centre','Session','Semester'];

    public function __construct(private PDO $pdo) {}

    private function normaliseDetails(mixed $value): array {
        if (!is_array($value)) return [];
        $out=[];
        foreach (self::DETAIL_KEYS as $key) {
            if (!array_key_exists($key,$value)) continue;
            $text=trim((string)$value[$key]);
            if (mb_strlen($text)>120) throw new InvalidArgumentException('Student detail values must be 120 characters or fewer.');
            $out[$key]=$text;
        }
        return $out;
    }

    private function normaliseCourses(mixed $value): array {
        if (!is_array($value)) return [];
        $out=[];
        foreach ($value as $raw) {
            if (!is_string($raw)) throw new InvalidArgumentException('Send a valid course list.');
            $course=strtoupper(str_replace(' ','',trim($raw)));
            if (!preg_match('/^[A-Z]{2,5}[0-9]{3}$/D',$course)) throw new InvalidArgumentException('One of the course codes is invalid.');
            $out[$course]=true;
            if (count($out)>60) throw new InvalidArgumentException('A maximum of 60 courses can be saved.');
        }
        return array_keys($out);
    }

    private function normalisePins(mixed $value): array {
        if (!is_array($value)) return [];
        $out=[];
        foreach ($value as $raw) {
            if (!is_string($raw)) throw new InvalidArgumentException('Send a valid pinned-tool list.');
            $id=trim($raw);
            if (!preg_match('/^[a-z0-9][a-z0-9_-]{0,79}$/D',$id)) throw new InvalidArgumentException('One of the pinned tools is invalid.');
            $out[$id]=true;
            if (count($out)>50) throw new InvalidArgumentException('Too many pinned tools were supplied.');
        }
        return array_keys($out);
    }

    private function decoded(?string $json): array {
        if ($json===null || $json==='') return [];
        $value=json_decode($json,true);
        return is_array($value)?$value:[];
    }

    public function get(int $accountId): array {
        $stmt=$this->pdo->prepare('SELECT details_json,courses_json,pins_json,revision,updated_at FROM nu_mobile_student_workspaces WHERE account_id=? LIMIT 1');
        $stmt->execute([$accountId]);
        $row=$stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row) return ['account_id'=>(string)$accountId,'exists'=>false,'details'=>(object)[],'courses'=>[],'pins'=>[],'revision'=>0,'updated_at'=>null];
        return [
            'account_id'=>(string)$accountId,'exists'=>true,
            'details'=>(object)$this->decoded($row['details_json']??null),
            'courses'=>$this->decoded($row['courses_json']??null),
            'pins'=>$this->decoded($row['pins_json']??null),
            'revision'=>(int)$row['revision'],
            'updated_at'=>isset($row['updated_at'])?str_replace(' ','T',$row['updated_at']).'Z':null,
        ];
    }

    public function save(int $accountId,array $body): array {
        if(isset($body['account_id']) && $body['account_id']!==(string)$accountId)throw new InvalidArgumentException('The signed-in account changed. Reopen your workspace.');
        $details=$this->normaliseDetails($body['details']??[]);
        $courses=$this->normaliseCourses($body['courses']??[]);
        $pins=$this->normalisePins($body['pins']??[]);
        $base=$body['base_revision']??null;
        if (!is_int($base) || $base<0) throw new InvalidArgumentException('Send a valid workspace revision.');
        $detailsJson=json_encode($details,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR);
        $coursesJson=json_encode($courses,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR);
        $pinsJson=json_encode($pins,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR);
        try {
            $this->pdo->beginTransaction();
            $stmt=$this->pdo->prepare('SELECT revision FROM nu_mobile_student_workspaces WHERE account_id=? LIMIT 1 FOR UPDATE');
            $stmt->execute([$accountId]);
            $current=$stmt->fetchColumn();
            if ($current===false) {
                if ($base!==0) throw new RuntimeException('WORKSPACE_CONFLICT');
                $insert=$this->pdo->prepare('INSERT INTO nu_mobile_student_workspaces(account_id,details_json,courses_json,pins_json,revision,updated_at) VALUES(?,?,?,?,1,UTC_TIMESTAMP())');
                $insert->execute([$accountId,$detailsJson,$coursesJson,$pinsJson]);
            } else {
                if ((int)$current!==$base) throw new RuntimeException('WORKSPACE_CONFLICT');
                $update=$this->pdo->prepare('UPDATE nu_mobile_student_workspaces SET details_json=?,courses_json=?,pins_json=?,revision=revision+1,updated_at=UTC_TIMESTAMP() WHERE account_id=? AND revision=?');
                $update->execute([$detailsJson,$coursesJson,$pinsJson,$accountId,$base]);
                if ($update->rowCount()!==1) throw new RuntimeException('WORKSPACE_CONFLICT');
            }
            $this->pdo->commit();
            return $this->get($accountId);
        } catch (Throwable $e) {
            if ($this->pdo->inTransaction()) $this->pdo->rollBack();
            throw $e;
        }
    }
}
