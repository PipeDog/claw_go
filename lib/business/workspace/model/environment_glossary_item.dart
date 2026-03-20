/// OpenClaw Environment 术语来源。
enum EnvironmentGlossarySourceType {
  clawGo,
  openClaw,
  mixed,
}

/// Environment 术语说明项。
class EnvironmentGlossaryItem {
  const EnvironmentGlossaryItem({
    required this.id,
    required this.termKey,
    required this.descriptionKey,
    required this.mappingKey,
    required this.sourceType,
  });

  final String id;
  final String termKey;
  final String descriptionKey;
  final String mappingKey;
  final EnvironmentGlossarySourceType sourceType;
}
