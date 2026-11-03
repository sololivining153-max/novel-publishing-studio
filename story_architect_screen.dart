import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/project.dart';
import '../models/outline_result.dart';
import '../services/project_api.dart';

class StoryArchitectScreen extends StatefulWidget {
  final NovelProject project;
  const StoryArchitectScreen({super.key, required this.project});
  @override
  State<StoryArchitectScreen> createState() => _StoryArchitectScreenState();
}

class _StoryArchitectScreenState extends State<StoryArchitectScreen> {
  final api = const ProjectApi();
  final instructions = TextEditingController();
  int chapters = 24, words = 80000;
  bool loading = false;
  String? error;
  OutlineResult? result;

  Future<void> _generate() async {
    setState(() { loading = true; error = null; result = null; });
    try {
      final r = await api.generateOutline(projectId: widget.project.id,
        targetChapters: chapters, targetWords: words, instructions: instructions.text);
      if (mounted) setState(() => result = r);
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => loading = false); }
  }

  @override
  void dispose() { instructions.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Story Architect')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Text(widget.project.title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      const Text('Generate a proposed blueprint. Review it before approving any story facts.'),
      const SizedBox(height: 20),
      DropdownButtonFormField<int>(value: chapters, decoration: const InputDecoration(labelText: 'Target chapters'),
        items: [12, 18, 24, 30, 36, 42].map((v) => DropdownMenuItem(value: v, child: Text('$v chapters'))).toList(),
        onChanged: loading ? null : (v) { if (v != null) setState(() => chapters = v); }),
      DropdownButtonFormField<int>(value: words, decoration: const InputDecoration(labelText: 'Target word count'),
        items: [40000, 60000, 80000, 100000, 120000].map((v) => DropdownMenuItem(value: v, child: Text('${v ~/ 1000}k words'))).toList(),
        onChanged: loading ? null : (v) { if (v != null) setState(() => words = v); }),
      const SizedBox(height: 12),
      TextField(controller: instructions, minLines: 3, maxLines: 6,
        decoration: const InputDecoration(labelText: 'Additional instructions (optional)',
          hintText: 'Tone, POV, ending, themes and constraints…', border: OutlineInputBorder())),
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: loading ? null : _generate,
        icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.auto_awesome),
        label: Text(loading ? 'Architect is working…' : 'Generate story blueprint')),
      if (error != null) ...[const SizedBox(height: 12), Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
      if (result != null) ...[
        const SizedBox(height: 22),
        Row(children: [Expanded(child: Text('Proposed blueprint', style: Theme.of(context).textTheme.titleLarge)),
          IconButton(onPressed: () async { await Clipboard.setData(ClipboardData(text: result!.outline));
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Outline copied.'))); },
            icon: const Icon(Icons.copy))]),
        Text('Model: ${result!.model} • Prompt: ${result!.promptVersion}',
          style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        SelectableText(result!.outline),
        const SizedBox(height: 18),
        const Text('This output is a proposal. Approval, editing and saving it as official canon will be added in a later milestone.'),
      ],
    ]),
  );
}
