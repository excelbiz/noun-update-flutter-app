import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'skin_theme.dart';

String _hex(Color c)=>'#${c.toARGB32().toRadixString(16).padLeft(8,'0').substring(2)}';
Future<String>? _faces;
Future<String> _fontFaces()=>_faces??=()async{
 final css=<String>[];
 for(final face in [('NUSans','NUSans-Regular.ttf',400),('NUSans','NUSans-Bold.ttf',700),('NUReading','NUReading.ttf',400)]){
  final bytes=await rootBundle.load('assets/fonts/${face.$2}');
  css.add('@font-face{font-family:${face.$1};font-weight:${face.$3};src:url(data:font/ttf;base64,${base64Encode(bytes.buffer.asUint8List(bytes.offsetInBytes,bytes.lengthInBytes))}) format("truetype");font-display:swap;}');
 }
 return css.join();
}();

/// Presentation only. No DOM replacement, account data, navigation or form edits.
Future<String> webSkinCss(ThemeData theme)async{
 final t=theme.extension<SkinTokens>();if(t==null||!t.skin.isPremium)return '';
 final bg=_hex(t.background),surface=_hex(t.surface),ink=_hex(t.ink),primary=_hex(t.primary),onPrimary=_hex(theme.colorScheme.onPrimary),outline=_hex(Color.alphaBlend(t.primary.withValues(alpha:.35),t.surface));
 final body=t.bodyFont.startsWith('sans-serif')?'Arial':t.bodyFont,display=t.displayFont.startsWith('sans-serif')?'Arial':t.displayFont;
 final faces=await _fontFaces();
 return '''$faces
:root{color-scheme:${theme.brightness.name};--bs-body-bg:$bg;--bs-body-color:$ink;--bs-primary:$primary;--bs-border-color:$outline;--bs-secondary-color:$ink;--bs-tertiary-bg:$surface;--bs-card-bg:$surface;--bs-card-color:$ink;--bs-link-color:$primary;--bs-modal-bg:$surface;--bs-dropdown-bg:$surface;--bs-dropdown-color:$ink;--bs-table-color:$ink;--bs-table-bg:$surface;}
html,body{background-color:$bg!important;color:$ink!important;}
body,input,select,textarea,button{font-family:"$body","NUSans",Arial,sans-serif!important;}
h1,h2,h3,h4,h5,h6,.card-title,.panel-title{font-family:"$display","NUSans",Arial,sans-serif!important;}
header,.navbar,.site-header,.page-header,.tool-header{background-color:$bg!important;color:$ink!important;border-color:$outline!important;}
:where(a){color:$primary!important;}
:where(p,label,small,li,td,th){color:inherit!important;}
.card,.panel,.modal-content,.dropdown-menu,.list-group-item,.tool-card,.result-card,.form-card{background-color:$surface!important;color:$ink!important;border-color:$outline!important;border-radius:${t.radius}px!important;${t.skin==AppSkin.futureTech?'box-shadow:0 0 14px ${_hex(t.heroSurface)};':''}}
:where(input:not([type=checkbox]):not([type=radio]):not([type=range]):not([type=submit]):not([type=button]):not([type=image]),select,textarea,.form-control,.form-select){background-color:$surface!important;color:$ink!important;border-color:$outline!important;border-radius:${t.radius}px!important;}
input::placeholder,textarea::placeholder{color:$ink;opacity:.58;}
input:focus-visible,select:focus-visible,textarea:focus-visible,button:focus-visible,a:focus-visible{outline:2px solid $primary;outline-offset:2px;}
.is-invalid,[aria-invalid=true]{border-color:#dc3545!important;}
.btn-primary,button[type=submit]:not(.btn-danger):not([data-destructive]),input[type=submit]:not(.btn-danger){background-color:$primary!important;color:$onPrimary!important;border-color:$primary!important;border-radius:${t.radius}px!important;}
.btn-outline-primary{color:$primary!important;border-color:$primary!important;border-radius:${t.radius}px!important;}
''';
}

/// The guard is checked inside the current document, even after async font loading.
String webSkinScript(String css,AppSkin skin)=>'''
(()=>{if(location.protocol!=='https:'||!(location.hostname==='nounupdate.com'||location.hostname.endsWith('.nounupdate.com')))return;
const id='nu-app-skin',css=${jsonEncode(css)};let style=document.getElementById(id);
if(!css){if(style)style.remove();delete document.documentElement.dataset.nuAppSkin;return;}
if(!style){style=document.createElement('style');style.id=id;(document.head||document.documentElement).appendChild(style);}
style.textContent=css;document.documentElement.dataset.nuAppSkin=${jsonEncode(skin.name)};
})();
''';
