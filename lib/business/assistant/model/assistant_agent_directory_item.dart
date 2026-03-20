/// Agent 资产条目。
///
/// 该模型用于承接 Agent 列表页所需的核心信息，
/// 目标是把原始配置中的分散字段整理成更适合产品展示的结构。
class AssistantAgentDirectoryItem {
  const AssistantAgentDirectoryItem({
    required this.id,
    required this.name,
    required this.displayLabel,
    required this.workspace,
    required this.modelId,
    required this.modelLabel,
    required this.isDefault,
    required this.isSelected,
    this.description,
  });

  final String id;
  final String name;
  final String displayLabel;
  final String workspace;
  final String modelId;
  final String modelLabel;
  final bool isDefault;
  final bool isSelected;
  final String? description;
}
