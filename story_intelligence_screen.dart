import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Story memory dashboard. Pass API base URL and novel project ID from app config.
class StoryIntelligenceScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;
  final String apiBaseUrl;
  const StoryIntelligenceScreen({
    super.key, required this.projectId, required this.projectTitle,
    required this.apiBaseUrl,
  });

  @override
  State<StoryIntelligenceScreen> createState() => _StoryIntelligenceScreenState();
}

class _StoryIntelligenceScreenState extends State<StoryIntelligenceScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic> dashboard = {};
  List<dynamic> characters = [], facts = [], conflicts = [];

  String get base => '${widget.apiBaseUrl}/v1/projects/${widget.projectId}/intelligence';
  Uri endpoint(String path) => Uri.parse('$base/$path');

  @override
  void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    setState(() { loading = true; error = null; });
    try {
      final responses = await Future.wait([
        http.get(endpoint('dashboard')), http.get(endpoint('characters')),
        http.get(endpoint('canon')), http.get(endpoint('canon/conflicts')),
      ]).timeout(const Duration(seconds: 25));
      if (responses.any((r) => r.statusCode != 200)) {
        throw Exception('Server returned an error. Check the API and project ID.');
      }
      if (!mounted) return;
      setState(() {
        dashboard = jsonDecode(responses[0].body);
        characters = jsonDecode(responses[1].body);
        facts = jsonDecode(responses[2].body);
        conflicts = jsonDecode(responses[3].body)['conflicts'];
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  Future<void> addCharacter() async {
    final name = TextEditingController(), role = TextEditingController();
    final desc = TextEditingController(), goals = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('New character'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
        TextField(controller: role, decoration: const InputDecoration(labelText: 'Role')),
        TextField(controller: desc, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
        TextField(controller: goals, maxLines: 2, decoration: const InputDecoration(labelText: 'Goals')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save'))],
    ));
    if (ok != true || name.text.trim().isEmpty) return;
    final r = await http.post(endpoint('characters'), headers: {'Content-Type':'application/json'},
      body: jsonEncode({'name':name.text.trim(),'role':role.text.trim(),
        'description':desc.text.trim(),'goals':goals.text.trim()}));
    if (r.statusCode == 201) refresh();
    else if (mounted) _message('Could not save character.');
  }

  Future<void> proposeFact() async {
    final subject = TextEditingController(), predicate = TextEditingController(), value = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Propose a story fact'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: subject, decoration: const InputDecoration(labelText: 'Subject *')),
        TextField(controller: predicate, decoration: const InputDecoration(labelText: 'Attribute *')),
        TextField(controller: value, maxLines: 3, decoration: const InputDecoration(labelText: 'Fact *')),
        const Padding(padding: EdgeInsets.only(top: 12),
          child: Text('This will be saved as provisional. It will not become canon until you approve it.')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save proposal'))],
    ));
    if (ok != true || subject.text.trim().isEmpty || predicate.text.trim().isEmpty || value.text.trim().isEmpty) return;
    final r = await http.post(endpoint('canon'), headers: {'Content-Type':'application/json'},
      body: jsonEncode({'subject':subject.text.trim(),'predicate':predicate.text.trim(),
        'value':value.text.trim(),'status':'provisional'}));
    if (r.statusCode == 201) refresh();
    else if (mounted) _message('Could not save fact.');
  }

  Future<void> updateFact(String id, String status) async {
    final r = await http.patch(endpoint('canon/$id/status'),
      headers: {'Content-Type':'application/json'}, body: jsonEncode({'status':status}));
    if (r.statusCode == 200) refresh();
    else if (mounted) _message('Could not update fact.');
  }

  void _message(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Story Intelligence'),
      actions: [IconButton(onPressed: refresh, icon: const Icon(Icons.refresh))]),
    floatingActionButton: PopupMenuButton<String>(
      icon: const Icon(Icons.add_circle, size: 32),
      onSelected: (v) => v == 'character' ? addCharacter() : proposeFact(),
      itemBuilder: (_) => const [
        PopupMenuItem(value:'character', child:Text('Add character')),
        PopupMenuItem(value:'fact', child:Text('Propose canon fact')),
      ],
    ),
    body: loading ? const Center(child:CircularProgressIndicator())
      : error != null ? Center(child:Padding(padding:const EdgeInsets.all(24), child:Column(
          mainAxisSize:MainAxisSize.min, children:[Text(error!, textAlign:TextAlign.center),
            const SizedBox(height:12), FilledButton(onPressed:refresh, child:const Text('Retry'))]))
      : RefreshIndicator(onRefresh:refresh, child:ListView(padding:const EdgeInsets.all(16), children:[
          Text(widget.projectTitle, style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:12),
          Wrap(spacing:8, runSpacing:8, children:[
            _metric('Characters', dashboard['characters']),
            _metric('Facts', dashboard['facts']),
            _metric('Events', dashboard['events']),
            _metric('Chapter memories', dashboard['chapter_memories']),
          ]),
          const SizedBox(height:16),
          if (conflicts.isNotEmpty) Card(
            color:Theme.of(context).colorScheme.errorContainer,
            child:Padding(padding:const EdgeInsets.all(12), child:Column(
              crossAxisAlignment:CrossAxisAlignment.start, children:[
                const Text('Potential contradictions', style:TextStyle(fontWeight:FontWeight.bold)),
                ...conflicts.map((c)=>Padding(padding:const EdgeInsets.only(top:8),
                  child:Text('${c['subject']} / ${c['predicate']}: ${(c['facts'] as List).map((f)=>f['value']).join('  •  ')}'))),
              ]))),
          _heading('Characters', characters.length),
          if(characters.isEmpty) const Text('No characters recorded yet.'),
          ...characters.map((c)=>Card(child:ListTile(
            leading:const CircleAvatar(child:Icon(Icons.person_outline)),
            title:Text(c['name'] ?? ''),
            subtitle:Text([c['role'],c['description']].where((x)=>x!=null && x.toString().isNotEmpty).join(' • ')),
          ))),
          _heading('Canon facts', facts.length),
          if(facts.isEmpty) const Text('No story facts recorded yet.'),
          ...facts.map((f)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('${f['subject']} — ${f['predicate']}',style:const TextStyle(fontWeight:FontWeight.bold)),
              const SizedBox(height:4),Text(f['value'] ?? ''),
              const SizedBox(height:8),
              Wrap(spacing:4, children:[
                Chip(label:Text(f['status'] ?? 'provisional')),
                if(f['status']!='approved') TextButton(onPressed:()=>updateFact(f['id'],'approved'),child:const Text('Approve')),
                if(f['status']!='disputed') TextButton(onPressed:()=>updateFact(f['id'],'disputed'),child:const Text('Dispute')),
                if(f['status']!='secret') TextButton(onPressed:()=>updateFact(f['id'],'secret'),child:const Text('Mark secret')),
              ])
            ])))),
          const SizedBox(height:72),
        ])),
  );

  Widget _metric(String label, dynamic value) => SizedBox(width:145, child:Card(
    child:Padding(padding:const EdgeInsets.all(12),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('${value ?? 0}',style:Theme.of(context).textTheme.headlineSmall),
        Text(label),
      ]))));
  Widget _heading(String title,int count)=>Padding(
    padding:const EdgeInsets.only(top:16,bottom:8),
    child:Text('$title ($count)',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold)));
}
