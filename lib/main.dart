import 'package:flutter/material.dart';

void main() => runApp(const NovelApp());

class NovelApp extends StatelessWidget {
  const NovelApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Publishing Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: 【entity-Colors¦canonical_name=Colors】.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novel Publishing Studio'), centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('روايتي الأولى', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('منصة كتابة الروايات - KDP جاهز'),
            const Text('وهران - Oran'),
          ]))),
        const SizedBox(height: 16),
        _tile(context, Icons.auto_awesome, 'Story Architect', 'توليد مخطط 24 فصل', const ArchitectScreen()),
        _tile(context, Icons.psychology, 'Story Intelligence', 'الشخصيات والحقائق والتناقضات', const IntelligenceScreen()),
        _tile(context, Icons.menu_book, 'Publishing Studio', 'العنوان، الإهداء، الفهرس، تصدير KDP', const PublishingScreen(), color: Colors.deepPurple),
      ]),
    );
  }
  Widget _tile(BuildContext ctx, IconData icon, String title, String sub, Widget screen, {Color? color}) {
    return Card(margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: (color??Colors.deepPurple).withOpacity(0.15), child: Icon(icon, color: color??Colors.deepPurple)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen)),
      ));
  }
}

class ArchitectScreen extends StatelessWidget {
  const ArchitectScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Story Architect')),
    body: ListView(padding: const EdgeInsets.all(16), children: const [
      Text('توليد مخطط الرواية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      SizedBox(height: 16),
      Card(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('الهدف: 24 فصل - 80,000 كلمة'),
        SizedBox(height: 8),
        Text('النمط: رواية عربية - وهران'),
        SizedBox(height: 12),
        Text('سيتم توليد المخطط عبر API الخاص بك'),
      ]))),
    ]),
  );
}

class IntelligenceScreen extends StatelessWidget {
  const IntelligenceScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Story Intelligence')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Wrap(spacing: 8, children: [
        Chip(label: Text('Characters: 12')), Chip(label: Text('Facts: 45')), Chip(label: Text('Events: 28')),
      ]),
      const SizedBox(height: 16),
      const Card(color: Color(0xFFFFEBEE), child: Padding(padding: EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('تناقضات محتملة', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('الشخصية: أحمد / العمر: 30 و 32 سنة في فصلين مختلفين'),
        ]))),
      const SizedBox(height: 16),
      const Text('الشخصيات', style: TextStyle(fontWeight: FontWeight.bold)),
      const Card(child: ListTile(leading: CircleAvatar(child: Icon(Icons.person)), title: Text('أحمد'), subtitle: Text('البطل - 30 سنة'))),
      const Card(child: ListTile(leading: CircleAvatar(child: Icon(Icons.person)), title: Text('ليلى'), subtitle: Text('الصديقة'))),
    ]),
  );
}

class PublishingScreen extends StatelessWidget {
  const PublishingScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Publishing Studio - KDP')),
    floatingActionButton: FloatingActionButton.extended(onPressed: (){}, label: const Text('بناء وتصدير'), icon: const Icon(Icons.publish)),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ملفات KDP', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('1 ملف - 6x9'),
            const SizedBox(height: 8),
            FilledButton(onPressed: (){}, child: const Text('إنشاء ملف KDP جديد')),
          ])))),
        const SizedBox(width: 8),
        const Expanded(child: Card(child: Padding(padding: EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('البناء', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('HTML • DOCX • EPUB • PDF'),
          ])))),
      ]),
      const SizedBox(height: 16),
      const Text('صفحات البداية', style: TextStyle(fontWeight: FontWeight.bold)),
      Wrap(spacing: 8, children: [
        ActionChip(label: Text('صفحة العنوان'), onPressed: (){}),
        ActionChip(label: Text('الإهداء'), onPressed: (){}),
        ActionChip(label: Text('حقوق النشر'), onPressed: (){}),
      ]),
      const SizedBox(height: 16),
      const Card(child: Padding(padding: EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('فحص ما قبل النشر - Preflight', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('• عدد الصفحات 24-828 ✅'),
        Text('• الهوامش KDP 0.375" ✅'),
        Text('• دقة الصور 300 DPI'),
        Text('• TOC قابل للنقر'),
        Text('• RTL للعربية ✅'),
      ]))),
    ]),
  );
}
