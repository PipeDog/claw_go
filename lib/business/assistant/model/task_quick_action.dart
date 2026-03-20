import '../../../component/openclaw_runtime/model/openclaw_command_preset.dart';

/// 面向普通用户的快捷动作。
///
/// 每个动作都对应一个更自然的文案，并映射到底层 OpenClaw 命令预设。
class TaskQuickAction {
  const TaskQuickAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.prompt,
    required this.presetId,
  });

  final String id;
  final String title;
  final String subtitle;
  final String prompt;
  final String presetId;

  static const String chatId = 'chat';
  static const String checkReadyId = 'check_ready';
  static const String viewStatusId = 'view_status';
  static const String recentChangesId = 'recent_changes';
  static const String viewHistoryId = 'view_history';
  static const String startGuideId = 'start_guide';
  static const String fixSetupId = 'fix_setup';

  static const List<TaskQuickAction> values = <TaskQuickAction>[
    TaskQuickAction(
      id: chatId,
      title: '直接和 OpenClaw 聊天',
      subtitle: '发送一个问题，让 OpenClaw 直接回复。',
      prompt: '你是谁',
      presetId: OpenClawCommandPreset.agentChatId,
    ),
    TaskQuickAction(
      id: checkReadyId,
      title: '帮我检查是否可以开始使用',
      subtitle: '快速检查当前环境是否就绪。',
      prompt: '帮我检查一下现在是否已经准备好可以使用了',
      presetId: OpenClawCommandPreset.healthId,
    ),
    TaskQuickAction(
      id: viewStatusId,
      title: '看看当前运行状态',
      subtitle: '查看当前连接、服务和网关状态。',
      prompt: '帮我看看现在的运行状态',
      presetId: OpenClawCommandPreset.gatewayStatusId,
    ),
    TaskQuickAction(
      id: recentChangesId,
      title: '看看最近发生了什么',
      subtitle: '查看最近日志和系统变化。',
      prompt: '帮我看看最近发生了什么',
      presetId: OpenClawCommandPreset.logsId,
    ),
    TaskQuickAction(
      id: viewHistoryId,
      title: '查看当前记录',
      subtitle: '查看会话或历史记录情况。',
      prompt: '帮我查看当前的记录和会话',
      presetId: OpenClawCommandPreset.sessionsId,
    ),
    TaskQuickAction(
      id: startGuideId,
      title: '带我开始使用',
      subtitle: '适合第一次上手，执行引导流程。',
      prompt: '带我开始使用并完成初始化',
      presetId: OpenClawCommandPreset.onboardId,
    ),
    TaskQuickAction(
      id: fixSetupId,
      title: '帮我排查设置问题',
      subtitle: '先做检查，再定位当前设置问题。',
      prompt: '帮我排查一下设置问题',
      presetId: OpenClawCommandPreset.healthId,
    ),
  ];

  static TaskQuickAction byId(String id) {
    return values.firstWhere(
      (TaskQuickAction item) => item.id == id,
      orElse: () => values.first,
    );
  }
}
