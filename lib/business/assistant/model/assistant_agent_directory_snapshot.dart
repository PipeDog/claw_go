import 'assistant_agent_directory_item.dart';

/// Agent 目录页快照。
class AssistantAgentDirectorySnapshot {
  const AssistantAgentDirectorySnapshot({
    required this.items,
    required this.selectedAgentId,
    required this.selectedModelId,
    required this.selectedModelLabel,
  });

  final List<AssistantAgentDirectoryItem> items;
  final String? selectedAgentId;
  final String? selectedModelId;
  final String? selectedModelLabel;
}
