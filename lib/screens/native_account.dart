import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../widgets/native_ui.dart';
import 'native_tools.dart';

class NativeAuth extends StatefulWidget {
 const NativeAuth(this.api,{super.key,this.initialMode='login'});
 final ApiClient api;final String initialMode;
 @override State<NativeAuth> createState()=>_NativeAuthState();
}
class _NativeAuthState extends State<NativeAuth>{
 final email=TextEditingController(),password=TextEditingController(),name=TextEditingController(),code=TextEditingController();
 late String mode;bool busy=false,hidden=true;String? message;
 @override void initState(){super.initState();mode=widget.initialMode;}
 @override void dispose(){email.dispose();password.dispose();name.dispose();code.dispose();super.dispose();}
 Future<void> submit()async{if(busy)return;setState((){busy=true;message=null;});try{
  final path=switch(mode){'register'=>'/auth/register','reset'=>'/auth/reset-request','code'=>'/auth/reset-finish',_=>'/auth/login'};
  final d=unpack(await widget.api.postJson(path,{'email':email.text.trim(),'password':password.text,'name':name.text.trim(),'code':code.text.trim()}));
  if(mode=='reset'){if(mounted)setState((){mode='code';message='${d['message']}';});}
  else if(mode=='code'){password.clear();if(mounted)setState((){mode='login';message='${d['message']}';});}
  else{await const SessionStore().saveTokens(accessToken:d['access_token'] as String,refreshToken:d['refresh_token'] as String);if(mounted)Navigator.pop(context,true);}
 }catch(e){if(mounted)setState(()=>message='$e');}finally{if(mounted)setState(()=>busy=false);}}
 Widget _insideTools()=>NuPanel(color:nuMint,padding:12,child:Column(
  crossAxisAlignment:CrossAxisAlignment.start,
  children:[
   const Text('Inside NOUN Update',style:TextStyle(fontWeight:FontWeight.w800,color:nuDeep)),
   const SizedBox(height:14),
   Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
    for(final item in [('Fee Checker',Icons.account_balance_wallet_rounded,nuGreen),('Study Hub',Icons.lightbulb_rounded,nuGold),('Mock e-Exam',Icons.desktop_windows_rounded,nuRed)])
     Expanded(child:InkWell(
      onTap:()=>pushNu(context,item.$1=='Fee Checker'?NativeFees(widget.api):item.$1=='Study Hub'?MaterialLibrary(api:widget.api):const NativeUnavailable('Mock e-Exam')),
      child:Column(children:[GlossIcon(item.$2,color:item.$3,size:46),const SizedBox(height:8),Text(item.$1,textAlign:TextAlign.center,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700))]),
     )),
   ]),
  ],
 ));
 @override Widget build(BuildContext context)=>NuPage(title:'Your student space',child:ListView(padding:EdgeInsets.zero,children:[
 StudentHero(title:mode=='login'?'Welcome back!':'Your next chapter.',height:MediaQuery.textScalerOf(context).scale(16)>20?300:245),
 Container(transform:Matrix4.translationValues(0,-18,0),padding:const EdgeInsets.fromLTRB(20,23,20,18),decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(24))),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
 if(mode!='login')NuTitle(switch(mode){'register'=>'Create your account','reset'=>'Reset your password',_=>'Enter your reset code'}),
 if(mode=='register')Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:name,autofillHints:const [AutofillHints.name],decoration:const InputDecoration(labelText:'Full name',prefixIcon:Icon(Icons.person_outline)))),
 TextField(controller:email,keyboardType:TextInputType.emailAddress,autofillHints:const [AutofillHints.username],decoration:const InputDecoration(labelText:'Email address',prefixIcon:Icon(Icons.email_outlined))),const SizedBox(height:12),
 if(mode=='code')... [TextField(controller:code,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'8-digit reset code')),const SizedBox(height:12)],
 if(mode!='reset')TextField(controller:password,obscureText:hidden,autofillHints:mode=='login'?const [AutofillHints.password]:const [AutofillHints.newPassword],decoration:InputDecoration(labelText:mode=='code'?'New password':'Password',helperText:mode=='register'||mode=='code'?'Use 10–128 characters':null,prefixIcon:const Icon(Icons.lock_outline),suffixIcon:IconButton(tooltip:hidden?'Show password':'Hide password',onPressed:()=>setState(()=>hidden=!hidden),icon:Icon(hidden?Icons.visibility_off_outlined:Icons.visibility_outlined))),onSubmitted:(_)=>submit()),
 if(mode=='login')Align(alignment:Alignment.centerRight,child:TextButton(onPressed:()=>setState(()=>mode='reset'),child:const Text('Forgot password?'))),
 if(message!=null)Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Text(message!)),const SizedBox(height:20),FilledButton(onPressed:busy?null:submit,child:Text(busy?'Please wait…':switch(mode){'register'=>'Create account','reset'=>'Send reset code','code'=>'Change password',_=>'Sign in'})),
 const SizedBox(height:10),OutlinedButton(onPressed:()=>setState((){mode=mode=='login'?'register':'login';message=null;}),child:Text(mode=='login'?'Create an account':'Back to sign in')),
 const SizedBox(height:14),const Row(children:[Expanded(child:Divider()),Padding(padding:EdgeInsets.symmetric(horizontal:12),child:Text('Explore at your pace',style:TextStyle(fontSize:11))),Expanded(child:Divider())]),TextButton.icon(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.person_outline),label:const Text('Continue as guest')),const SizedBox(height:8),_insideTools(),const Text('One account. More possibilities.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:nuGreen)),
 ])),]));
}
class NativeProfile extends StatefulWidget {
 const NativeProfile({super.key,required this.api,required this.name});final ApiClient api;final String name;
 @override State<NativeProfile> createState()=>_NativeProfileState();
}
class _NativeProfileState extends State<NativeProfile>{
 final name=TextEditingController(),programme=TextEditingController(),level=TextEditingController(),matric=TextEditingController();bool loading=true,busy=false;Object? error;
 @override void initState(){super.initState();name.text=widget.name;load();}
 @override void dispose(){name.dispose();programme.dispose();level.dispose();matric.dispose();super.dispose();}
 Future<void> load()async{try{final d=unpack(await widget.api.getJson('/profile'));if(mounted)setState((){programme.text='${d['programme']??''}';level.text='${d['level']??''}';matric.text='${d['matric_number']??''}';loading=false;error=null;});}catch(e){if(mounted)setState(()=>error=e);}}
 Future<void> save()async{setState(()=>busy=true);try{await widget.api.postJson('/profile',{'name':name.text,'programme':programme.text,'level':level.text,'matric_number':matric.text});if(mounted){nuMessage(context,'Profile saved.');Navigator.pop(context);}}catch(e){if(mounted)nuMessage(context,e);}finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext context)=>NuPage(title:'Profile details',child:ListView(padding:const EdgeInsets.all(22),children:[if(error!=null)AsyncError(error!,load)else if(loading)const LinearProgressIndicator(),const NuTitle('About you'),for(final field in [(name,'Full name'),(programme,'Programme'),(level,'Level'),(matric,'Matric number')])Padding(padding:const EdgeInsets.only(bottom:14),child:TextField(controller:field.$1,enabled:!loading,decoration:InputDecoration(labelText:field.$2))),const Text('Your matric number is profile information. Continue using your email to sign in.'),const SizedBox(height:20),FilledButton(onPressed:busy||loading?null:save,child:const Text('Save profile'))]));
}
