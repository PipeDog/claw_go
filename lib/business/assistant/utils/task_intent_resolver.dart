import '../model/task_quick_action.dart';

/// 根据用户输入选择更合适的快捷动作。
class TaskIntentResolver {
  const TaskIntentResolver._();

  static TaskQuickAction resolve({
    required String prompt,
    String? quickActionId,
  }) {
    if (quickActionId != null && quickActionId.isNotEmpty) {
      return TaskQuickAction.byId(quickActionId);
    }

    final String normalized = prompt.toLowerCase();
    if (normalized.contains('日志') ||
        normalized.contains('最近') ||
        normalized.contains('发生')) {
      return TaskQuickAction.byId(TaskQuickAction.recentChangesId);
    }
    if (normalized.contains('会话') ||
        normalized.contains('记录') ||
        normalized.contains('历史')) {
      return TaskQuickAction.byId(TaskQuickAction.viewHistoryId);
    }
    if (normalized.contains('状态') ||
        normalized.contains('连接') ||
        normalized.contains('网关')) {
      return TaskQuickAction.byId(TaskQuickAction.viewStatusId);
    }
    if (normalized.contains('开始') ||
        normalized.contains('上手') ||
        normalized.contains('初始化')) {
      return TaskQuickAction.byId(TaskQuickAction.startGuideId);
    }
    if (normalized.contains('修复') ||
        normalized.contains('排查') ||
        normalized.contains('设置')) {
      return TaskQuickAction.byId(TaskQuickAction.fixSetupId);
    }

    return TaskQuickAction.byId(TaskQuickAction.chatId);
  }
}
