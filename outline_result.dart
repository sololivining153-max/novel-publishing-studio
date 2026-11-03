class OutlineResult {
  final String jobId, projectId, status, model, promptVersion, outline;
  const OutlineResult({required this.jobId, required this.projectId, required this.status,
    required this.model, required this.promptVersion, required this.outline});
  factory OutlineResult.fromJson(Map<String, dynamic> j) => OutlineResult(
    jobId: j['job_id'] as String, projectId: j['project_id'] as String,
    status: j['status'] as String, model: j['model'] as String,
    promptVersion: j['prompt_version'] as String, outline: j['outline'] as String);
}
