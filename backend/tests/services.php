<?php
declare(strict_types=1);
require_once __DIR__.'/../public_html/nu-mobile/content.php';
function servicesOk(bool $value,string $name):void{if(!$value)throw new RuntimeException('FAILED '.$name);echo "PASS $name\n";}
$items=nu_services(['site_url'=>'https://nounupdate.com']);
$ids=array_column($items,'id');
servicesOk(!in_array('transcript-analyzer',$ids,true),'disabled transcript analyzer hidden');
servicesOk(!in_array('gpa-rescue',$ids,true),'disabled GPA rescue hidden');
servicesOk(count($ids)===count(array_unique($ids)),'service IDs are unique');
servicesOk(in_array('result',$ids,true)&&in_array('mock',$ids,true)&&in_array('exam-practice.html',$ids,true),'enabled website tools retained');
foreach($items as $item){
    servicesOk(($item['enabled']??false)===true,'returned service is enabled '.$item['id']);
    servicesOk(str_starts_with((string)$item['url'],'https://nounupdate.com/'),'returned service URL stays on NOUN Update '.$item['id']);
}
