import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noun_update_student_app/core/skin_theme.dart';
import 'package:noun_update_student_app/core/web_skin.dart';

void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 test('Export real web themes for browser verification without changing form values',()async{
  final out=Directory('${Directory.systemTemp.path}/nu-web-skin-fixtures')..createSync(recursive:true);
  String rgb(Color c)=>'rgb(${(c.toARGB32()>>16)&255}, ${(c.toARGB32()>>8)&255}, ${c.toARGB32()&255})';
  final index=<Map<String,dynamic>>[];
  for(final skin in AppSkin.values.where((s)=>s.isPremium)){for(final brightness in Brightness.values){
   final theme=buildSkinTheme(skin,brightness:brightness),t=theme.extension<SkinTokens>()!,css=await webSkinCss(theme),script=webSkinScript(css,skin),file='${skin.name}-${brightness.name}.html';
   final expected=jsonEncode({'background':rgb(t.background),'surface':rgb(t.surface),'ink':rgb(t.ink),'primary':rgb(t.primary),'buttonInk':rgb(theme.colorScheme.onPrimary),'radius':'${t.radius.toStringAsFixed(0)}px','heading':t.displayFont.startsWith('sans-serif')?'Arial':t.displayFont});
   File('${out.path}/$file').writeAsStringSync('''<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>
body{background:white;color:black;margin:0;padding:20px;font-family:Arial;line-height:1.45}h1{font-size:24px;margin:12px 0}.card{background:white;color:black;border:1px solid #ddd;border-radius:4px;padding:18px;margin-top:20px}label{display:block;margin:12px 0 5px}input,select,button{box-sizing:border-box;width:100%;padding:14px;border:1px solid #ddd;background:white;color:black}button{margin-top:18px;cursor:pointer}small{font-size:11px}.is-invalid{border:1px solid red}.btn-danger{background:#dc3545;color:white}iframe{width:1px;height:1px;border:0}
</style></head><body><small>THEME INTEGRATION · LOCAL TOOL FIXTURE</small><h1>NOUN Update study tool</h1><p>Skin colours and fonts follow you into the page.</p><form class="card" action="/no-network" method="post"><label for="course">Course code</label><input id="course" name="course" value="GST101"><label for="semester">Semester</label><select id="semester" name="semester"><option>2026_2</option></select><button type="submit" class="btn-primary">Open resource</button><input id="protected" value="Account value" disabled><input id="invalid" class="is-invalid" aria-invalid="true" value="Review required"><button type="button" class="btn-danger">Remove resource</button></form><iframe id="frame" srcdoc="<body style='background:rgb(255,255,255);color:rgb(0,0,0)'>Provider frame</body>"></iframe>
<script>$script</script><script>
window.addEventListener('load',async()=>{await document.fonts.ready;
const expected=$expected,fail=[],body=getComputedStyle(document.body),card=getComputedStyle(document.querySelector('.card')),input=getComputedStyle(document.querySelector('#course')),button=getComputedStyle(document.querySelector('.btn-primary'));
function check(ok,label){if(!ok)fail.push(label);}
check(getComputedStyle(document.querySelector('h1')).fontFamily.includes(expected.heading),'heading font');check(body.backgroundColor===expected.background,'body background');check(body.color===expected.ink,'body ink');check(card.backgroundColor===expected.surface,'card surface');check(input.backgroundColor===expected.surface,'input surface');check(input.color===expected.ink,'input ink');check(card.borderRadius===expected.radius,'card radius');check(button.backgroundColor===expected.primary,'button colour');check(button.color===expected.buttonInk,'button contrast');
check(document.querySelector('#course').value==='GST101','form value');check(document.querySelector('#protected').disabled,'disabled state');check(document.querySelector('form').getAttribute('method')==='post','form method');check(document.querySelector('form').getAttribute('action')==='/no-network','form action');check(getComputedStyle(document.querySelector('#invalid')).borderTopColor==='rgb(220, 53, 69)','validation border');check(getComputedStyle(document.querySelector('.btn-danger')).backgroundColor==='rgb(220, 53, 69)','destructive colour');
check(getComputedStyle(document.querySelector('#frame').contentDocument.body).backgroundColor==='rgb(255, 255, 255)','frame isolation');
let calls=0;document.querySelector('form').addEventListener('submit',e=>{e.preventDefault();calls++;});document.querySelector('.btn-primary').click();check(calls===1,'existing submit handler');
document.body.dataset.themeTest=fail.length?'FAIL:'+fail.join(','):'PASS';
});</script></body></html>''');
   index.add({'file':file,'skin':skin.name,'brightness':brightness.name});
  }}
  // Reapplying a skin replaces one style node; expiry removes it.
  final theme=buildSkinTheme(AppSkin.futureTech,brightness:Brightness.dark),css=await webSkinCss(theme);
  File('${out.path}/lifecycle.html').writeAsStringSync('''<html><head><style>body{background:rgb(255,255,255)}</style></head><body><input value="kept"><script>${webSkinScript(css,AppSkin.futureTech)}${webSkinScript(css,AppSkin.futureTech)}
const count=document.querySelectorAll('#nu-app-skin').length;
${webSkinScript('',AppSkin.defaultNoun)}
document.body.dataset.themeTest=count===1&&!document.getElementById('nu-app-skin')&&!document.documentElement.dataset.nuAppSkin&&getComputedStyle(document.body).backgroundColor==='rgb(255, 255, 255)'&&document.querySelector('input').value==='kept'?'PASS':'FAIL:lifecycle';</script></body></html>''');
  index.add({'file':'lifecycle.html'});
  File('${out.path}/outside.html').writeAsStringSync('''<html><head><style>body{background:rgb(255,255,255)}</style></head><body><script>${webSkinScript(css,AppSkin.futureTech)}document.body.dataset.themeTest=!document.getElementById('nu-app-skin')&&getComputedStyle(document.body).backgroundColor==='rgb(255, 255, 255)'?'PASS':'FAIL:origin';</script></body></html>''');
  index.add({'file':'outside.html','host':'nounupdate.com.attacker.test'});index.add({'file':'outside.html','host':'paystack.test'});
  File('${out.path}/index.json').writeAsStringSync(jsonEncode(index));
  expect(await webSkinCss(buildSkinTheme(AppSkin.defaultNoun)),isEmpty);
  expect(index.length,23);
 });
}
