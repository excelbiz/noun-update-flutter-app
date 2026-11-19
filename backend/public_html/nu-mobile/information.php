<?php
declare(strict_types=1);

/** Operator-approved text only. No requests to public HTML and no user input as a filename. */
function nu_native_information(array $config, string $id): array {
    $allowed=['about-noun','faqs','privacy-policy','terms-of-use','editorial-policy','corrections','sources','advertising'];
    if(!in_array($id,$allowed,true))throw new NuFailure(404,'NOT_FOUND','This information page does not exist.');
    $path=$config['native_information_file']??null;
    if(!is_string($path)||!is_file($path)||!is_readable($path)) {
        throw new NuFailure(503,'NATIVE_CONTENT_UNAVAILABLE','This page has not yet been published for the app.');
    }
    $raw=file_get_contents($path,false,null,0,524289);
    if($raw===false||strlen($raw)>524288)throw new RuntimeException('Invalid native information file.');
    $pages=json_decode($raw,true,16,JSON_THROW_ON_ERROR);
    $data=$pages[$id]??null;
    if(!is_array($data)||!is_string($data['title']??null)||trim($data['title'])===''||!is_array($data['sections']??null)||$data['sections']===[]) {
        throw new NuFailure(503,'NATIVE_CONTENT_UNAVAILABLE','This page has not yet been published for the app.');
    }
    $sections=[];
    foreach($data['sections'] as $section){
        if(!is_array($section)||!is_string($section['text']??null)||trim($section['text'])==='')throw new RuntimeException('Invalid native information section.');
        $sections[]=['heading'=>is_string($section['heading']??null)?$section['heading']:'','text'=>$section['text']];
    }
    return ['title'=>$data['title'],'updated_at'=>is_string($data['updated_at']??null)?$data['updated_at']:null,'sections'=>$sections];
}
