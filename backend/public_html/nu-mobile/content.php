<?php
declare(strict_types=1);

function nu_services(array $config): array {
    $items=json_decode((string)file_get_contents(__DIR__.'/services.json'),true,512,JSON_THROW_ON_ERROR);
    foreach($items as &$item)$item['url']=$config['site_url'].$item['path'];
    return $items;
}
function nu_content_map(): array {
    return [
        'news'=>['table'=>'news_upload','images'=>'/latestnews_images/','url'=>'/news/','id'=>'id'],
        'guides'=>['table'=>'guides_upload','images'=>'','url'=>'/guides/','id'=>'id'],
        'scholarships'=>['table'=>'scholarship_upload','images'=>'/scholarship_images/','url'=>'/scholarships?b=','id'=>'ref_id'],
        'career'=>['table'=>'career_posts','images'=>'/career_upload/','url'=>'/career-hub?b=','id'=>'ref_id'],
        'blog'=>['table'=>'blog_upload','images'=>'/blog_images/','url'=>'/blog?b=','id'=>'ref_id'],
    ];
}
function nu_text(string $html): string {
    $html=preg_replace('#<(script|style)\b[^>]*>.*?</\1>#is','',$html)??'';
    $html=preg_replace('#</(?:p|div|h[1-6]|li)>|<br\s*/?>#i',"\n\n",$html)??'';
    return trim(html_entity_decode(strip_tags($html),ENT_QUOTES|ENT_HTML5,'UTF-8'));
}
function nu_posts(PDO $db,array $config,string $category,int $page=1,?int $id=null): array {
    $map=nu_content_map();
    if(!isset($map[$category]))throw new NuFailure(404,'NOT_FOUND','Content category not found.');
    $m=$map[$category]; $table=$m['table'];
    $columns=$db->query('SHOW COLUMNS FROM `'.$table.'`')->fetchAll(PDO::FETCH_COLUMN);
    $where=['1=1'];$args=[];
    // Legacy Power Space inserts publish immediately. If a publication control
    // exists, honour it; NEVER expose a draft merely because it has a row ID.
    if(in_array('status',$columns,true))$where[]="LOWER(status) IN ('published','publish','active','1')";
    if(in_array('is_published',$columns,true))$where[]='is_published=1';
    if(in_array('published_at',$columns,true))$where[]='published_at IS NOT NULL AND published_at<=NOW()';
    if(in_array('deleted_at',$columns,true))$where[]='deleted_at IS NULL';
    if($id!==null){$where[]='id=?';$args[]=$id;}
    $page=max(1,min(10000,$page));$limit=$id===null?21:1;$offset=$id===null?($page-1)*20:0;
    $s=$db->prepare('SELECT * FROM `'.$table.'` WHERE '.implode(' AND ',$where).' ORDER BY id DESC LIMIT '.$limit.' OFFSET '.$offset);
    $s->execute($args);$rows=$s->fetchAll();$more=count($rows)>20;$items=[];
    foreach(array_slice($rows,0,20) as $r){
        $text=nu_text((string)($r['message']??''));$image=null;
        if($m['images']!==''&&!empty($r['imagepath']))$image=$config['site_url'].$m['images'].rawurlencode(basename($r['imagepath']));
        $items[]=['id'=>(int)$r['id'],'category'=>$category,'title'=>nu_text((string)$r['title']),
            'excerpt'=>mb_substr($text,0,220),'content_text'=>$id===null?null:$text,'image_url'=>$image,
            'published_at'=>(string)($r['published_at']??$r['upload_date']??''),
            'url'=>$config['site_url'].$m['url'].rawurlencode((string)$r[$m['id']])];
    }
    if($id!==null){if(!$items)throw new NuFailure(404,'NOT_FOUND','This article is unavailable.');return $items[0];}
    return ['items'=>$items,'page'=>$page,'has_more'=>$more];
}
function nu_exam_catalogue(PDO $db,string $q,int $page): array {
    $page=max(1,min(10000,$page));$q=mb_substr($q,0,100);
    $s=$db->prepare('SELECT id,name,price FROM files WHERE name LIKE ? ORDER BY id DESC LIMIT 21 OFFSET '.(($page-1)*20));
    $s->execute(['%'.$q.'%']);$rows=$s->fetchAll();$items=[];
    foreach(array_slice($rows,0,20) as $r){
        $items[]=['id'=>(int)$r['id'],'name'=>$r['name'],'price_kobo'=>nu_money_to_kobo($r['price'])];
    }
    return ['items'=>$items,'page'=>$page,'has_more'=>count($rows)>20,'service'=>'exam-summary'];
}

function nu_academic_period(?DateTimeInterface $date=null): string {
    $when=$date??new DateTimeImmutable('now',new DateTimeZone('Africa/Lagos'));
    return $when->format('Y').'_'.(((int)$when->format('n')<=6)?'1':'2');
}
function nu_timetable_code(string $value): string {
    return strtoupper(str_replace(' ','',trim($value)));
}
function nu_timetable_type(string $courseCode): string {
    static $practical=['CHM192','ESM222','BIO211','CHM292','PHY192','ESM234','CIT104','MTH101','PHY191','EMT409','BIO201','CIT191','ESM103','BIO191','EMT411','PHY291','CHM291','CHM191','BIO192'];
    static $pop=['CLL203','CLL231','CLL232','CLL233','CLL234','JIL100','JIL111','JIL112','JIL211'];
    static $cbt=['GST302','NOU807','NOU707'];
    $code=nu_timetable_code($courseCode);
    if(in_array($code,$practical,true))return 'Practical';
    if(in_array($code,$pop,true))return 'POP';
    if(in_array($code,$cbt,true))return 'CBT';
    if(preg_match('/^[A-Z]{3}(\d)/D',$code,$m))return in_array((int)$m[1],[1,2],true)?'CBT':'POP';
    return 'CBT';
}
function nu_timetable_datetime(string $rawDate,string $rawTime): ?DateTimeImmutable {
    try {
        $tz=new DateTimeZone('Africa/Lagos');
        $date=trim(preg_replace('/(\d+)(st|nd|rd|th)/i','$1',$rawDate)??$rawDate);
        $date=trim(preg_replace('/,\s*(?=\d{4})/',' ',$date)??$date);
        $time=strtolower(trim($rawTime));
        $time=str_replace('.',':',$time);
        $time=preg_replace('/\s+/','',$time)??$time;
        $time=preg_replace('/^(\d{1,2})(am|pm)$/i','$1:00 $2',$time)??$time;
        $time=preg_replace('/^(\d{1,2}:\d{2})(am|pm)$/i','$1 $2',$time)??$time;
        $full=trim($date.' '.$time);
        foreach(['l, j F Y g:i a','l j F Y g:i a','j F Y g:i a','Y-m-d H:i:s','Y-m-d H:i','Y-m-d g:i a'] as $format){
            $dt=DateTimeImmutable::createFromFormat($format,$full,$tz);
            if($dt instanceof DateTimeImmutable)return $dt;
        }
        return new DateTimeImmutable($full,$tz);
    } catch(Throwable $e) {
        return null;
    }
}
function nu_timetable(PDO $db,string $rawCourses): array {
    $pieces=preg_split('/[,\s]+/',strtoupper($rawCourses),-1,PREG_SPLIT_NO_EMPTY)?:[];
    $codes=[];
    foreach($pieces as $piece){
        $code=nu_timetable_code($piece);
        if(!preg_match('/^[A-Z]{2,5}[0-9]{3}$/D',$code))throw new NuFailure(422,'INVALID_COURSE','Use valid course codes such as CIT411.');
        if(!in_array($code,$codes,true))$codes[]=$code;
        if(count($codes)>30)throw new NuFailure(422,'TOO_MANY_COURSES','A maximum of 30 registered courses can be checked at once.');
    }
    if(!$codes)throw new NuFailure(422,'COURSES_REQUIRED','Add at least one registered course to generate your timetable.');

    $placeholders=implode(',',array_fill(0,count($codes),'?'));
    $sql="SELECT `day`,`course_code`,`course_title`,`date`,`time`,
              CASE
                WHEN `day` REGEXP '^Day[[:space:]]+[0-9]+$' THEN CAST(SUBSTRING_INDEX(`day`, ' ', -1) AS UNSIGNED)
                WHEN `day` REGEXP '^[0-9]+$' THEN CAST(`day` AS UNSIGNED)
                ELSE 9999
              END AS sortable_day
          FROM personalized_timetable
          WHERE UPPER(REPLACE(`course_code`, ' ', '')) IN ($placeholders)
          ORDER BY sortable_day ASC, course_code ASC";
    $stmt=$db->prepare($sql);$stmt->execute($codes);$rows=$stmt->fetchAll();
    $byCode=[];
    foreach($rows as $row)$byCode[nu_timetable_code((string)$row['course_code'])]=$row;

    $now=new DateTimeImmutable('now',new DateTimeZone('Africa/Lagos'));
    $items=[];$sourcePeriods=[];$next=null;
    foreach($codes as $code){
        if(!isset($byCode[$code]))continue;
        $row=$byCode[$code];
        $dt=nu_timetable_datetime((string)($row['date']??''),(string)($row['time']??''));
        $period=$dt?nu_academic_period($dt):null;
        if($period!==null)$sourcePeriods[$period]=($sourcePeriods[$period]??0)+1;
        $item=[
            'course_code'=>$code,
            'course_title'=>trim((string)($row['course_title']??'')),
            'day'=>trim((string)($row['day']??'')),
            'date'=>trim((string)($row['date']??'')),
            'time'=>trim((string)($row['time']??'')),
            'exam_type'=>nu_timetable_type($code),
            'exam_datetime'=>$dt? $dt->format(DATE_ATOM):null,
            'is_past'=>$dt? $dt<$now:false,
        ];
        $items[]=$item;
        if($dt!==null&&$dt>=$now){
            if($next===null||$dt<new DateTimeImmutable((string)$next['exam_datetime']))$next=$item;
        }
    }
    usort($items,function(array $a,array $b):int{
        if($a['exam_datetime']===null&&$b['exam_datetime']===null)return strcmp($a['course_code'],$b['course_code']);
        if($a['exam_datetime']===null)return 1;
        if($b['exam_datetime']===null)return -1;
        return strcmp($a['exam_datetime'],$b['exam_datetime']);
    });
    if($next===null){foreach($items as $item){if($item['exam_datetime']!==null&&!$item['is_past']){$next=$item;break;}}}
    $missing=array_values(array_filter($codes,fn(string $code):bool=>!isset($byCode[$code])));
    arsort($sourcePeriods);$sourcePeriod=$sourcePeriods?array_key_first($sourcePeriods):null;
    $currentPeriod=nu_academic_period($now);
    return [
        'current_period'=>$currentPeriod,
        'source_period'=>$sourcePeriod,
        'period_mismatch'=>$sourcePeriod!==null&&$sourcePeriod!==$currentPeriod,
        'items'=>$items,
        'missing_courses'=>$missing,
        'next_exam'=>$next,
        'generated_at'=>$now->format(DATE_ATOM),
    ];
}
