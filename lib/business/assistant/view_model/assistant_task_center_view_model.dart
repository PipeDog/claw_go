import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../component/openclaw_runtime/model/openclaw_profile.dart';
import '../../../component/openclaw_runtime/model/openclaw_session.dart';
import '../../../component/openclaw_runtime/model/runtime_launch_result.dart';
import '../../../component/openclaw_runtime/model/terminal_event.dart';
import '../../../component/openclaw_runtime/utils/command_parser.dart';
import '../../../foundation/base/base_view_model.dart';
import '../../../foundation/utils/id_generator.dart';
import '../../onboarding/repository/onboarding_repository.dart';
import '../../session/repository/session_repository.dart';
import '../../workspace/repository/workspace_repository.dart';
import '../model/assistant_chat_message.dart';
import '../model/assistant_task.dart';
import '../model/task_quick_action.dart';
import '../repository/assistant_task_repository.dart';
import '../utils/task_intent_resolver.dart';

/// 首页和任务页共享的任务中心 ViewModel。
final assistantTaskCenterViewModelProvider =
    ChangeNotifierProvider<AssistantTaskCenterViewModel>((Ref ref) {
  return AssistantTaskCenterViewModel(
    taskRepository: ref.watch(assistantTaskRepositoryProvider),
    sessionRepository: ref.watch(sessionRepositoryProvider),
    workspaceRepository: ref.watch(workspaceRepositoryProvider),
    onboardingRepository: ref.watch(onboardingRepositoryProvider),
  );
});

class AssistantTaskCenterViewModel extends BaseViewModel {
  AssistantTaskCenterViewModel({
    required AssistantTaskRepository taskRepository,
    required SessionRepository sessionRepository,
    required WorkspaceRepository workspaceRepository,
    required OnboardingRepository onboardingRepository,
  })  : _taskRepository = taskRepository,
        _sessionRepository = sessionRepository,
        _workspaceRepository = workspaceRepository,
        _onboardingRepository = onboardingRepository {
    unawaited(_loadInitialState());
  }

  final AssistantTaskRepository _taskRepository;
  final SessionRepository _sessionRepository;
  final WorkspaceRepository _workspaceRepository;
  final OnboardingRepository _onboardingRepository;

  final List<AssistantTask> _tasks = <AssistantTask>[];
  final Set<String> _favoriteActionIds = <String>{};
  final Map<String, String> _activeChatSessionKeyByAgent = <String, String>{};
  final Map<String, String> _pendingRevertTargetTaskIdByAgent =
      <String, String>{};
  StreamSubscription<TerminalEvent>? _subscription;
  OpenClawSession? _currentSession;
  String? _currentTaskId;
  String? _selectedTaskId;

  List<AssistantTask> get tasks => List<AssistantTask>.unmodifiable(_tasks);
  List<TaskQuickAction> get quickActions {
    final List<TaskQuickAction> favorites = TaskQuickAction.values
        .where((TaskQuickAction item) => _favoriteActionIds.contains(item.id))
        .toList();
    final List<TaskQuickAction> others = TaskQuickAction.values
        .where((TaskQuickAction item) => !_favoriteActionIds.contains(item.id))
        .toList();
    return <TaskQuickAction>[...favorites, ...others];
  }

  AssistantTask? get selectedTask {
    for (final AssistantTask task in _tasks) {
      if (task.id == _selectedTaskId) {
        return task;
      }
    }
    return _tasks.isEmpty ? null : _tasks.first;
  }

  bool get hasTasks => _tasks.isNotEmpty;
  bool get hasRunningTask => _currentTaskId != null;

  List<AssistantTask> recentTasks({int limit = 10}) {
    return List<AssistantTask>.unmodifiable(_tasks.take(limit));
  }

  AssistantTask? findTaskById(String id) {
    return _taskById(id);
  }

  List<AssistantTask> chatTasksForAgent({required String agentId}) {
    final String normalizedAgentId = _normalizeAgentId(agentId);
    // 聊天区展示的不是“所有历史任务”，
    // 而是“当前 Agent 所在活跃分支可见的那一段聊天链路”。
    return List<AssistantTask>.unmodifiable(
      _resolveVisibleChatTasks(
        agentId: normalizedAgentId,
        sessionKey: resolveActiveChatSessionKey(agentId: normalizedAgentId),
      ),
    );
  }

  List<AssistantChatMessage> chatMessagesForAgent({required String agentId}) {
    // 一个聊天分支由多个任务节点串起来，
    // UI 真正需要的是合并后的消息流，因此这里把任务级消息打平并按时间排序。
    final List<AssistantChatMessage> messages = chatTasksForAgent(
      agentId: agentId,
    ).expand((AssistantTask task) => task.chatMessages).toList();
    messages.sort(
      (AssistantChatMessage left, AssistantChatMessage right) =>
          left.createdAt.compareTo(right.createdAt),
    );
    return List<AssistantChatMessage>.unmodifiable(messages);
  }

  AssistantTask? chatRevertTargetForAgent({required String agentId}) {
    final String normalizedAgentId = _normalizeAgentId(agentId);
    final String? pendingTaskId =
        _pendingRevertTargetTaskIdByAgent[normalizedAgentId];
    if (pendingTaskId != null) {
      // 如果用户刚执行了“回退”，但还没发送新消息，
      // 那么优先展示这次待生效回退的锚点任务。
      return _taskById(pendingTaskId);
    }

    final String sessionKey =
        resolveActiveChatSessionKey(agentId: normalizedAgentId);
    final List<AssistantTask> currentSessionTasks = _tasks
        .where(
          (AssistantTask task) =>
              _isChatTask(task) &&
              task.agentId == normalizedAgentId &&
              task.chatSessionKey == sessionKey,
        )
        .toList()
      ..sort(
        (AssistantTask left, AssistantTask right) =>
            left.createdAt.compareTo(right.createdAt),
      );
    if (currentSessionTasks.isEmpty) {
      return null;
    }

    // 当前分支的第一条任务如果记录了 revertToTaskId，
    // 就表示这条分支是从某个旧会话“切”出来的。
    final AssistantTask firstTask = currentSessionTasks.first;
    if (firstTask.revertToTaskId == null) {
      return null;
    }
    return _taskById(firstTask.revertToTaskId!);
  }

  bool canRevertTask(AssistantTask task) {
    return _isChatTask(task);
  }

  bool isFavoriteAction(String actionId) {
    return _favoriteActionIds.contains(actionId);
  }

  Future<void> _loadInitialState() async {
    try {
      final List<AssistantTask> storedTasks = await _taskRepository.loadTasks();
      final Set<String> favoriteActionIds =
          await _taskRepository.loadFavoriteActionIds();
      _tasks
        ..clear()
        ..addAll(_sortTasks(storedTasks));
      _favoriteActionIds
        ..clear()
        ..addAll(favoriteActionIds);
      _restoreChatSessionSelections();
      _selectedTaskId = _tasks.isEmpty ? null : _tasks.first.id;
      notifyListeners();
    } catch (error) {
      setErrorMessage('加载任务历史失败：$error');
    }
  }

  Future<bool> submitPrompt({
    required String prompt,
    String? quickActionId,
    String? chatAgentId,
    String? chatSessionKey,
  }) async {
    final String trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      setErrorMessage('先告诉我你想完成什么任务。');
      return false;
    }

    setLoading(true);
    clearError();

    final TaskQuickAction action = TaskIntentResolver.resolve(
      prompt: trimmedPrompt,
      quickActionId: quickActionId,
    );
    final String resolvedAgentId = _normalizeAgentId(chatAgentId);
    final String resolvedChatSessionKey = action.id == TaskQuickAction.chatId
        ? _resolveChatSessionKeyForSubmit(
            agentId: resolvedAgentId,
            explicitSessionKey: chatSessionKey,
          )
        : _normalizeChatSessionKey(
            chatSessionKey: chatSessionKey,
            fallbackAgentId: resolvedAgentId,
          );
    final String? revertToTaskId = action.id == TaskQuickAction.chatId
        ? _pendingRevertTargetTaskIdByAgent.remove(resolvedAgentId)
        : null;

    // 新任务开始前，统一先停止上一个运行中的任务。
    // 这样可以避免多个会话同时向同一个 UI 状态流写入事件。
    await _stopRunningTaskBeforeStartingNext();

    final AssistantTask task = AssistantTask(
      id: IdGenerator.next('task'),
      title: _buildTaskTitle(trimmedPrompt, action),
      prompt: trimmedPrompt,
      agentId: resolvedAgentId,
      chatSessionKey: resolvedChatSessionKey,
      quickActionId: action.id,
      commandLabel: action.title,
      profileName: '正在准备',
      status: AssistantTaskStatus.running,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      transcript: <String>[
        '已收到你的任务：$trimmedPrompt',
        '正在为你准备运行环境...',
      ],
      chatMessages: <AssistantChatMessage>[
        AssistantChatMessage(
          id: IdGenerator.next('chat'),
          role: AssistantChatMessageRole.user,
          content: trimmedPrompt,
          createdAt: DateTime.now(),
        ),
        AssistantChatMessage(
          id: IdGenerator.next('chat'),
          role: AssistantChatMessageRole.assistant,
          content: '',
          createdAt: DateTime.now(),
          state: AssistantChatMessageState.loading,
        ),
      ],
      revertToTaskId: revertToTaskId,
      summary: '正在处理...',
    );

    if (action.id == TaskQuickAction.chatId) {
      // 聊天任务会把当前 Agent 的“活跃分支”切换到本次会话键上，
      // 后续聊天区就会围绕这条分支继续展开。
      _activeChatSessionKeyByAgent[resolvedAgentId] = resolvedChatSessionKey;
    }
    _upsertTask(task, select: true);

    try {
      final OpenClawProfile? profile = await _ensureUsableProfile();
      if (profile == null) {
        _markTaskFailed(
          task.id,
          message: '暂时无法自动完成准备，请前往“设置 > 高级工具 > 开始使用”完成准备。',
        );
        setErrorMessage('暂时无法自动准备环境，请稍后在高级工具里完成设置。');
        return false;
      }

      await _subscription?.cancel();
      _subscription = null;
      final String runtimeCustomArgs = _buildRuntimeCustomArgs(
        baseArgs: profile.customArgs,
        prompt: trimmedPrompt,
        action: action,
      );
      final RuntimeLaunchResult launchResult;
      if (action.id == TaskQuickAction.chatId) {
        launchResult = await _sessionRepository.startGatewayChat(
          profile: profile,
          message: trimmedPrompt,
          sessionKey: resolvedChatSessionKey,
        );
      } else {
        final OpenClawProfile runtimeProfile = profile.copyWith(
          commandPresetId: action.presetId,
          customArgs: runtimeCustomArgs,
        );
        launchResult = await _sessionRepository.start(runtimeProfile);
      }
      _currentSession = launchResult.session;
      _currentTaskId = task.id;

      _replaceTask(
        task.id,
        task.copyWith(
          profileName: profile.name,
          transcript: <String>[
            ...task.transcript,
            '已为你选择动作：${action.title}',
            '开始执行：${launchResult.session.commandLabel}',
          ],
          updatedAt: DateTime.now(),
        ),
      );

      _subscription = _sessionRepository.listen(
        launchResult,
        (TerminalEvent event) => _handleTaskEvent(task.id, event),
      );
      return true;
    } catch (error) {
      _markTaskFailed(task.id, message: '执行失败：$error');
      setErrorMessage('这次任务没有完成，请稍后重试或检查高级工具中的设置。');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> stopCurrentTask() async {
    final OpenClawSession? session = _currentSession;
    final String? currentTaskId = _currentTaskId;
    if (session == null || currentTaskId == null) {
      return;
    }

    await _subscription?.cancel();
    _subscription = null;
    await _sessionRepository.stop(session);
    final AssistantTask? currentTask = _taskById(currentTaskId);
    if (currentTask == null) {
      _currentSession = null;
      _currentTaskId = null;
      await _saveState();
      return;
    }

    _replaceTask(
      currentTaskId,
      currentTask.copyWith(
        status: AssistantTaskStatus.stopped,
        transcript: <String>[
          ...currentTask.transcript,
          '任务已手动停止。',
        ],
        summary: '任务已停止',
        updatedAt: DateTime.now(),
      ),
    );
    _currentSession = null;
    _currentTaskId = null;
    await _saveState();
  }

  void selectTask(String id) {
    _selectedTaskId = id;
    notifyListeners();
  }

  void openTaskInChat(String id) {
    final AssistantTask? task = _taskById(id);
    if (task == null) {
      return;
    }
    _selectedTaskId = id;
    if (_isChatTask(task)) {
      // 从“最近会话”点击进入聊天时，
      // 本质上是在切换当前 Agent 的活跃分支。
      _activeChatSessionKeyByAgent[task.agentId] = task.chatSessionKey;
      _pendingRevertTargetTaskIdByAgent.remove(task.agentId);
    }
    notifyListeners();
  }

  Future<void> revertToTask(String id) async {
    final AssistantTask? task = _taskById(id);
    if (task == null || !_isChatTask(task)) {
      return;
    }

    // 回退不是直接改写旧任务，而是新建一条“分支会话键”。
    // 这样旧历史仍然完整保留，同时新消息会从指定锚点继续往后长。
    _selectedTaskId = task.id;
    _activeChatSessionKeyByAgent[task.agentId] =
        IdGenerator.next('chat-branch');
    _pendingRevertTargetTaskIdByAgent[task.agentId] = task.id;
    notifyListeners();
  }

  Future<void> toggleFavoriteAction(String actionId) async {
    if (_favoriteActionIds.contains(actionId)) {
      _favoriteActionIds.remove(actionId);
    } else {
      _favoriteActionIds.add(actionId);
    }
    await _saveState();
    notifyListeners();
  }

  void _handleTaskEvent(String taskId, TerminalEvent event) {
    final AssistantTask? task = _taskById(taskId);
    if (task == null) {
      return;
    }

    // transcript 保留完整过程文本；chatMessages 只保留真正的对话消息。
    // 两者分离后，聊天区和任务详情页就能各取所需。
    final String prefix = switch (event.type) {
      TerminalEventType.stdout => '',
      TerminalEventType.stderr => '提醒：',
      TerminalEventType.status => '状态：',
    };
    final List<String> nextTranscript = <String>[
      ...task.transcript,
      '$prefix${event.data}',
    ];
    final List<AssistantChatMessage> nextChatMessages =
        List<AssistantChatMessage>.from(task.chatMessages);

    AssistantTaskStatus nextStatus = task.status;
    String? failureMessage = task.failureMessage;
    String summary = _buildSummary(nextTranscript, task.summary);

    if (event.type == TerminalEventType.stdout) {
      // 仅 stdout 进入聊天消息流；
      // status / stderr 属于过程信息，不混入聊天对话本身。
      final String content = event.data.trim();
      if (content.isNotEmpty) {
        _upsertAssistantResponseMessage(
          nextChatMessages,
          content: content,
          createdAt: event.timestamp,
          state: AssistantChatMessageState.loading,
        );
      }
    }

    if (event.type == TerminalEventType.status && event.data.contains('退出码：')) {
      // 运行结束的判定依赖退出码，
      // 一旦捕获到退出码，就同时回收当前运行会话状态。
      final int? exitCode = _extractExitCode(event.data);
      nextStatus = exitCode == null || exitCode == 0
          ? AssistantTaskStatus.completed
          : AssistantTaskStatus.failed;
      summary =
          nextStatus == AssistantTaskStatus.completed ? '任务已完成' : '任务未成功完成';
      if (nextStatus == AssistantTaskStatus.failed) {
        failureMessage = event.data;
        _upsertAssistantResponseMessage(
          nextChatMessages,
          content: event.data.trim(),
          createdAt: event.timestamp,
          state: AssistantChatMessageState.failed,
        );
      } else {
        _finalizePendingAssistantMessage(nextChatMessages);
      }
      _currentSession = null;
      _currentTaskId = null;
    }

    _replaceTask(
      taskId,
      task.copyWith(
        status: nextStatus,
        transcript: nextTranscript,
        chatMessages: nextChatMessages,
        summary: summary,
        failureMessage: failureMessage,
        updatedAt: DateTime.now(),
      ),
    );
    unawaited(_saveState());
  }

  Future<OpenClawProfile?> _ensureUsableProfile() async {
    final List<OpenClawProfile> profiles =
        await _workspaceRepository.loadProfiles();
    final OpenClawProfile? defaultProfile = _findDefaultProfile(profiles);
    if (defaultProfile != null) {
      return defaultProfile;
    }

    final detection = await _onboardingRepository.detectEnvironment();
    if (detection.primaryCliPath == null) {
      return null;
    }

    final OpenClawProfile imported = OpenClawProfile.fromDetection(
      id: IdGenerator.next('profile'),
      detection: detection,
    );
    await _workspaceRepository.saveProfiles(<OpenClawProfile>[imported]);
    return imported;
  }

  OpenClawProfile? _findDefaultProfile(List<OpenClawProfile> profiles) {
    for (final OpenClawProfile profile in profiles) {
      if (profile.isDefault) {
        return profile;
      }
    }
    return profiles.isEmpty ? null : profiles.first;
  }

  String _buildTaskTitle(String prompt, TaskQuickAction action) {
    final String compactPrompt = prompt.replaceAll('\n', ' ').trim();
    if (compactPrompt.length <= 18) {
      return compactPrompt;
    }
    return '${action.title} · ${compactPrompt.substring(0, 18)}…';
  }

  String _buildRuntimeCustomArgs({
    required String baseArgs,
    required String prompt,
    required TaskQuickAction action,
  }) {
    final String trimmedBaseArgs = baseArgs.trim();
    if (action.id != TaskQuickAction.chatId) {
      return trimmedBaseArgs;
    }

    final String messageArgument =
        '--message ${CommandParser.quoteArgument(prompt)}';
    if (trimmedBaseArgs.isEmpty) {
      return messageArgument;
    }
    return '$trimmedBaseArgs $messageArgument';
  }

  String _buildSummary(List<String> transcript, String? currentSummary) {
    for (int index = transcript.length - 1; index >= 0; index -= 1) {
      final String line = transcript[index].trim();
      if (line.isEmpty) {
        continue;
      }
      if (line.startsWith('状态：')) {
        continue;
      }
      return line;
    }
    return currentSummary ?? '任务处理中';
  }

  int? _extractExitCode(String value) {
    final Match? match = RegExp(r'(\d+)$').firstMatch(value);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1) ?? '');
  }

  void _markTaskFailed(String taskId, {required String message}) {
    final AssistantTask? task = _taskById(taskId);
    if (task == null) {
      return;
    }
    final List<AssistantChatMessage> nextChatMessages =
        List<AssistantChatMessage>.from(task.chatMessages);
    _upsertAssistantResponseMessage(
      nextChatMessages,
      content: message,
      createdAt: DateTime.now(),
      state: AssistantChatMessageState.failed,
    );
    _replaceTask(
      taskId,
      task.copyWith(
        status: AssistantTaskStatus.failed,
        transcript: <String>[...task.transcript, message],
        chatMessages: nextChatMessages,
        summary: '任务未成功完成',
        failureMessage: message,
        updatedAt: DateTime.now(),
      ),
    );
    unawaited(_saveState());
  }

  void _upsertAssistantResponseMessage(
    List<AssistantChatMessage> messages, {
    required String content,
    required DateTime createdAt,
    required AssistantChatMessageState state,
  }) {
    if (messages.isEmpty) {
      messages.add(
        AssistantChatMessage(
          id: IdGenerator.next('chat'),
          role: AssistantChatMessageRole.assistant,
          content: content,
          createdAt: createdAt,
          state: state,
        ),
      );
      return;
    }

    final int index = messages.lastIndexWhere(
      (AssistantChatMessage item) =>
          item.role == AssistantChatMessageRole.assistant &&
          (item.state == AssistantChatMessageState.loading ||
              item.state == AssistantChatMessageState.failed ||
              item.content.trim().isEmpty),
    );

    if (index != -1) {
      final AssistantChatMessage current = messages[index];
      final String nextContent = current.content.trim().isEmpty
          ? content
          : '${current.content}\n$content';
      messages[index] = current.copyWith(
        content: nextContent,
        createdAt: createdAt,
        state: state,
      );
      return;
    }

    final AssistantChatMessage lastMessage = messages.last;
    if (lastMessage.role == AssistantChatMessageRole.assistant &&
        lastMessage.state == AssistantChatMessageState.success) {
      messages[messages.length - 1] = lastMessage.copyWith(
        content: '${lastMessage.content}\n$content',
        createdAt: createdAt,
      );
      return;
    }

    messages.add(
      AssistantChatMessage(
        id: IdGenerator.next('chat'),
        role: AssistantChatMessageRole.assistant,
        content: content,
        createdAt: createdAt,
        state: state,
      ),
    );
  }

  void _finalizePendingAssistantMessage(List<AssistantChatMessage> messages) {
    if (messages.isEmpty) {
      return;
    }
    final int index = messages.lastIndexWhere(
      (AssistantChatMessage item) =>
          item.role == AssistantChatMessageRole.assistant &&
          item.state == AssistantChatMessageState.loading,
    );
    if (index == -1) {
      return;
    }
    messages[index] = messages[index].copyWith(
      state: AssistantChatMessageState.success,
      content: messages[index].content.trim().isEmpty
          ? '已完成。'
          : messages[index].content.trim(),
    );
  }

  void _upsertTask(AssistantTask task, {bool select = false}) {
    final int index =
        _tasks.indexWhere((AssistantTask item) => item.id == task.id);
    if (index == -1) {
      _tasks.insert(0, task);
    } else {
      _tasks[index] = task;
    }
    _sortInPlace();
    if (select) {
      _selectedTaskId = task.id;
    }
    unawaited(_saveState());
    notifyListeners();
  }

  void _replaceTask(String id, AssistantTask task) {
    final int index = _tasks.indexWhere((AssistantTask item) => item.id == id);
    if (index == -1) {
      return;
    }
    _tasks[index] = task;
    _sortInPlace();
    notifyListeners();
  }

  AssistantTask? _taskById(String id) {
    for (final AssistantTask task in _tasks) {
      if (task.id == id) {
        return task;
      }
    }
    return null;
  }

  void _sortInPlace() {
    _tasks.sort(
      (AssistantTask left, AssistantTask right) =>
          right.updatedAt.compareTo(left.updatedAt),
    );
  }

  List<AssistantTask> _sortTasks(List<AssistantTask> tasks) {
    final List<AssistantTask> copied = List<AssistantTask>.from(tasks);
    copied.sort(
      (AssistantTask left, AssistantTask right) =>
          right.updatedAt.compareTo(left.updatedAt),
    );
    return copied;
  }

  Future<void> _saveState() {
    return _taskRepository.save(
      tasks: _tasks,
      favoriteActionIds: _favoriteActionIds,
    );
  }

  void _restoreChatSessionSelections() {
    _activeChatSessionKeyByAgent.clear();
    for (final AssistantTask task in _tasks) {
      if (!_isChatTask(task)) {
        continue;
      }
      // 这里使用 putIfAbsent，意味着只认“按更新时间倒序后的第一条聊天任务”
      // 作为该 Agent 的默认活跃分支，保证恢复逻辑稳定且直观。
      _activeChatSessionKeyByAgent.putIfAbsent(task.agentId, () {
        return _normalizeChatSessionKey(
          chatSessionKey: task.chatSessionKey,
          fallbackAgentId: task.agentId,
        );
      });
    }
  }

  String resolveActiveChatSessionKey({required String agentId}) {
    final String normalizedAgentId = _normalizeAgentId(agentId);
    return _activeChatSessionKeyByAgent[normalizedAgentId] ?? normalizedAgentId;
  }

  String _resolveChatSessionKeyForSubmit({
    required String agentId,
    required String? explicitSessionKey,
  }) {
    if (explicitSessionKey != null && explicitSessionKey.trim().isNotEmpty) {
      return explicitSessionKey.trim();
    }
    return resolveActiveChatSessionKey(agentId: agentId);
  }

  String _normalizeAgentId(String? agentId) {
    final String trimmed = (agentId ?? '').trim();
    return trimmed.isEmpty ? 'main' : trimmed;
  }

  String _normalizeChatSessionKey({
    required String? chatSessionKey,
    required String fallbackAgentId,
  }) {
    final String trimmed = (chatSessionKey ?? '').trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return _normalizeAgentId(fallbackAgentId);
  }

  bool _isChatTask(AssistantTask task) {
    return task.quickActionId == TaskQuickAction.chatId;
  }

  List<AssistantTask> _resolveVisibleChatTasks({
    required String agentId,
    required String sessionKey,
  }) {
    return _resolveChatTasksForSession(
      agentId: agentId,
      sessionKey: sessionKey,
      limitTaskId: null,
      visitedSessionKeys: <String>{},
    );
  }

  List<AssistantTask> _resolveChatTasksForSession({
    required String agentId,
    required String sessionKey,
    required String? limitTaskId,
    required Set<String> visitedSessionKeys,
  }) {
    if (!visitedSessionKeys.add(sessionKey)) {
      // 防止异常数据导致分支互相引用，出现递归死循环。
      return <AssistantTask>[];
    }

    // 先拿到当前会话键下的所有聊天任务，再按创建时间正序排列，
    // 这样最终拼出来的消息链路才符合真实对话顺序。
    final List<AssistantTask> sessionTasks = _tasks
        .where(
          (AssistantTask task) =>
              _isChatTask(task) &&
              task.agentId == agentId &&
              task.chatSessionKey == sessionKey,
        )
        .toList()
      ..sort(
        (AssistantTask left, AssistantTask right) =>
            left.createdAt.compareTo(right.createdAt),
      );

    final String? anchorTaskId = _pendingRevertTargetTaskIdByAgent[agentId] ??
        (sessionTasks.isEmpty ? null : sessionTasks.first.revertToTaskId);

    List<AssistantTask> visibleTasks = sessionTasks;
    if (anchorTaskId != null) {
      final AssistantTask? anchorTask = _taskById(anchorTaskId);
      if (anchorTask != null && anchorTask.agentId == agentId) {
        // 如果当前分支是从旧任务回退而来，
        // 那么可见链路 = 旧分支中“锚点之前的历史” + 当前新分支任务。
        visibleTasks = <AssistantTask>[
          ..._resolveChatTasksForSession(
            agentId: agentId,
            sessionKey: anchorTask.chatSessionKey,
            limitTaskId: anchorTask.id,
            visitedSessionKeys: visitedSessionKeys,
          ),
          ...sessionTasks,
        ];
      }
    }

    if (limitTaskId == null) {
      return visibleTasks;
    }

    // limitTaskId 用于“只截取到某个锚点为止”，
    // 这是回退时拼接旧历史链路的关键能力。
    final int index = visibleTasks.indexWhere(
      (AssistantTask task) => task.id == limitTaskId,
    );
    if (index == -1) {
      return visibleTasks;
    }
    return visibleTasks.sublist(0, index + 1);
  }

  Future<void> _stopRunningTaskBeforeStartingNext() async {
    if (_currentSession == null || _currentTaskId == null) {
      return;
    }

    final String currentTaskId = _currentTaskId!;
    await _subscription?.cancel();
    _subscription = null;
    await _sessionRepository.stop(_currentSession!);

    final AssistantTask? currentTask = _taskById(currentTaskId);
    if (currentTask != null) {
      _replaceTask(
        currentTaskId,
        currentTask.copyWith(
          status: AssistantTaskStatus.stopped,
          transcript: <String>[
            ...currentTask.transcript,
            '系统已停止上一个任务，以便开始新的任务。',
          ],
          chatMessages: currentTask.chatMessages,
          summary: '上一个任务已停止',
          updatedAt: DateTime.now(),
        ),
      );
    }

    _currentSession = null;
    _currentTaskId = null;
    await _saveState();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
