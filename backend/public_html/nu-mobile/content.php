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
