import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../widgets/native_ui.dart';

class NativeAuth extends StatefulWidget {
 const NativeAuth(this.api,{super.key,this.initialMode='login'});
 final ApiClient api;final String initialMode;
 @override State<NativeAuth> createState()=>_NativeAuthState();
}
class _NativeAuthState extends State<NativeAuth>{
 final email=TextEditingController(),password=TextEditingController(),name=TextEditingController(),code=TextEditingController();
 late String mode;bool busy=false;String? message;
 @override void initState(){super.initState();mode=widget.initialMode;}
 @override void dispose(){email.dispose();password.dispose();name.dispose();code.dispose();super.dispose();}
 Future<void> submit()async{if(busy)return;setState((){busy=true;message=null;});try{
  final path=switch(mode){'register'=>'/auth/register','reset'=>'/auth/reset-request','code'=>'/auth/reset-finish',_=>'/auth/login'};
  final d=unpack(await widget.api.postJson(path,{'email':email.text.trim(),'password':password.text,'name':name.text.trim(),'code':code.text.trim()}));
  if(mode=='reset'){if(mounted)setState((){mode='code';message='${d['message']}';});}
  else if(mode=='code'){password.clear();if(mounted)setState((){mode='login';message='${d['message']}';});}
  else{await const SessionStore().saveTokens(accessToken:d['access_token'] as String,refreshToken:d['refresh_token'] as String);if(mounted)Navigator.pop(context,true);}
 }catch(e){if(mounted)setState(()=>message='$e');}finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext context)=>NuPage(title:'NOUN Update',child:ListView(padding:const EdgeInsets.all(22),children:[const Center(child:BrandLogo(size:92)),const SizedBox(height:20),const GreenBanner(title:'Welcome to your\nstudent space.',text:'Study, prepare and stay connected.',icon:Icons.school_rounded),NuTitle(switch(mode){'register'=>'Create your account','reset'=>'Reset your password','code'=>'Enter your reset code',_=>'Welcome back!'},subtitle:mode=='login'?'Sign in with your Course Summary email and password.':'One account for the website and app.'),
 if(mode=='register')Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:name,autofillHints:const [AutofillHints.name],decoration:const InputDecoration(labelText:'Full name',prefixIcon:Icon(Icons.person_outline)))),
 TextField(controller:email,keyboardType:TextInputType.emailAddress,autofillHints:const [AutofillHints.username],decoration:const InputDecoration(labelText:'Email address',prefixIcon:Icon(Icons.email_outlined))),const SizedBox(height:12),
 if(mode=='code')... [TextField(controller:code,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'8-digit reset code')),const SizedBox(height:12)],
 if(mode!='reset')TextField(controller:password,obscureText:true,autofillHints:mode=='login'?const [AutofillHints.password]:const [AutofillHints.newPassword],decoration:InputDecoration(labelText:mode=='code'?'New password':'Password',helperText:mode=='register'||mode=='code'?'Use 10–128 characters':null,prefixIcon:const Icon(Icons.lock_outline)),onSubmitted:(_)=>submit()),
 if(message!=null)Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Text(message!)),const SizedBox(height:20),FilledButton(onPressed:busy?null:submit,child:Text(busy?'Please wait…':switch(mode){'register'=>'Create account','reset'=>'Send reset code','code'=>'Change password',_=>'Sign in'})),
 if(mode=='login')TextButton(onPressed:()=>setState(()=>mode='reset'),child:const Text('Forgot password?')),
 TextButton(onPressed:()=>setState((){mode=mode=='login'?'register':'login';message=null;}),child:Text(mode=='login'?'Create an account':'Back to sign in')),
 OutlinedButton.icon(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.person_outline),label:const Text('Continue as guest')),
 ]));
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
