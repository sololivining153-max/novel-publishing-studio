import 'package:flutter/material.dart';
void main() => runApp(const MyApp());
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Novel Studio')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Card(child: Padding(padding: EdgeInsets.all(16),
            child: Text('Publishing Studio - KDP Ready\nروايتي الأولى - وهران', style: TextStyle(fontSize: 18)))),
          const SizedBox(height: 16),
          Card(child: ListTile(leading: const Icon(Icons.auto_awesome), title: const Text('Story Architect'), subtitle: const Text('24 فصل'))),
          Card(child: ListTile(leading: const Icon(Icons.psychology), title: const Text('Story Intelligence'), subtitle: const Text('الشخصيات والحقائق'))),
          Card(child: ListTile(leading: const Icon(Icons.menu_book), title: const Text('Publishing Studio'), subtitle: const Text('KDP - عنوان، إهداء، فهرس'))),
          const SizedBox(height: 20),
          const Center(child: Text('تم بناء APK بنجاح!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
        ]),
      ),
    );
  }
}
