import 'assistant_chat_message.dart';

/// 用户任务状态。
enum AssistantTaskStatus {
  running,
  completed,
  failed,
  stopped,
}

/// 面向用户展示的任务实体。
class AssistantTask {
  const AssistantTask({
    required this.id,
    required this.title,
    required this.prompt,
    required this.agentId,
    required this.chatSessionKey,
    required this.quickActionId,
    required this.commandLabel,
    required this.profileName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.transcript,
    required this.chatMessages,
    this.revertToTaskId,
    this.summary,
    this.failureMessage,
  });

  final String id;
  final String title;
  final String prompt;
  final String agentId;
  final String chatSessionKey;
  final String quickActionId;
  final String commandLabel;
  final String profileName;
  final AssistantTaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> transcript;
  final List<AssistantChatMessage> chatMessages;
  final String? revertToTaskId;
  final String? summary;
  final String? failureMessage;

  factory AssistantTask.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawTranscript =
        json['transcript'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawChatMessages =
        json['chat_messages'] as List<dynamic>? ?? <dynamic>[];
    final DateTime createdAt =
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now();
    final DateTime updatedAt =
        DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.now();
    final List<String> transcript =
        rawTranscript.map((dynamic item) => item.toString()).toList();
    final List<AssistantChatMessage> chatMessages = rawChatMessages
        .whereType<Map<String, dynamic>>()
        .map(AssistantChatMessage.fromJson)
        .toList();

    return AssistantTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      agentId: json['agent_id'] as String? ?? 'main',
      chatSessionKey: json['chat_session_key'] as String? ??
          json['agent_id'] as String? ??
          'main',
      quickActionId: json['quick_action_id'] as String? ?? '',
      commandLabel: json['command_label'] as String? ?? '',
      profileName: json['profile_name'] as String? ?? '',
      status: AssistantTaskStatus.values.firstWhere(
        (AssistantTaskStatus item) => item.name == json['status'],
        orElse: () => AssistantTaskStatus.completed,
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
      transcript: transcript,
      chatMessages: chatMessages.isEmpty
          ? _migrateChatMessages(
              prompt: json['prompt'] as String? ?? '',
              transcript: transcript,
              createdAt: createdAt,
              updatedAt: updatedAt,
            )
          : chatMessages,
      revertToTaskId: json['revert_to_task_id'] as String?,
      summary: json['summary'] as String?,
      failureMessage: json['failure_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'prompt': prompt,
      'agent_id': agentId,
      'chat_session_key': chatSessionKey,
      'quick_action_id': quickActionId,
      'command_label': commandLabel,
      'profile_name': profileName,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'transcript': transcript,
      'chat_messages': chatMessages
          .map((AssistantChatMessage item) => item.toJson())
          .toList(),
      'revert_to_task_id': revertToTaskId,
      'summary': summary,
      'failure_message': failureMessage,
    };
  }

  AssistantTask copyWith({
    String? id,
    String? title,
    String? prompt,
    String? agentId,
    String? chatSessionKey,
    String? quickActionId,
    String? commandLabel,
    String? profileName,
    AssistantTaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? transcript,
    List<AssistantChatMessage>? chatMessages,
    String? revertToTaskId,
    String? summary,
    String? failureMessage,
    bool clearRevertToTaskId = false,
    bool clearFailureMessage = false,
  }) {
    return AssistantTask(
      id: id ?? this.id,
      title: title ?? this.title,
      prompt: prompt ?? this.prompt,
      agentId: agentId ?? this.agentId,
      chatSessionKey: chatSessionKey ?? this.chatSessionKey,
      quickActionId: quickActionId ?? this.quickActionId,
      commandLabel: commandLabel ?? this.commandLabel,
      profileName: profileName ?? this.profileName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transcript: transcript ?? this.transcript,
      chatMessages: chatMessages ?? this.chatMessages,
      revertToTaskId:
          clearRevertToTaskId ? null : revertToTaskId ?? this.revertToTaskId,
      summary: summary ?? this.summary,
      failureMessage:
          clearFailureMessage ? null : failureMessage ?? this.failureMessage,
    );
  }

  static List<AssistantChatMessage> _migrateChatMessages({
    required String prompt,
    required List<String> transcript,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    final List<AssistantChatMessage> messages = <AssistantChatMessage>[];
    final String trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isNotEmpty) {
      messages.add(
        AssistantChatMessage(
          id: 'legacy-user-$createdAt',
          role: AssistantChatMessageRole.user,
          content: trimmedPrompt,
          createdAt: createdAt,
        ),
      );
    }

    for (final String line in transcript) {
      final String trimmedLine = line.trim();
      if (trimmedLine.isEmpty ||
          trimmedLine.startsWith('状态：') ||
          trimmedLine.startsWith('提醒：') ||
          trimmedLine.startsWith('已收到你的任务：') ||
          trimmedLine.startsWith('正在为你准备运行环境') ||
          trimmedLine.startsWith('已为你选择动作：') ||
          trimmedLine.startsWith('开始执行：') ||
          trimmedLine.startsWith('任务已手动停止。') ||
          trimmedLine.startsWith('系统已停止上一个任务')) {
        continue;
      }
      messages.add(
        AssistantChatMessage(
          id: 'legacy-assistant-${messages.length}-$updatedAt',
          role: AssistantChatMessageRole.assistant,
          content: trimmedLine,
          createdAt: updatedAt,
        ),
      );
    }
    return messages;
  }
}
