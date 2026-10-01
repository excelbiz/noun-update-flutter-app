<?php
declare(strict_types=1);

/** Read-only Premium analytics over the existing Mock and POP attempt stores. */
final class NuPremiumAnalytics {
    public function __construct(private PDO $sitePdo, private ?PDO $mockPdo = null) {}

    public static function mockPdoFromEnvironment(): ?PDO {
        $dsn=trim((string)(getenv('NU_MOCK_DB_DSN')?:''));
        $user=(string)(getenv('NU_MOCK_DB_USER')?:'');
        $pass=(string)(getenv('NU_MOCK_DB_PASSWORD')?:'');
        if($dsn==='')return null;
        try{
            return new PDO($dsn,$user,$pass,[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC,PDO::ATTR_EMULATE_PREPARES=>false,PDO::ATTR_STRINGIFY_FETCHES=>false]);
        }catch(Throwable $e){
            error_log('[MOBILE ANALYTICS] Mock analytics database unavailable: '.$e->getMessage());
            return null;
        }
    }

    private function tableExists(PDO $pdo,string $table): bool {
        if(!preg_match('/^[A-Za-z0-9_]+$/D',$table))return false;
        try{$s=$pdo->prepare('SHOW TABLES LIKE ?');$s->execute([$table]);return (bool)$s->fetchColumn();}catch(Throwable){return false;}
    }

    private function emptyResult(string $source,bool $available,bool $linked=true): array {
        return ['source'=>$source,'source_available'=>$available,'account_linked'=>$linked,'has_data'=>false,
            'summary'=>['attempts'=>0,'courses'=>0,'average_percentage'=>null,'best_percentage'=>null],
            'courses'=>[],'trend'=>[],'recent'=>[],'generated_at'=>gmdate('c')];
    }

    private function pct(float|int $score,float|int $total): float {
        if((float)$total<=0)return 0.0;
        return round(max(0,min(100,((float)$score/(float)$total)*100)),1);
    }

    public function mock(string $email): array {
        $db=$this->mockPdo;
        if(!$db||!$this->tableExists($db,'mock_users')||!$this->tableExists($db,'attempts')||!$this->tableExists($db,'courses'))return $this->emptyResult('mock',false);
        $user=$db->prepare('SELECT id FROM mock_users WHERE LOWER(email)=LOWER(?) ORDER BY id ASC LIMIT 1');$user->execute([$email]);$userId=(int)$user->fetchColumn();
        if($userId<1)return $this->emptyResult('mock',true,false);
        $q=$db->prepare('SELECT a.id,a.score,a.time_taken,a.attempt_date,c.name AS course_code,c.title AS course_title,c.question_count FROM attempts a JOIN courses c ON c.id=a.course_id WHERE a.user_id=? ORDER BY a.attempt_date DESC,a.id DESC LIMIT 500');
        $q->execute([$userId]);$rows=$q->fetchAll(PDO::FETCH_ASSOC);
        if(!$rows)return $this->emptyResult('mock',true,true);
        $sum=0.0;$best=0.0;$totalTime=0;$course=[];$trend=[];$recent=[];
        foreach($rows as $i=>$row){
            $questions=max(0,(int)$row['question_count']);$percentage=$this->pct((float)$row['score'],$questions);$seconds=max(0,(int)$row['time_taken']);
            $sum+=$percentage;$best=max($best,$percentage);$totalTime+=$seconds;$code=strtoupper(trim((string)$row['course_code']))?:'COURSE';
            if(!isset($course[$code]))$course[$code]=['course_code'=>$code,'course_title'=>(string)$row['course_title'],'attempts'=>0,'sum'=>0.0,'best_percentage'=>0.0,'total_time_seconds'=>0,'questions'=>0,'last_attempt_at'=>(string)$row['attempt_date']];
            $course[$code]['attempts']++;$course[$code]['sum']+=$percentage;$course[$code]['best_percentage']=max($course[$code]['best_percentage'],$percentage);$course[$code]['total_time_seconds']+=$seconds;$course[$code]['questions']+=$questions;
            $point=['attempt_id'=>(int)$row['id'],'course_code'=>$code,'course_title'=>(string)$row['course_title'],'percentage'=>$percentage,'score'=>(int)$row['score'],'question_count'=>$questions,'time_seconds'=>$seconds,'attempted_at'=>(string)$row['attempt_date']];
            if($i<12)$recent[]=$point;if($i<20)$trend[]=['course_code'=>$code,'percentage'=>$percentage,'attempted_at'=>(string)$row['attempt_date']];
        }
        $courses=[];foreach($course as $c){$attempts=max(1,(int)$c['attempts']);$questions=max(0,(int)$c['questions']);$time=max(0,(int)$c['total_time_seconds']);$courses[]=[
            'course_code'=>$c['course_code'],'course_title'=>$c['course_title'],'attempts'=>$attempts,'average_percentage'=>round($c['sum']/$attempts,1),'best_percentage'=>round($c['best_percentage'],1),
            'total_time_seconds'=>$time,'average_time_seconds'=>(int)round($time/$attempts),'seconds_per_question'=>$questions>0?round($time/$questions,1):null,'last_attempt_at'=>$c['last_attempt_at']];}
        usort($courses,static fn($a,$b)=>($a['average_percentage']<=>$b['average_percentage'])?:strcmp($a['course_code'],$b['course_code']));
        $count=count($rows);$totalQuestions=array_sum(array_map(static fn($r)=>max(0,(int)$r['question_count']),$rows));
        return ['source'=>'mock','source_available'=>true,'account_linked'=>true,'has_data'=>true,'summary'=>[
            'attempts'=>$count,'courses'=>count($course),'average_percentage'=>round($sum/$count,1),'best_percentage'=>round($best,1),'total_time_seconds'=>$totalTime,
            'average_time_seconds'=>(int)round($totalTime/$count),'seconds_per_question'=>$totalQuestions>0?round($totalTime/$totalQuestions,1):null],
            'courses'=>$courses,'trend'=>array_reverse($trend),'recent'=>$recent,'generated_at'=>gmdate('c')];
    }

    public function pop(string $email): array {
        if(!$this->tableExists($this->sitePdo,'user_exam_history'))return $this->emptyResult('pop',false);
        $q=$this->sitePdo->prepare('SELECT id,course_code,score,total_marks,difficulty,exam_details,exam_date FROM user_exam_history WHERE LOWER(user_email)=LOWER(?) ORDER BY exam_date DESC,id DESC LIMIT 500');
        $q->execute([$email]);$rows=$q->fetchAll(PDO::FETCH_ASSOC);if(!$rows)return $this->emptyResult('pop',true,true);
        $sum=0.0;$best=0.0;$course=[];$difficulty=[];$trend=[];$recent=[];$answered=0;$answerSlots=0;
        foreach($rows as $i=>$row){
            $percentage=$this->pct((float)$row['score'],(float)$row['total_marks']);$sum+=$percentage;$best=max($best,$percentage);$code=strtoupper(trim((string)$row['course_code']))?:'COURSE';$level=strtolower(trim((string)$row['difficulty']))?:'unknown';
            if(!isset($course[$code]))$course[$code]=['course_code'=>$code,'attempts'=>0,'sum'=>0.0,'best_percentage'=>0.0,'last_attempt_at'=>(string)$row['exam_date']];
            $course[$code]['attempts']++;$course[$code]['sum']+=$percentage;$course[$code]['best_percentage']=max($course[$code]['best_percentage'],$percentage);
            if(!isset($difficulty[$level]))$difficulty[$level]=['difficulty'=>$level,'attempts'=>0,'sum'=>0.0,'best_percentage'=>0.0];$difficulty[$level]['attempts']++;$difficulty[$level]['sum']+=$percentage;$difficulty[$level]['best_percentage']=max($difficulty[$level]['best_percentage'],$percentage);
            $details=json_decode((string)($row['exam_details']??''),true);if(is_array($details)){
                $answers=$details['userAnswers']??[];$questions=$details['questions']??[];
                if(is_array($answers)&&is_array($questions)){
                    foreach($questions as $index=>$question){$ua=$answers[$index]??null;if(!is_array($ua)){foreach($answers as $candidate){if(is_array($candidate)&&($candidate['id']??null)==='q-'.$index){$ua=$candidate;break;}}}
                        $counted=!is_array($ua)||!array_key_exists('counted',$ua)||$ua['counted']!==false;if(!$counted)continue;$answerSlots++;if(is_array($ua)&&trim((string)($ua['answer']??''))!=='')$answered++;}
                }
            }
            $point=['attempt_id'=>(int)$row['id'],'course_code'=>$code,'percentage'=>$percentage,'score'=>(int)$row['score'],'total_marks'=>(int)$row['total_marks'],'difficulty'=>$level,'attempted_at'=>(string)$row['exam_date']];
            if($i<12)$recent[]=$point;if($i<20)$trend[]=['course_code'=>$code,'percentage'=>$percentage,'difficulty'=>$level,'attempted_at'=>(string)$row['exam_date']];
        }
        $courses=[];foreach($course as $c){$n=max(1,(int)$c['attempts']);$courses[]=['course_code'=>$c['course_code'],'attempts'=>$n,'average_percentage'=>round($c['sum']/$n,1),'best_percentage'=>round($c['best_percentage'],1),'last_attempt_at'=>$c['last_attempt_at']];}
        usort($courses,static fn($a,$b)=>($a['average_percentage']<=>$b['average_percentage'])?:strcmp($a['course_code'],$b['course_code']));
        $levels=[];foreach($difficulty as $d){$n=max(1,(int)$d['attempts']);$levels[]=['difficulty'=>$d['difficulty'],'attempts'=>$n,'average_percentage'=>round($d['sum']/$n,1),'best_percentage'=>round($d['best_percentage'],1)];}
        usort($levels,static fn($a,$b)=>strcmp($a['difficulty'],$b['difficulty']));$count=count($rows);
        return ['source'=>'pop','source_available'=>true,'account_linked'=>true,'has_data'=>true,'summary'=>[
            'attempts'=>$count,'courses'=>count($course),'average_percentage'=>round($sum/$count,1),'best_percentage'=>round($best,1),'answer_coverage_percentage'=>$answerSlots>0?round(($answered/$answerSlots)*100,1):null],
            'courses'=>$courses,'difficulty'=>$levels,'trend'=>array_reverse($trend),'recent'=>$recent,'generated_at'=>gmdate('c')];
    }
}
