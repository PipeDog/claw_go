import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../component/openclaw_runtime/model/openclaw_gateway_connection_state.dart';
import '../../../component/openclaw_runtime/model/openclaw_gateway_connection_request.dart';
import '../../../component/openclaw_runtime/model/openclaw_gateway_status.dart';
import '../../../component/openclaw_runtime/model/openclaw_profile.dart';
import '../../../component/openclaw_runtime/model/openclaw_session.dart';
import '../../../component/openclaw_runtime/model/terminal_event.dart';
import '../../../foundation/base/base_view_model.dart';
import '../../../foundation/utils/app_logger.dart';
import '../model/gateway_connection_preferences.dart';
import '../model/session_action_feedback.dart';
import '../model/session_gateway_action.dart';
import '../repository/session_repository.dart';

/// 会话控制台 ViewModel。
final sessionViewModelProvider =
    ChangeNotifierProvider<SessionViewModel>((Ref ref) {
  return SessionViewModel(
    repository: ref.watch(sessionRepositoryProvider),
  );
});

class SessionViewModel extends BaseViewModel {
  SessionViewModel({required SessionRepository repository})
      : _repository = repository,
        _gatewayConnectionState = repository.gatewayConnectionState {
    _gatewayConnectionSubscription =
        _repository.watchGatewayConnectionState().listen(
      (OpenClawGatewayConnectionState state) {
        _gatewayConnectionState = state;
        _appendTerminalLine(state.message);
        notifyListeners();
      },
    );
    _diagnosticLogs.addAll(AppLogger.entries);
    _diagnosticLogSubscription = AppLogger.watch().listen(_appendDiagnosticLog);
  }

  final SessionRepository _repository;
  OpenClawSession? _currentSession;
  StreamSubscription<TerminalEvent>? _subscription;
  StreamSubscription<OpenClawGatewayConnectionState>?
      _gatewayConnectionSubscription;
  StreamSubscription<String>? _diagnosticLogSubscription;
  final List<String> _terminalLines = <String>[];
  final List<String> _diagnosticLogs = <String>[];
  final Set<SessionGatewayAction> _runningGatewayActions =
      <SessionGatewayAction>{};
  OpenClawGatewayStatus _gatewayStatus = const OpenClawGatewayStatus(
    isRunning: false,
    message: 'Gateway 未启动',
  );
  OpenClawGatewayConnectionState _gatewayConnectionState;

  OpenClawSession? get currentSession => _currentSession;
  List<String> get terminalLines => List<String>.unmodifiable(_terminalLines);
  List<String> get diagnosticLogs => List<String>.unmodifiable(_diagnosticLogs);
  OpenClawGatewayStatus get gatewayStatus => _gatewayStatus;
  OpenClawGatewayConnectionState get gatewayConnectionState =>
      _gatewayConnectionState;
  bool get isRunning =>
      _currentSession?.status == OpenClawSessionStatus.running;

  bool isGatewayActionRunning(SessionGatewayAction action) {
    return _runningGatewayActions.contains(action);
  }

  /// 清空诊断日志，仅影响当前应用运行期的内存数据。
  void clearDiagnosticLogs() {
    _diagnosticLogs.clear();
    AppLogger.clear();
    notifyListeners();
  }

  Future<SessionActionFeedback> refreshGatewayStatus(
    OpenClawProfile profile,
  ) async {
    return _runGatewayAction(
      action: SessionGatewayAction.refreshStatus,
      task: () async {
        _gatewayStatus = await _repository.getGatewayStatus(profile);
        notifyListeners();
        return SessionActionFeedback.success(_gatewayStatus.message);
      },
      onError: (Object error) {
        _gatewayStatus = OpenClawGatewayStatus(
          isRunning: false,
          message: 'Gateway 状态获取失败：$error',
        );
        notifyListeners();
        return SessionActionFeedback.failure(_gatewayStatus.message);
      },
    );
  }

  Future<SessionActionFeedback> ensureGatewayRunning(
    OpenClawProfile profile,
  ) async {
    return _runGatewayAction(
      action: SessionGatewayAction.startGateway,
      task: () async {
        _gatewayStatus = await _repository.ensureGatewayRunning(profile);
        _appendTerminalLine(_gatewayStatus.message);
        notifyListeners();
        return SessionActionFeedback.success(_gatewayStatus.message);
      },
      onError: (Object error) {
        _gatewayStatus = OpenClawGatewayStatus(
          isRunning: false,
          message: 'Gateway 启动失败：$error',
        );
        _appendTerminalLine(_gatewayStatus.message);
        notifyListeners();
        return SessionActionFeedback.failure(_gatewayStatus.message);
      },
    );
  }

  Future<SessionActionFeedback> stopGateway() async {
    return _runGatewayAction(
      action: SessionGatewayAction.stopGateway,
      task: () async {
        await _repository.stopGateway();
        _gatewayStatus = const OpenClawGatewayStatus(
          isRunning: false,
          message: 'Gateway 已停止',
        );
        _appendTerminalLine(_gatewayStatus.message);
        notifyListeners();
        return const SessionActionFeedback.success('Gateway 已停止');
      },
      onError: (Object error) {
        return SessionActionFeedback.failure('停止 Gateway 失败：$error');
      },
    );
  }

  Future<SessionActionFeedback> restartGateway(OpenClawProfile profile) async {
    return _runGatewayAction(
      action: SessionGatewayAction.restartGateway,
      task: () async {
        _gatewayStatus = await _repository.restartGateway(profile);
        _appendTerminalLine(_gatewayStatus.message);
        notifyListeners();
        return SessionActionFeedback.success(_gatewayStatus.message);
      },
      onError: (Object error) {
        return SessionActionFeedback.failure('重启 Gateway 失败：$error');
      },
    );
  }

  Future<SessionActionFeedback> connectGateway(OpenClawProfile profile) async {
    return connectGatewayWithRequest(profile);
  }

  /// 使用显式请求参数连接 Gateway。
  ///
  /// 若未提供 request，则自动读取本地记住的 URL / Token 覆盖项；
  /// 若本地也没有保存覆盖项，则完全回退到 Runtime 自动探测逻辑。
  Future<SessionActionFeedback> connectGatewayWithRequest(
    OpenClawProfile profile, {
    OpenClawGatewayConnectionRequest? request,
    bool rememberOverrides = false,
  }) async {
    return _runGatewayAction(
      action: SessionGatewayAction.connectGateway,
      task: () async {
        final OpenClawGatewayConnectionRequest? effectiveRequest =
            request ?? await _loadStoredGatewayConnectionRequest();
        if (rememberOverrides && request != null) {
          await saveGatewayConnectionPreferences(
            GatewayConnectionPreferences(
              webSocketUrl: request.normalizedUrl,
              gatewayToken: request.normalizedToken,
            ),
          );
        }
        _gatewayConnectionState = await _repository.connectGateway(
          profile,
          request: effectiveRequest,
        );
        notifyListeners();
        return SessionActionFeedback.success(_gatewayConnectionState.message);
      },
      onError: (Object error) {
        return SessionActionFeedback.failure('连接 Gateway 失败：$error');
      },
    );
  }

  Future<SessionActionFeedback> disconnectGateway() async {
    return _runGatewayAction(
      action: SessionGatewayAction.disconnectGateway,
      task: () async {
        await _repository.disconnectGateway();
        notifyListeners();
        return const SessionActionFeedback.success('Gateway 连接已断开。');
      },
      onError: (Object error) {
        return SessionActionFeedback.failure('断开 Gateway 连接失败：$error');
      },
    );
  }

  /// 读取已记住的 Gateway 连接偏好。
  Future<GatewayConnectionPreferences> loadGatewayConnectionPreferences() {
    return _repository.loadGatewayConnectionPreferences();
  }

  /// 保存可记忆的 Gateway 连接偏好。
  Future<void> saveGatewayConnectionPreferences(
    GatewayConnectionPreferences preferences,
  ) {
    return _repository.saveGatewayConnectionPreferences(preferences);
  }

  /// 清空本地保存的 URL / Token 覆盖项。
  Future<void> clearGatewayConnectionOverrides() {
    return _repository.saveGatewayConnectionPreferences(
      const GatewayConnectionPreferences(),
    );
  }

  Future<void> startSession(OpenClawProfile profile) async {
    setLoading(true);
    clearError();
    try {
      await _subscription?.cancel();
      _terminalLines
        ..clear()
        ..add('准备启动：${profile.name}');
      final launchResult = await _repository.start(profile);
      _currentSession = launchResult.session;
      _subscription = _repository.listen(launchResult, _handleTerminalEvent);
      notifyListeners();
    } catch (error) {
      _currentSession = OpenClawSession(
        id: 'failed',
        profileId: profile.id,
        status: OpenClawSessionStatus.failed,
        startedAt: DateTime.now(),
        commandLabel: '启动失败',
      );
      _appendTerminalLine('启动失败：$error');
      setErrorMessage('无法启动命令：$error');
      notifyListeners();
    } finally {
      setLoading(false);
    }
  }

  Future<void> stopSession() async {
    final OpenClawSession? session = _currentSession;
    if (session == null) {
      return;
    }
    await _repository.stop(session);
    _currentSession = session.copyWith(
      status: OpenClawSessionStatus.stopped,
      exitCode: 0,
    );
    _appendTerminalLine('会话已由用户停止。');
    notifyListeners();
  }

  Future<OpenClawGatewayConnectionRequest?>
      _loadStoredGatewayConnectionRequest() async {
    final GatewayConnectionPreferences preferences =
        await _repository.loadGatewayConnectionPreferences();
    if (preferences.isEmpty) {
      return null;
    }
    return OpenClawGatewayConnectionRequest(
      url: preferences.normalizedWebSocketUrl,
      token: preferences.normalizedGatewayToken,
    );
  }

  Future<void> sendInput(String input) async {
    final OpenClawSession? session = _currentSession;
    if (session == null || input.trim().isEmpty) {
      return;
    }
    await _repository.sendInput(session, input);
    _appendTerminalLine('> $input');
    notifyListeners();
  }

  void _handleTerminalEvent(TerminalEvent event) {
    final String prefix = switch (event.type) {
      TerminalEventType.stdout => '',
      TerminalEventType.stderr => '[stderr] ',
      TerminalEventType.status => '[status] ',
    };
    _appendTerminalLine('$prefix${event.data}');
    if (event.type == TerminalEventType.status && event.data.contains('退出码')) {
      _currentSession = _currentSession?.copyWith(
        status: OpenClawSessionStatus.stopped,
        exitCode: _extractExitCode(event.data),
      );
    }
    notifyListeners();
  }

  Future<SessionActionFeedback> _runGatewayAction({
    required SessionGatewayAction action,
    required Future<SessionActionFeedback> Function() task,
    required SessionActionFeedback Function(Object error) onError,
  }) async {
    _runningGatewayActions.add(action);
    clearError();
    notifyListeners();
    try {
      final SessionActionFeedback feedback = await task();
      if (!feedback.success) {
        setErrorMessage(feedback.message);
      }
      return feedback;
    } catch (error) {
      final SessionActionFeedback feedback = onError(error);
      setErrorMessage(feedback.message);
      return feedback;
    } finally {
      _runningGatewayActions.remove(action);
      notifyListeners();
    }
  }

  void _appendTerminalLine(String line) {
    _terminalLines.add(line);
    if (_terminalLines.length > 500) {
      _terminalLines.removeRange(0, _terminalLines.length - 500);
    }
  }

  void _appendDiagnosticLog(String line) {
    _diagnosticLogs.add(line);
    if (_diagnosticLogs.length > 800) {
      _diagnosticLogs.removeRange(0, _diagnosticLogs.length - 800);
    }
    notifyListeners();
  }

  int? _extractExitCode(String value) {
    final Match? match = RegExp(r'(\d+)$').firstMatch(value);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1) ?? '');
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_gatewayConnectionSubscription?.cancel());
    unawaited(_diagnosticLogSubscription?.cancel());
    super.dispose();
  }
}
