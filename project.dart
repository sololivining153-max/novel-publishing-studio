class NovelProject {
  final String id, title, language, status;
  final String? genre, premise;
  const NovelProject({required this.id, required this.title, required this.language,
    required this.status, this.genre, this.premise});
  factory NovelProject.fromJson(Map<String, dynamic> json) => NovelProject(
    id: json['id'] as String, title: json['title'] as String,
    language: (json['language'] as String?) ?? 'en',
    status: (json['status'] as String?) ?? 'planning',
    genre: json['genre'] as String?, premise: json['premise'] as String?,
  );
}
