import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LiteraryEditorScreen extends StatefulWidget {
  final String apiBaseUrl;
  const LiteraryEditorScreen({super.key,required this.apiBaseUrl});
  @override State<LiteraryEditorScreen> createState()=>_LiteraryEditorScreenState();
}
class _LiteraryEditorScreenState extends State<LiteraryEditorScreen> {
  final manuscript=TextEditingController(), contextText=TextEditingController(),
    canon=TextEditingController(), instructions=TextEditingController();
  String mode='developmental', language='en';
  bool busy=false;
  Map<String,dynamic>? result;
  String? error;
  final modes=const {'structural':'Structural','developmental':'Developmental',
    'line':'Line','dialogue':'Dialogue','continuity':'Continuity','pacing':'Pacing',
    'repetition':'Repetition','final':'Final assessment'};
  Future<void> send(String endpoint) async {
    setState((){busy=true;error=null;result=null;});
    try {
      final response=await http.post(Uri.parse('${widget.apiBaseUrl}/v1/editor/$endpoint'),
        headers:{'Content-Type':'application/json'},
        body:jsonEncode({'manuscript':manuscript.text,'review_type':mode,'language':language,
          'project_context':contextText.text,'canon_context':canon.text,'instructions':instructions.text}));
      final data=jsonDecode(response.body);
      if(response.statusCode>=400) throw Exception(data['detail']??'Request failed');
      setState(()=>result=Map<String,dynamic>.from(data));
    } catch(e){setState(()=>error=e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override void dispose(){manuscript.dispose();contextText.dispose();canon.dispose();instructions.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Literary Editor')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      DropdownButtonFormField<String>(value:mode,decoration:const InputDecoration(labelText:'Review mode'),
        items:modes.entries.map((e)=>DropdownMenuItem(value:e.key,child:Text(e.value))).toList(),
        onChanged:busy?null:(v)=>setState(()=>mode=v??mode)),
      DropdownButtonFormField<String>(value:language,decoration:const InputDecoration(labelText:'Report language'),
        items:const [DropdownMenuItem(value:'en',child:Text('English')),
          DropdownMenuItem(value:'ar',child:Text('العربية')),DropdownMenuItem(value:'fr',child:Text('Français'))],
        onChanged:busy?null:(v)=>setState(()=>language=v??language)),
      const SizedBox(height:12),
      TextField(controller:manuscript,minLines:10,maxLines:22,
        decoration:const InputDecoration(labelText:'Chapter or manuscript',border:OutlineInputBorder())),
      const SizedBox(height:10),
      TextField(controller:contextText,minLines:2,maxLines:4,
        decoration:const InputDecoration(labelText:'Project context',border:OutlineInputBorder())),
      const SizedBox(height:10),
      TextField(controller:canon,minLines:2,maxLines:4,
        decoration:const InputDecoration(labelText:'Approved canon',border:OutlineInputBorder())),
      const SizedBox(height:10),
      TextField(controller:instructions,minLines:2,maxLines:4,
        decoration:const InputDecoration(labelText:'Author instructions',border:OutlineInputBorder())),
      const SizedBox(height:12),
      FilledButton(onPressed:busy||manuscript.text.trim().length<30?null:()=>send('review'),
        child:Text(busy?'Reviewing…':'Run editorial review')),
      OutlinedButton(onPressed:busy||manuscript.text.trim().length<30?null:()=>send('local-checks'),
        child:const Text('Local checks only')),
      if(error!=null) Text(error!,style:const TextStyle(color:Colors.red)),
      if(result!=null) SelectableText(const JsonEncoder.withIndent('  ').convert(result)),
      const Text('Suggestions never overwrite your manuscript. Verify every finding before applying it.')
    ]));
}
