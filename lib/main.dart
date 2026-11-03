import 'package:flutter/material.dart';
void main() => runApp(const MyApp());
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novel Studio')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Card(child: Padding(padding: EdgeInsets.all(16),
          child: Text('Publishing Studio - KDP Ready\nروايتي الاولى - وهران', style: TextStyle(fontSize: 18)))),
        const SizedBox(height: 16),
        Card(child: ListTile(
          leading: const Icon(Icons.auto_awesome),
          title: const Text('Story Architect'),
          subtitle: const Text('24 فصل - اضغط للدخول'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchitectScreen())),
        )),
        Card(child: ListTile(
          leading: const Icon(Icons.psychology),
          title: const Text('Story Intelligence'),
          subtitle: const Text('الشخصيات والحقائق - اضغط للدخول'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IntelligenceScreen())),
        )),
        Card(child: ListTile(
          leading: const Icon(Icons.menu_book),
          title: const Text('Publishing Studio'),
          subtitle: const Text('عنوان، اهداء، فهرس - KDP - اضغط للدخول'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PublishingScreen())),
        )),
        const SizedBox(height: 20),
        const Center(child: Text('اضغط على اي تبويب للدخول', style: TextStyle(fontSize: 16))),
      ]),
    );
  }
}
class ArchitectScreen extends StatelessWidget {
  const ArchitectScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Story Architect - 24 فصل')),
    body: const Padding(padding: EdgeInsets.all(16),
      child: Text('هنا سيتم توليد مخطط الرواية 24 فصل - 80000 كلمة\n\nبعد ربط الباك اند سيعمل توليد حقيقي')),
  );
}
class IntelligenceScreen extends StatelessWidget {
  const IntelligenceScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Story Intelligence')),
    body: ListView(padding: const EdgeInsets.all(16), children: const [
      Card(child: ListTile(leading: CircleAvatar(child: Text('A')), title: Text('احمد'), subtitle: Text('البطل - 30 سنة'))),
      Card(child: ListTile(leading: CircleAvatar(child: Text('L')), title: Text('ليلى'), subtitle: Text('الصديقة'))),
      SizedBox(height: 16),
      Text('التناقضات: احمد عمره 30 و 32 في فصلين'),
    ]),
  );
}
class PublishingScreen extends StatelessWidget {
  const PublishingScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Publishing Studio - KDP')),
    floatingActionButton: FloatingActionButton.extended(onPressed: (){}, label: Text('بناء وتصدير'), icon: Icon(Icons.publish)),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(child: Card(child: Padding(padding: EdgeInsets.all(12), child: Column(children: [Text('KDP 6x9'), SizedBox(height: 8), Text('HTML • DOCX • EPUB • PDF')])))),
      ]),
      const SizedBox(height: 16),
      const Text('صفحات البداية'),
      Wrap(spacing: 8, children: [
        ActionChip(label: Text('صفحة العنوان')), ActionChip(label: Text('الاهداء')), ActionChip(label: Text('حقوق النشر')),
      ]),
    ]),
  );
}
