import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/project.dart';
import '../models/outline_result.dart';

class ProjectApiException implements Exception {
  final String message;
  const ProjectApiException(this.message);
  @override
  String toString() => message;
}

class ProjectApi {
  const ProjectApi();
  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<List<NovelProject>> fetchProjects() async {
    final r = await http.get(_uri('/v1/projects')).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) throw ProjectApiException('Could not load projects (${r.statusCode}).');
    final data = jsonDecode(r.body);
    if (data is! List) throw const ProjectApiException('Unexpected projects response.');
    return data.map((e) => NovelProject.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<NovelProject> createProject({required String title, required String language,
      String? genre, String? premise}) async {
    final r = await http.post(_uri('/v1/projects'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title.trim(), 'language': language,
        'genre': _nullIfEmpty(genre), 'premise': _nullIfEmpty(premise)}))
      .timeout(const Duration(seconds: 20));
    if (r.statusCode != 201) throw ProjectApiException(_detail(r, 'Could not create project'));
    return NovelProject.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<OutlineResult> generateOutline({required String projectId,
      required int targetChapters, required int targetWords, String? instructions}) async {
    final r = await http.post(_uri('/v1/projects/$projectId/generate-outline'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'target_chapters': targetChapters, 'target_words': targetWords,
        'additional_instructions': _nullIfEmpty(instructions)}))
      .timeout(const Duration(minutes: 4));
    if (r.statusCode != 200) throw ProjectApiException(_detail(r, 'Outline generation failed'));
    return OutlineResult.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  String _detail(http.Response r, String fallback) {
    try { final j = jsonDecode(r.body); if (j is Map && j['detail'] != null) return j['detail'].toString(); }
    catch (_) {}
    return '$fallback (${r.statusCode}).';
  }
  String? _nullIfEmpty(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
}
