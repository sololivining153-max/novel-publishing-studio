import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/project_api.dart';
import 'story_architect_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});
  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final api = const ProjectApi();
  late Future<List<NovelProject>> future;
  @override
  void initState() { super.initState(); _reload(); }
  void _reload() => future = api.fetchProjects();

  Future<void> _create() async {
    final key = GlobalKey<FormState>();
    final title = TextEditingController(), genre = TextEditingController(), premise = TextEditingController();
    String language = 'en';
    await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) =>
      AlertDialog(title: const Text('Create a novel'), content: SizedBox(width: 420, child: Form(key: key,
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Novel title *'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter a title' : null),
          TextField(controller: genre, decoration: const InputDecoration(labelText: 'Genre')),
          DropdownButtonFormField<String>(value: language, decoration: const InputDecoration(labelText: 'Language'),
            items: const [DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'ar', child: Text('العربية')),
              DropdownMenuItem(value: 'fr', child: Text('Français'))],
            onChanged: (v) { if (v != null) setDialog(() => language = v); }),
          TextField(controller: premise, minLines: 2, maxLines: 4,
            decoration: const InputDecoration(labelText: 'Story premise')),
        ])))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            if (!key.currentState!.validate()) return;
            Navigator.pop(ctx);
            try { await api.createProject(title: title.text, language: language, genre: genre.text, premise: premise.text);
              if (mounted) setState(_reload);
            } catch (e) { if (mounted) _error(e.toString()); }
          }, child: const Text('Create'))]));
    title.dispose(); genre.dispose(); premise.dispose();
  }

  void _error(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(m), backgroundColor: Colors.red.shade700));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My novels'), actions: [
      IconButton(onPressed: () => setState(_reload), icon: const Icon(Icons.refresh))]),
    floatingActionButton: FloatingActionButton.extended(onPressed: _create,
      icon: const Icon(Icons.add), label: const Text('New novel')),
    body: FutureBuilder<List<NovelProject>>(future: future, builder: (ctx, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snap.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Could not connect to the server.'),
        FilledButton(onPressed: () => setState(_reload), child: const Text('Retry'))]));
      final items = snap.data ?? [];
      if (items.isEmpty) return const Center(child: Text('No novels yet. Create your first project.'));
      return RefreshIndicator(onRefresh: () async => setState(_reload), child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90), itemCount: items.length,
        itemBuilder: (ctx, i) { final p = items[i]; return Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.menu_book)),
          title: Text(p.title), subtitle: Text('${p.genre ?? "Genre not set"} • ${p.language.toUpperCase()}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => StoryArchitectScreen(project: p))).then((_) { if (mounted) setState(_reload); }),
        )); }));
    }),
  );
}
