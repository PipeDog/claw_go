/// 对话消息角色。
enum AssistantChatMessageRole {
  user,
  assistant,
}

/// 对话消息展示状态。
enum AssistantChatMessageState {
  loading,
  success,
  failed,
}

/// 对话消息实体。
///
/// 仅用于聊天列表展示，因此只保留用户与 OpenClaw 两种角色，
/// 不把状态、告警等过程性文本混入消息流。
class AssistantChatMessage {
  const AssistantChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.state = AssistantChatMessageState.success,
  });

  final String id;
  final AssistantChatMessageRole role;
  final String content;
  final DateTime createdAt;
  final AssistantChatMessageState state;

  factory AssistantChatMessage.fromJson(Map<String, dynamic> json) {
    return AssistantChatMessage(
      id: json['id'] as String? ?? '',
      role: AssistantChatMessageRole.values.firstWhere(
        (AssistantChatMessageRole item) => item.name == json['role'],
        orElse: () => AssistantChatMessageRole.assistant,
      ),
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      state: AssistantChatMessageState.values.firstWhere(
        (AssistantChatMessageState item) => item.name == json['state'],
        orElse: () => AssistantChatMessageState.success,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'role': role.name,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'state': state.name,
    };
  }

  AssistantChatMessage copyWith({
    String? id,
    AssistantChatMessageRole? role,
    String? content,
    DateTime? createdAt,
    AssistantChatMessageState? state,
  }) {
    return AssistantChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      state: state ?? this.state,
    );
  }
}
