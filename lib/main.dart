import 'package:flutter/material.dart';
import 'models/project.dart';
import 'screens/StoryArchitectScreen.dart';
import 'screens/StoryIntelligenceScreen.dart';
import 'screens/PublishingStudioScreen.dart';

void main() { runApp(const NovelApp()); }

class NovelApp extends StatelessWidget {
  const NovelApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Publishing Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final demoProject = NovelProject(
    id: 'demo-project-id',
    title: 'روايتي الأولى',
    language: 'ar',
    genre: 'رواية',
    premise: 'قصة عن وهران',
    status: 'draft',
    createdAt: DateTime.now(),
  );
  final String apiBaseUrl = 'https://your-api.com';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novel Publishing Studio'), centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(demoProject.title, style: Theme.of(context).textTheme.headlineSmall),
            Text('ID: ${demoProject.id}'),
          ]))),
        const SizedBox(height: 20),
        Card(child: ListTile(leading: const Icon(Icons.auto_awesome), title: const Text('Story Architect'),
          subtitle: const Text('توليد مخطط الرواية - 24 فصل'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoryArchitectScreen(project: demoProject))))),
        Card(child: ListTile(leading: const Icon(Icons.psychology), title: const Text('Story Intelligence'),
          subtitle: const Text('الشخصيات والحقائق'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoryIntelligenceScreen(
            projectId: demoProject.id, projectTitle: demoProject.title, apiBaseUrl: apiBaseUrl))))),
        Card(child: ListTile(leading: const Icon(Icons.menu_book, color: Colors.deepPurple), title: const Text('Publishing Studio'),
          subtitle: const Text('العنوان، الإهداء، الفهرس، KDP'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublishingStudioScreen(
            projectId: demoProject.id, apiBaseUrl: apiBaseUrl))))),
      ]),
    );
  }
}
