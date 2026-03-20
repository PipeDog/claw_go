import 'chat_runtime_option.dart';

/// 聊天运行配置快照。
class ChatRuntimeConfig {
  const ChatRuntimeConfig({
    required this.agents,
    required this.models,
    required this.selectedAgentId,
    required this.selectedModelId,
  });

  final List<ChatRuntimeOption> agents;
  final List<ChatRuntimeOption> models;
  final String? selectedAgentId;
  final String? selectedModelId;
}
