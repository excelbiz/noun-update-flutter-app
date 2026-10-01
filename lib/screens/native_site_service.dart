import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../widgets/native_ui.dart';
import '../core/skin_theme.dart';
import '../core/web_skin.dart';

final Uri nounUpdateSite=Uri.parse('https://nounupdate.com');

bool isNounUpdateUri(Uri uri)=>uri.host=='nounupdate.com'||uri.host.endsWith('.nounupdate.com');

Uri? safeNounUpdateDestination(String value){
  final raw=value.trim();
  if(raw.isEmpty)return null;
  final parsed=Uri.tryParse(raw);
  final uri=(parsed!=null&&parsed.hasScheme)?parsed:nounUpdateSite.resolve(raw.startsWith('/')?raw:'/$raw');
  if(uri.scheme!='https'||!isNounUpdateUri(uri))return null;
  return uri;
}

class NativeSiteService extends StatefulWidget {
  const NativeSiteService({super.key,required this.title,required this.destination});
  final String title;
  final String destination;

  @override
  State<NativeSiteService> createState()=>_NativeSiteServiceState();
}

class _NativeSiteServiceState extends State<NativeSiteService>{
  WebViewController? controller;
  String? error;
  int progress=0;
  bool pageReady=false;

  @override void didChangeDependencies(){super.didChangeDependencies();if(pageReady)_applySkin();}

  Future<void> _applySkin()async{
    final web=controller;if(web==null||!mounted)return;
    final theme=Theme.of(context),skin=SkinTokens.of(context).skin;
    try{
      final css=await webSkinCss(theme);if(!mounted||web!=controller||Theme.of(context)!=theme)return;
      await web.setBackgroundColor(theme.scaffoldBackgroundColor);
      await web.runJavaScript(webSkinScript(css,skin));
    }catch(_){/* A presentation failure must not stop the website tool. */}
  }

  @override
  void initState(){
    super.initState();
    final uri=safeNounUpdateDestination(widget.destination);
    if(uri==null){error='This service does not have a valid NOUN Update address.';return;}
    controller=WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted:(_){pageReady=false;},
        onPageFinished:(url){pageReady=safeNounUpdateDestination(url)!=null;if(pageReady)_applySkin();},
        onProgress:(value){if(mounted)setState(()=>progress=value);},
        onNavigationRequest:(request){
          final target=Uri.tryParse(request.url);
          if(target==null)return NavigationDecision.prevent;
          if(target.scheme=='https'&&isNounUpdateUri(target))return NavigationDecision.navigate;
          if(target.scheme=='https'||target.scheme=='mailto'||target.scheme=='tel'){
            launchUrl(target,mode:LaunchMode.externalApplication);
          }
          return NavigationDecision.prevent;
        },
        onWebResourceError:(event){
          if(event.isForMainFrame==true&&mounted)setState(()=>error='This NOUN Update page could not load. Check your connection and retry.');
        },
      ))
      ..loadRequest(uri);
  }

  Future<void> _reload()async{
    if(controller==null)return;
    setState((){error=null;progress=0;});
    await controller!.reload();
  }

  @override
  Widget build(BuildContext context)=>NuPage(
    title:widget.title,
    actions:[
      if(controller!=null)IconButton(tooltip:'Reload',onPressed:_reload,icon:const Icon(Icons.refresh_rounded)),
      IconButton(tooltip:'Open in browser',onPressed:()async{final uri=safeNounUpdateDestination(widget.destination);if(uri!=null)await launchUrl(uri,mode:LaunchMode.externalApplication);},icon:const Icon(Icons.open_in_new_rounded)),
    ],
    child:Column(children:[
      if(progress<100&&controller!=null)LinearProgressIndicator(value:progress/100),
      if(error!=null)Expanded(child:Center(child:AsyncError(error!,_reload))) else if(controller!=null)Expanded(child:WebViewWidget(controller:controller!)) else const Expanded(child:Center(child:Text('This service is unavailable.'))),
    ]),
  );
}
