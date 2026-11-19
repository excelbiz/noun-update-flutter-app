<?php
declare(strict_types=1);
require dirname(__DIR__).'/public_html/nu-mobile/core.php';
require dirname(__DIR__).'/public_html/nu-mobile/information.php';

function verify(bool $condition,string $message):void {
    if(!$condition)throw new RuntimeException($message);
    echo "PASS: $message\n";
}
$test=tempnam(sys_get_temp_dir(),'nu-info-');
try{
    file_put_contents($test,json_encode(['privacy-policy'=>[
        'title'=>'Fixture privacy policy','updated_at'=>'2026-11-19',
        'sections'=>[['heading'=>'Scope','text'=>'Approved fixture text','url'=>'https://example.test']],
    ]],JSON_THROW_ON_ERROR));
    $config=['native_information_file'=>$test];
    $page=nu_native_information($config,'privacy-policy');
    verify($page['sections']===[['heading'=>'Scope','text'=>'Approved fixture text']],'Structured data omits link and HTML navigation fields');
    foreach(['about-noun'=>503,'../../config.local'=>404,'private-help'=>404] as $id=>$status){
        try{nu_native_information($config,$id);throw new RuntimeException('Expected rejection');}
        catch(NuFailure $e){verify($e->status===$status,"Expected status $status for $id");}
    }
}finally{unlink($test);}
