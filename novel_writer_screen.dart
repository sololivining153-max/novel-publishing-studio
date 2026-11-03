import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Basic scene-preparation and draft-check interface.
/// AI generation is performed by the server's configured provider adapter.
class NovelWriterScreen extends StatefulWidget {
  final String projectId;
  final String apiBaseUrl;
  const NovelWriterScreen({super.key, required this.projectId, required this.apiBaseUrl});
  @override
  State<NovelWriterScreen> createState() => _NovelWriterScreenState();
}

class _NovelWriterScreenState extends State<NovelWriterScreen> {
  final goal = TextEditingController();
  final pov = TextEditingController();
  final chapter = TextEditingController();
  final location = TextEditingController();
  final style = TextEditingController();
  final draft = TextEditingController();
  bool busy = false;
  String? prompt;
  Map<String,dynamic>? report;
  String? error;

  Uri url(String path) => Uri.parse('${widget.apiBaseUrl}/v1/projects/${widget.projectId}/writer/$path');

  Future<void> prepareContext() async {
    if (goal.text.trim().isEmpty) return;
    setState(() { busy = true; error = null; report = null; });
    try {
      final r = await http.post(url('scene-context'),
        headers: {'Content-Type':'application/json'},
        body: jsonEncode({'scene_goal':goal.text.trim(),'pov_character':pov.text.trim(),
          'scene_time':chapter.text.trim(),'location':location.text.trim(),
          'style_guide':style.text.trim()})).timeout(const Duration(seconds:30));
      if (r.statusCode != 200) throw Exception('Context request failed (${r.statusCode}).');
      final data = jsonDecode(r.body);
      if (mounted) setState(() { prompt = data['prompt']; busy = false; });
    } catch(e) { if(mounted) setState(() { error=e.toString(); busy=false; }); }
  }

  Future<void> checkDraft() async {
    if (draft.text.trim().isEmpty) return;
    setState(() { busy=true; error=null; });
    try {
      final r = await http.post(url('check-draft'),
        headers: {'Content-Type':'application/json'},
        body: jsonEncode({'draft':draft.text})).timeout(const Duration(seconds:30));
      if (r.statusCode != 200) throw Exception('Draft check failed (${r.statusCode}).');
      if(mounted) setState(() { report=jsonDecode(r.body); busy=false; });
    } catch(e) { if(mounted) setState(() { error=e.toString(); busy=false; }); }
  }

  @override
  void dispose() {
    goal.dispose(); pov.dispose(); chapter.dispose(); location.dispose();
    style.dispose(); draft.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Novel Writer')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Text('Prepare a scene', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height:8),
      TextField(controller:goal, maxLines:3, decoration:const InputDecoration(labelText:'Scene objective *', border:OutlineInputBorder())),
      const SizedBox(height:8),
      TextField(controller:pov, decoration:const InputDecoration(labelText:'POV character', border:OutlineInputBorder())),
      const SizedBox(height:8),
      TextField(controller:chapter, decoration:const InputDecoration(labelText:'Chapter / story time (e.g. Chapter 8)', border:OutlineInputBorder())),
      const SizedBox(height:8),
      TextField(controller:location, decoration:const InputDecoration(labelText:'Location', border:OutlineInputBorder())),
      const SizedBox(height:8),
      TextField(controller:style, maxLines:2, decoration:const InputDecoration(labelText:'Style guide (optional)', border:OutlineInputBorder())),
      const SizedBox(height:12),
      FilledButton.icon(onPressed:busy?null:prepareContext, icon:const Icon(Icons.auto_awesome), label:const Text('Build continuity-aware prompt')),
      if(prompt!=null) ...[
        const SizedBox(height:12),
        const Text('Prepared prompt', style:TextStyle(fontWeight:FontWeight.bold)),
        SelectableText(prompt!),
        const SizedBox(height:8),
        const Text('Send this prompt to the server-side AI provider. The API key must never be placed in this mobile app.'),
      ],
      const Divider(height:32),
      Text('Check a generated scene', style:Theme.of(context).textTheme.titleLarge),
      const SizedBox(height:8),
      TextField(controller:draft, minLines:6, maxLines:14, decoration:const InputDecoration(hintText:'Paste the scene draft here...', border:OutlineInputBorder())),
      const SizedBox(height:12),
      OutlinedButton.icon(onPressed:busy?null:checkDraft, icon:const Icon(Icons.fact_check), label:const Text('Check continuity & secret leaks')),
      if(report!=null) Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Review: ${report!['status']}',style:const TextStyle(fontWeight:FontWeight.bold)),
          const SizedBox(height:8),
          Text('Potential secret leaks: ${(report!['secret_leaks'] as List).length}'),
          ...(report!['secret_leaks'] as List).map((x)=>Text('• ${x['matched_text']}')),
          const SizedBox(height:6),
          Text('Missing required anchors: ${(report!['missing_required_terms'] as List).join(', ')}'),
          const SizedBox(height:6),
          ...(report!['issues'] as List).map((x)=>Text('• $x')),
        ]))),
      if(error!=null) Padding(padding:const EdgeInsets.only(top:12),child:Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
      if(busy) const Padding(padding:EdgeInsets.all(16),child:Center(child:CircularProgressIndicator())),
    ]),
  );
}
