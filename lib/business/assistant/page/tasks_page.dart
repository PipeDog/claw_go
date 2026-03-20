import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../model/assistant_task.dart';
import '../model/task_session_scope.dart';
import '../view/task_detail_view.dart';
import '../view/task_session_scope_bar_view.dart';
import '../view/task_session_table_view.dart';
import '../view_model/assistant_task_center_view_model.dart';
import '../view_model/chat_runtime_view_model.dart';

/// Sessions 页面。
///
/// 当前改为更一体化的“工作台”布局：
/// - 顶部仅保留必要摘要
/// - 中部使用单个容器承载左右联动内容
/// - 左侧会话列表与右侧详情天然保持同一上下文
class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key, required this.onOpenHome});

  final VoidCallback onOpenHome;
  static const double _kCompactWidthBreakpoint = 920;

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  TaskSessionScope _scope = TaskSessionScope.currentAgent;

  @override
  Widget build(BuildContext context) {
    final taskCenter = ref.watch(assistantTaskCenterViewModelProvider);
    final ChatRuntimeViewModel chatRuntime = ref.watch(
      chatRuntimeViewModelProvider,
    );
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String currentAgentId = chatRuntime.selectedAgentId ?? 'main';
    final String currentAgentLabel = _resolveAgentLabel(
      currentAgentId,
      chatRuntime,
    );
    final List<AssistantTask> currentAgentTasks = taskCenter.tasks
        .where((AssistantTask task) => task.agentId == currentAgentId)
        .toList();
    final List<AssistantTask> scopedTasks =
        _scope == TaskSessionScope.all ? taskCenter.tasks : currentAgentTasks;
    final AssistantTask? selectedTask = _resolveSelectedTask(
      taskCenter.selectedTask,
      scopedTasks,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact =
            constraints.maxWidth < TasksPage._kCompactWidthBreakpoint;
        final double listPanelWidth = _resolveListPanelWidth(
          constraints.maxWidth,
        );
        final double headerScopeWidth = isCompact
            ? (constraints.maxWidth - 28)
                .clamp(220.0, double.infinity)
                .toDouble()
            : (constraints.maxWidth - 220)
                .clamp(320.0, double.infinity)
                .toDouble();

        final Widget sessionListView = TaskSessionTableView(
          tasks: scopedTasks,
          selectedTaskId: selectedTask?.id,
          onSelect: (String id) {
            ref.read(assistantTaskCenterViewModelProvider).selectTask(id);
          },
        );

        final Widget detailView = TaskDetailView(
          task: selectedTask,
          canStop: taskCenter.hasRunningTask,
          onStop: () {
            ref.read(assistantTaskCenterViewModelProvider).stopCurrentTask();
          },
          onRevert:
              selectedTask == null || !taskCenter.canRevertTask(selectedTask)
                  ? null
                  : () async {
                      final AssistantTask task = selectedTask;
                      final ChatRuntimeViewModel runtimeViewModel =
                          ref.read(chatRuntimeViewModelProvider);
                      final String currentAgentId =
                          runtimeViewModel.selectedAgentId ?? 'main';
                      if (task.agentId != currentAgentId &&
                          runtimeViewModel.agents.any(
                            (item) => item.id == task.agentId,
                          )) {
                        await runtimeViewModel.selectAgent(task.agentId);
                      }
                      await ref
                          .read(assistantTaskCenterViewModelProvider)
                          .revertToTask(task.id);
                      widget.onOpenHome();
                    },
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.borderOf(context)),
                ),
                child: Column(
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      color: AppTheme.sectionMutedOf(context),
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.spaceBetween,
                        children: <Widget>[
                          SizedBox(
                            width: headerScopeWidth,
                            child: TaskSessionScopeBarView(
                              scope: _scope,
                              currentAgentLabel: currentAgentLabel,
                              currentAgentTaskCount: currentAgentTasks.length,
                              allTaskCount: taskCenter.tasks.length,
                              onScopeChanged: (TaskSessionScope value) {
                                setState(() {
                                  _scope = value;
                                });
                              },
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: widget.onOpenHome,
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                            ),
                            label: Text(l10n.text('sessions.new_chat')),
                          ),
                        ],
                      ),
                    ),
                    if (taskCenter.errorMessage != null) ...<Widget>[
                      Divider(height: 1, color: AppTheme.borderOf(context)),
                      Container(
                        width: double.infinity,
                        color: AppTheme.sectionMutedOf(context),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        child: Text(
                          taskCenter.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.danger,
                          ),
                        ),
                      ),
                    ],
                    Divider(height: 1, color: AppTheme.borderOf(context)),
                    Expanded(
                      child: isCompact
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Expanded(
                                  child: ColoredBox(
                                    color: AppTheme.sectionCanvasOf(context),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        12,
                                        12,
                                        10,
                                      ),
                                      child: sessionListView,
                                    ),
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  color: AppTheme.borderOf(context),
                                ),
                                Expanded(
                                  child: ColoredBox(
                                    color: AppTheme.sectionCanvasOf(context),
                                    child: detailView,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                SizedBox(
                                  width: listPanelWidth,
                                  child: ColoredBox(
                                    color: AppTheme.sectionCanvasOf(context),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        12,
                                        10,
                                        12,
                                      ),
                                      child: sessionListView,
                                    ),
                                  ),
                                ),
                                VerticalDivider(
                                  width: 1,
                                  thickness: 1,
                                  color: AppTheme.borderOf(context),
                                ),
                                Expanded(
                                  child: ColoredBox(
                                    color: AppTheme.sectionCanvasOf(context),
                                    child: detailView,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  AssistantTask? _resolveSelectedTask(
    AssistantTask? selectedTask,
    List<AssistantTask> scopedTasks,
  ) {
    if (selectedTask != null &&
        scopedTasks.any((AssistantTask item) => item.id == selectedTask.id)) {
      return selectedTask;
    }
    return scopedTasks.isEmpty ? null : scopedTasks.first;
  }

  String _resolveAgentLabel(
    String agentId,
    ChatRuntimeViewModel chatRuntimeViewModel,
  ) {
    for (final item in chatRuntimeViewModel.agents) {
      if (item.id == agentId) {
        return item.label;
      }
    }
    return agentId;
  }

  /// 计算左侧会话列表面板宽度。
  ///
  /// 左侧列表不再使用纯 flex 比例，而是给一个更稳定的实际宽度，
  /// 这样桌面端阅读体验更接近“导航列表 + 内容详情”的经典工作台结构。
  double _resolveListPanelWidth(double availableWidth) {
    final double preferredWidth = availableWidth * 0.26;
    return preferredWidth.clamp(260, 340).toDouble();
  }
}
