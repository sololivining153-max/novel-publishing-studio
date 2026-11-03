import 'package:flutter/material.dart';
import 'projects_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('NOVEL FORGE AI')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text('Your novel. Your world. Your studio.',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Plan a coherent story, write chapter by chapter, and refine your manuscript.'),
      const SizedBox(height: 24),
      FilledButton.icon(onPressed: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ProjectsScreen())),
        icon: const Icon(Icons.library_books_outlined), label: const Text('Open my novels')),
      const SizedBox(height: 20),
      const _Feature(title: 'Story Architect', detail: 'Turn an idea into a structured story blueprint.'),
      const _Feature(title: 'Novel Writer', detail: 'Draft scenes and chapters with continuity in mind.'),
      const _Feature(title: 'Literary Editor', detail: 'Review structure, logic, style, dialogue and language.'),
    ]),
  );
}

class _Feature extends StatelessWidget {
  final String title, detail;
  const _Feature({required this.title, required this.detail});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text(detail), trailing: const Icon(Icons.arrow_forward_ios, size: 16)));
}
