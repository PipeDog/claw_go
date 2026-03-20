import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../foundation/process/process_service.dart';
import '../../../foundation/runtime/runtime_environment_preferences.dart';
import '../../../foundation/utils/app_logger.dart';
import '../../../foundation/utils/id_generator.dart';
import '../api/openclaw_runtime_adapter.dart';
import 'gateway_chat_protocol.dart';
import 'openclaw_gateway_client.dart';
import '../model/config_import_result.dart';
import '../model/openclaw_gateway_connection_state.dart';
import '../model/openclaw_gateway_connection_request.dart';
import '../model/openclaw_gateway_status.dart';
import '../model/node_runtime_info.dart';
import '../model/openclaw_command_preset.dart';
import '../model/openclaw_profile.dart';
import '../model/openclaw_session.dart';
import '../model/profile_validation_result.dart';
import '../model/runtime_launch_result.dart';
import '../model/terminal_event.dart';
import '../utils/command_parser.dart';

/// 默认 Runtime 实现。
///
/// 已按官方文档接入以下真实命令：
/// - openclaw configure
/// - openclaw config file
/// - openclaw config validate --json
/// - openclaw gateway status --json
/// - openclaw health --json
/// - openclaw sessions --json
/// - openclaw logs --plain
/// - openclaw onboard --install-daemon
final openClawRuntimeAdapterProvider =
    Provider<OpenClawRuntimeAdapter>((Ref ref) {
  return DefaultOpenClawRuntimeAdapter(
    processService: ref.watch(processServiceProvider),
    runtimePreferencesReader:
        ref.watch(runtimeEnvironmentPreferencesReaderProvider),
  );
});

class DefaultOpenClawRuntimeAdapter implements OpenClawRuntimeAdapter {
  DefaultOpenClawRuntimeAdapter({
    required ProcessService processService,
    required RuntimeEnvironmentPreferencesReader runtimePreferencesReader,
  })  : _processService = processService,
        _runtimePreferencesReader = runtimePreferencesReader;

  final ProcessService _processService;
  final RuntimeEnvironmentPreferencesReader _runtimePreferencesReader;
  final Map<String, ManagedProcess> _managedProcesses =
      <String, ManagedProcess>{};
  final Map<String, _ManagedGatewayChatSession> _managedGatewayChats =
      <String, _ManagedGatewayChatSession>{};
  final StreamController<OpenClawGatewayConnectionState>
      _gatewayConnectionStateController =
      StreamController<OpenClawGatewayConnectionState>.broadcast();
  OpenClawGatewayConnectionState _gatewayConnectionState =
      const OpenClawGatewayConnectionState.disconnected();
  OpenClawGatewayClient? _sharedGatewayClient;
  String? _sharedGatewayUrl;
  ManagedProcess? _gatewayProcess;
  StreamSubscription<String>? _gatewayStdoutSubscription;
  StreamSubscription<String>? _gatewayStderrSubscription;

  @override
  Future<ConfigImportResult> detect() async {
    final RuntimeEnvironmentPreferences runtimePreferences =
        await _runtimePreferencesReader.load();
    final NodeRuntimeInfo nodeRuntimeInfo = await _detectNodeRuntime(
      preferredNodePath: runtimePreferences.preferredNodePath,
    );
    final List<String> detectedCliPaths = <String>[];
    for (final String candidate in AppConfig.openClawExecutableCandidates) {
      final String? resolved = _resolveExecutable(candidate);
      if (resolved != null && !detectedCliPaths.contains(resolved)) {
        detectedCliPaths.add(resolved);
      }
    }

    final String? primaryCli =
        detectedCliPaths.isEmpty ? null : detectedCliPaths.first;
    final String? cliVersion = primaryCli == null
        ? null
        : await _detectVersion(
            primaryCli,
            preferredNodePath: runtimePreferences.preferredNodePath,
          );

    final List<String> detectedConfigPaths = <String>[];
    if (primaryCli != null) {
      final String? configPath = await _detectConfigPath(
        primaryCli,
        preferredNodePath: runtimePreferences.preferredNodePath,
      );
      if (configPath != null && configPath.isNotEmpty) {
        detectedConfigPaths.add(configPath);
      }
    }

    if (detectedConfigPaths.isEmpty) {
      detectedConfigPaths.addAll(_fallbackConfigCandidates());
    }

    bool? configValid;
    String? configValidationMessage;
    if (primaryCli != null && detectedConfigPaths.isNotEmpty) {
      final ConfigValidationSummary summary = await _validateConfig(
        executable: primaryCli,
        configPath: detectedConfigPaths.first,
        preferredNodePath: runtimePreferences.preferredNodePath,
      );
      configValid = summary.isValid;
      configValidationMessage = summary.message;
    }

    OpenClawGatewayStatus? gatewayStatus;
    if (primaryCli != null) {
      final Map<String, String> environment = _environmentWithPreferredNodePath(
        runtimePreferences.preferredNodePath,
      );
      if (detectedConfigPaths.isNotEmpty) {
        environment['OPENCLAW_CONFIG_PATH'] = detectedConfigPaths.first;
      }
      gatewayStatus = await _readGatewayStatus(
        executable: primaryCli,
        workingDirectory: null,
        environment: environment,
      );
    }

    final List<String> warnings = <String>[];
    if (detectedCliPaths.isEmpty) {
      warnings.add('未在 PATH 中发现 OpenClaw 可执行命令，请手动填写。');
    }
    if (!nodeRuntimeInfo.isDetected) {
      warnings.add('未在当前运行环境中发现 Node，可执行命令可能无法启动。');
    } else if (!nodeRuntimeInfo.isSatisfied) {
      warnings.add(
        'Node 版本不满足要求：需要 >= ${nodeRuntimeInfo.requiredVersion}，'
        '当前为 ${nodeRuntimeInfo.version ?? '未知'}'
        '${nodeRuntimeInfo.executablePath == null ? '' : '（${nodeRuntimeInfo.executablePath}）'}。',
      );
    }
    if (detectedConfigPaths.isEmpty) {
      warnings.add('未自动发现配置文件，可在 OpenClaw Environment 中手动指定。');
    }
    if (configValid == false &&
        (configValidationMessage?.isNotEmpty ?? false)) {
      warnings.add(configValidationMessage!);
    }

    return ConfigImportResult(
      detectedCliPaths: detectedCliPaths,
      detectedConfigPaths: detectedConfigPaths,
      envHints: <String, String>{
        if (Platform.environment['HOME'] case final String homeValue)
          'HOME': homeValue,
        if (Platform.environment['PWD'] case final String pwdValue)
          'PWD': pwdValue,
      },
      warnings: warnings,
      cliVersion: cliVersion,
      configValid: configValid,
      configValidationMessage: configValidationMessage,
      nodeRuntimeInfo: nodeRuntimeInfo,
      gatewayStatus: gatewayStatus,
    );
  }

  @override
  Future<ProfileValidationResult> validateProfile(
      OpenClawProfile profile) async {
    final RuntimeEnvironmentPreferences runtimePreferences =
        await _runtimePreferencesReader.load();
    final String? preferredNodePath = runtimePreferences.preferredNodePath;
    final NodeRuntimeInfo nodeRuntimeInfo = await _detectNodeRuntime(
      preferredNodePath: preferredNodePath,
    );
    if (!nodeRuntimeInfo.isDetected) {
      return ProfileValidationResult(
        isValid: false,
        message:
            '当前运行环境中未发现 Node，请先安装 Node ${AppConfig.minimumNodeVersion} 或更高版本。',
        nodeRuntimeInfo: nodeRuntimeInfo,
      );
    }
    if (!nodeRuntimeInfo.isSatisfied) {
      return ProfileValidationResult(
        isValid: false,
        message:
            'Node 版本不满足 OpenClaw 要求。需要 >= ${nodeRuntimeInfo.requiredVersion}，当前为 '
            '${nodeRuntimeInfo.version ?? '未知'}。',
        nodeRuntimeInfo: nodeRuntimeInfo,
      );
    }

    if (profile.name.trim().length < 2) {
      return ProfileValidationResult(
        isValid: false,
        message: 'Environment 名称至少需要 2 个字符。',
        nodeRuntimeInfo: nodeRuntimeInfo,
      );
    }

    if (profile.cliPath.trim().isEmpty) {
      return ProfileValidationResult(
        isValid: false,
        message: '请填写 OpenClaw CLI 路径或命令名。',
        nodeRuntimeInfo: nodeRuntimeInfo,
      );
    }

    final String? executable = _resolveExecutable(profile.cliPath);
    if (executable == null) {
      return ProfileValidationResult(
        isValid: false,
        message: '无法找到指定的 OpenClaw CLI，请确认 PATH 或绝对路径是否正确。',
        nodeRuntimeInfo: nodeRuntimeInfo,
      );
    }

    if (profile.workingDirectory.trim().isNotEmpty) {
      final Directory directory = Directory(profile.workingDirectory.trim());
      if (!directory.existsSync()) {
        return ProfileValidationResult(
          isValid: false,
          message: '工作目录不存在，请重新选择。',
          nodeRuntimeInfo: nodeRuntimeInfo,
        );
      }
    }

    final String? cliVersion = await _detectVersion(
      executable,
      preferredNodePath: preferredNodePath,
    );

    if (profile.configPath.trim().isNotEmpty) {
      final File file = File(profile.configPath.trim());
      if (!file.existsSync()) {
        return ProfileValidationResult(
          isValid: false,
          message: '配置文件不存在，请检查路径。',
          nodeRuntimeInfo: nodeRuntimeInfo,
        );
      }

      final ConfigValidationSummary summary = await _validateConfig(
        executable: executable,
        configPath: profile.configPath.trim(),
        preferredNodePath: preferredNodePath,
      );
      if (!summary.isValid) {
        return ProfileValidationResult(
          isValid: false,
          message: 'CLI 可用，但配置校验未通过。',
          cliVersion: cliVersion,
          configValidationMessage: summary.message,
          nodeRuntimeInfo: nodeRuntimeInfo,
        );
      }

      return ProfileValidationResult(
        isValid: true,
        message: 'CLI 与配置文件校验通过。',
        cliVersion: cliVersion,
        configValidationMessage: summary.message,
        nodeRuntimeInfo: nodeRuntimeInfo,
      );
    }

    return ProfileValidationResult(
      isValid: true,
      message: 'CLI 校验通过。当前未指定配置文件，将使用 OpenClaw 默认配置。',
      cliVersion: cliVersion,
      nodeRuntimeInfo: nodeRuntimeInfo,
    );
  }

  @override
  Future<OpenClawGatewayStatus> getGatewayStatus(
      OpenClawProfile profile) async {
    final RuntimeEnvironmentPreferences runtimePreferences =
        await _runtimePreferencesReader.load();
    final String executable =
        _resolveExecutable(profile.cliPath) ?? profile.cliPath;
    final _GatewayRuntimeContext runtimeContext =
        await _resolveGatewayRuntimeContext(
      profile: profile,
      executable: executable,
      preferredNodePath: runtimePreferences.preferredNodePath,
    );

    if (_sharedGatewayClient != null && _gatewayConnectionState.isConnected) {
      return OpenClawGatewayStatus(
        isRunning: true,
        message:
            'Gateway 已连接${_sharedGatewayUrl == null ? '' : '：$_sharedGatewayUrl'}',
        url: _sharedGatewayUrl,
        startedByApp: _gatewayProcess != null,
        configPath: runtimeContext.configPath,
        authSummary: runtimeContext.authSummary,
      );
    }
    final Map<String, String> environment = _buildExecutionEnvironment(
      profile: profile,
      preferredNodePath: runtimePreferences.preferredNodePath,
    );
    final OpenClawGatewayStatus status = await _readGatewayStatus(
      executable: executable,
      workingDirectory: profile.workingDirectory.trim().isEmpty
          ? null
          : profile.workingDirectory.trim(),
      environment: environment,
      preferredNodePath: runtimePreferences.preferredNodePath,
    );
    return _mergeGatewayRuntimeContext(status, runtimeContext);
  }

  @override
  Future<OpenClawGatewayStatus> ensureGatewayRunning(
      OpenClawProfile profile) async {
    final OpenClawGatewayStatus currentStatus = await getGatewayStatus(profile);
    if (currentStatus.isRunning) {
      return currentStatus;
    }

    final RuntimeEnvironmentPreferences runtimePreferences =
        await _runtimePreferencesReader.load();
    final String executable =
        _resolveExecutable(profile.cliPath) ?? profile.cliPath;
    final Map<String, String> environment = _buildExecutionEnvironment(
      profile: profile,
      preferredNodePath: runtimePreferences.preferredNodePath,
    );
    final String? workingDirectory = profile.workingDirectory.trim().isEmpty
        ? null
        : profile.workingDirectory.trim();

    if (_gatewayProcess != null) {
      _gatewayProcess!.kill();
      await _gatewayProcess!.dispose();
      await _gatewayStdoutSubscription?.cancel();
      await _gatewayStderrSubscription?.cancel();
      _gatewayProcess = null;
      _gatewayStdoutSubscription = null;
      _gatewayStderrSubscription = null;
    }

    final ManagedProcess gatewayProcess = await _startCliProcess(
      executable: executable,
      arguments: const <String>[
        'gateway',
        'run',
        '--force',
        '--port',
        '18789',
      ],
      workingDirectory: workingDirectory,
      environment: environment,
      preferredNodePath: runtimePreferences.preferredNodePath,
    );

    _gatewayProcess = gatewayProcess;
    _gatewayStdoutSubscription =
        gatewayProcess.stdoutLines.listen((String line) {
      AppLogger.info('[gateway] $line');
    });
    _gatewayStderrSubscription =
        gatewayProcess.stderrLines.listen((String line) {
      AppLogger.info('[gateway][stderr] $line');
    });
    unawaited(
      gatewayProcess.exitCode.then((_) async {
        await _gatewayStdoutSubscription?.cancel();
        await _gatewayStderrSubscription?.cancel();
        _gatewayStdoutSubscription = null;
        _gatewayStderrSubscription = null;
        _gatewayProcess = null;
      }),
    );

    OpenClawGatewayStatus latestStatus = const OpenClawGatewayStatus(
      isRunning: false,
      message: 'Gateway 正在启动...',
      startedByApp: true,
    );
    for (int attempt = 0; attempt < 20; attempt += 1) {
      await Future<void>.delayed(const Duration(seconds: 1));
      latestStatus = await _readGatewayStatus(
        executable: executable,
        workingDirectory: workingDirectory,
        environment: environment,
        preferredNodePath: runtimePreferences.preferredNodePath,
      );
      if (latestStatus.isRunning) {
        final _GatewayRuntimeContext runtimeContext =
            await _resolveGatewayRuntimeContext(
          profile: profile,
          executable: executable,
          preferredNodePath: runtimePreferences.preferredNodePath,
        );
        return OpenClawGatewayStatus(
          isRunning: true,
          message: 'Gateway 已在应用内启动。',
          url: latestStatus.url,
          pid: latestStatus.pid ?? gatewayProcess.pid,
          startedByApp: true,
          configPath: runtimeContext.configPath,
          authSummary: runtimeContext.authSummary,
        );
      }
    }

    throw StateError(
      '已尝试在 App 内启动 Gateway，但仍未就绪。${latestStatus.message}',
    );
  }

  @override
  Future<OpenClawGatewayStatus> restartGateway(OpenClawProfile profile) async {
    final RuntimeEnvironmentPreferences runtimePreferences =
        await _runtimePreferencesReader.load();
    final String executable =
        _resolveExecutable(profile.cliPath) ?? profile.cliPath;
    final Map<String, String> environment = _buildExecutionEnvironment(
      profile: profile,
      preferredNodePath: runtimePreferences.preferredNodePath,
    );
    final String? workingDirectory = profile.workingDirectory.trim().isEmpty
        ? null
        : profile.workingDirectory.trim();

    final CommandResult restartResult = await _runCliCommand(
      executable: executable,
      arguments: const <String>['gateway', 'restart'],
      workingDirectory: workingDirectory,
      environment: environment,
      preferredNodePath: runtimePreferences.preferredNodePath,
    );
    if (restartResult.exitCode == 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      return getGatewayStatus(profile);
    }

    await stopGateway();
    return ensureGatewayRunning(profile);
  }

  @override
  Future<void> stopGateway() async {
    await disconnectGateway();
    final ManagedProcess? gatewayProcess = _gatewayProcess;
    if (gatewayProcess == null) {
      return;
    }
    gatewayProcess.kill();
    await gatewayProcess.dispose();
    await _gatewayStdoutSubscription?.cancel();
    await _gatewayStderrSubscription?.cancel();
    _gatewayStdoutSubscription = null;
    _gatewayStderrSubscription = null;
    _gatewayProcess = null;
  }

  @override
  Future<OpenClawGatewayConnectionState> connectGateway(
    OpenClawProfile profile, {
    OpenClawGatewayConnectionRequest? request,
  }) async {
    if (_sharedGatewayClient != null && _gatewayConnectionState.isConnected) {
      return _gatewayConnectionState;
    }

    _emitGatewayConnectionState(
      OpenClawGatewayConnectionState(
        phase: OpenClawGatewayConnectionPhase.connecting,
        message: '正在连接 Gateway...',
      ),
    );

    OpenClawGatewayClient? nextClient;
    try {
      final OpenClawGatewayStatus gatewayStatus = await ensureGatewayRunning(
        profile,
      );
      final RuntimeEnvironmentPreferences runtimePreferences =
          await _runtimePreferencesReader.load();
      final String executable =
          _resolveExecutable(profile.cliPath) ?? profile.cliPath;
      final _GatewayConnectionOptions connectionOptions =
          await _resolveGatewayConnectionOptions(
        profile: profile,
        executable: executable,
        preferredNodePath: runtimePreferences.preferredNodePath,
        gatewayStatus: gatewayStatus,
        request: request,
      );

      nextClient = OpenClawGatewayClient(
        url: connectionOptions.url,
        token: connectionOptions.token,
        password: connectionOptions.password,
      );
      await nextClient.connect();
      final List<String> grantedScopes =
          _extractGatewayScopes(nextClient.helloPayload);
      final OpenClawGatewayClient? previousClient = _sharedGatewayClient;
      _sharedGatewayClient = nextClient;
      _sharedGatewayUrl = connectionOptions.url;
      if (previousClient != null && previousClient != nextClient) {
        await previousClient.close();
      }
      _observeSharedGatewayClient(nextClient);
      final OpenClawGatewayConnectionState connectedState =
          OpenClawGatewayConnectionState(
        phase: OpenClawGatewayConnectionPhase.connected,
        message: 'Gateway 已连接',
        url: connectionOptions.url,
        grantedScopes: grantedScopes,
      );
      _emitGatewayConnectionState(connectedState);
      return connectedState;
    } catch (error) {
      await nextClient?.close();
      final OpenClawGatewayConnectionState errorState =
          OpenClawGatewayConnectionState(
        phase: OpenClawGatewayConnectionPhase.error,
        message: 'Gateway 连接失败：$error',
      );
      _emitGatewayConnectionState(errorState);
      return errorState;
    }
  }

  @override
  Future<void> disconnectGateway() async {
    final OpenClawGatewayClient? client = _sharedGatewayClient;
    _sharedGatewayClient = null;
    _sharedGatewayUrl = null;
    if (client != null) {
      await client.close();
    }
    _emitGatewayConnectionState(
      const OpenClawGatewayConnectionState.disconnected(
        message: 'Gateway 已断开连接',
      ),
    );
  }

  @override
  OpenClawGatewayConnectionState getGatewayConnectionState() {
    return _gatewayConnectionState;
  }

  @override
  Stream<OpenClawGatewayConnectionState> watchGatewayConnectionState() {
    return _gatewayConnectionStateController.stream;
  }

  @override
  Future<RuntimeLaunchResult> startSession(OpenClawProfile profile) async {
    final ProfileValidationResult validationResult =
        await validateProfile(profile);
    if (!validationResult.isValid) {
      throw StateError(
          validationResult.configValidationMessage ?? validationResult.message);
    }
    final RuntimeEnvironmentPreferences runtimePreferences =
        await _runtimePreferencesReader.load();
    final String? preferredNodePath = runtimePreferences.preferredNodePath;

    final String sessionId = IdGenerator.next('session');
    final String executable =
        _resolveExecutable(profile.cliPath) ?? profile.cliPath;
    final OpenClawCommandPreset preset =
        OpenClawCommandPreset.byId(profile.commandPresetId);
    final List<String> arguments = <String>[
      ...preset.arguments,
      ...CommandParser.parseArguments(profile.customArgs),
    ];
    final Map<String, String> environment = _buildExecutionEnvironment(
      profile: profile,
      preferredNodePath: preferredNodePath,
    );
    final String? workingDirectory = profile.workingDirectory.trim().isEmpty
        ? null
        : profile.workingDirectory.trim();

    if (preset.id == OpenClawCommandPreset.agentChatId) {
      return _startAgentChatSession(
        sessionId: sessionId,
        profile: profile,
        executable: executable,
        arguments: arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        preferredNodePath: preferredNodePath,
      );
    }

    final ManagedProcess managedProcess = await _startCliProcess(
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      preferredNodePath: preferredNodePath,
    );

    _managedProcesses[sessionId] = managedProcess;
    final StreamController<TerminalEvent> controller =
        StreamController<TerminalEvent>();

    controller.add(
      TerminalEvent(
        type: TerminalEventType.status,
        data: '已启动 ${preset.label}，PID=${managedProcess.pid}',
        timestamp: DateTime.now(),
      ),
    );

    unawaited(
      managedProcess.stdoutLines.forEach((String line) {
        controller.add(
          TerminalEvent(
            type: TerminalEventType.stdout,
            data: line,
            timestamp: DateTime.now(),
          ),
        );
      }),
    );

    unawaited(
      managedProcess.stderrLines.forEach((String line) {
        controller.add(
          TerminalEvent(
            type: TerminalEventType.stderr,
            data: line,
            timestamp: DateTime.now(),
          ),
        );
      }),
    );

    unawaited(
      managedProcess.exitCode.then((int exitCode) async {
        controller.add(
          TerminalEvent(
            type: TerminalEventType.status,
            data: '命令执行结束，退出码：$exitCode',
            timestamp: DateTime.now(),
          ),
        );
        _managedProcesses.remove(sessionId);
        await managedProcess.dispose();
        await controller.close();
      }),
    );

    AppLogger.info('已启动 OpenClaw 会话 $sessionId，命令=${preset.label}');

    return RuntimeLaunchResult(
      session: OpenClawSession(
        id: sessionId,
        profileId: profile.id,
        status: OpenClawSessionStatus.running,
        startedAt: DateTime.now(),
        commandLabel: preset.label,
        pid: managedProcess.pid,
      ),
      events: controller.stream,
      sendInput: (String input) => sendInput(sessionId, input),
    );
  }

  @override
  Future<RuntimeLaunchResult> startGatewayChatSession({
    required OpenClawProfile profile,
    required String message,
    String sessionKey = 'main',
  }) async {
    final ProfileValidationResult validationResult =
        await validateProfile(profile);
    if (!validationResult.isValid) {
      throw StateError(
        validationResult.configValidationMessage ?? validationResult.message,
      );
    }

    final RuntimeEnvironmentPreferences runtimePreferences =
        await _runtimePreferencesReader.load();
    final String? preferredNodePath = runtimePreferences.preferredNodePath;
    final String sessionId = IdGenerator.next('gateway-chat');
    final String executable =
        _resolveExecutable(profile.cliPath) ?? profile.cliPath;
    final StreamController<TerminalEvent> controller =
        StreamController<TerminalEvent>();
    final _ManagedGatewayChatSession managedChat = _ManagedGatewayChatSession(
      sessionKey: sessionKey,
      controller: controller,
    );
    _managedGatewayChats[sessionId] = managedChat;

    void emitTerminalEvent(TerminalEventType type, String data) {
      if (!controller.isClosed) {
        controller.add(
          TerminalEvent(
            type: type,
            data: data,
            timestamp: DateTime.now(),
          ),
        );
      }
    }

    emitTerminalEvent(
      TerminalEventType.status,
      '正在通过 Gateway 建立聊天...',
    );

    unawaited(() async {
      int exitCode = 1;
      try {
        final OpenClawGatewayStatus gatewayStatus =
            await ensureGatewayRunning(profile);
        emitTerminalEvent(TerminalEventType.status, gatewayStatus.message);

        final _GatewayConnectionOptions connectionOptions =
            await _resolveGatewayConnectionOptions(
          profile: profile,
          executable: executable,
          preferredNodePath: preferredNodePath,
          gatewayStatus: gatewayStatus,
        );

        final bool reuseSharedClient = _sharedGatewayClient != null &&
            _gatewayConnectionState.isConnected &&
            _sharedGatewayUrl == connectionOptions.url;
        final OpenClawGatewayClient client = reuseSharedClient
            ? _sharedGatewayClient!
            : OpenClawGatewayClient(
                url: connectionOptions.url,
                token: connectionOptions.token,
                password: connectionOptions.password,
              );
        managedChat.client = client;
        managedChat.ownsClient = !reuseSharedClient;

        if (!reuseSharedClient) {
          emitTerminalEvent(
            TerminalEventType.status,
            '正在连接 ${connectionOptions.url}',
          );
          await client.connect();
          final List<String> grantedScopes =
              _extractGatewayScopes(client.helloPayload);
          if (grantedScopes.isNotEmpty) {
            emitTerminalEvent(
              TerminalEventType.status,
              'Gateway 授权范围：${grantedScopes.join(', ')}',
            );
          }
        }
        emitTerminalEvent(
          TerminalEventType.status,
          reuseSharedClient ? '已复用现有 Gateway 连接。' : 'Gateway 连接成功，正在发送消息...',
        );

        final String requestRunId = IdGenerator.next('gwrun');
        managedChat.requestRunId = requestRunId;
        final Completer<_GatewayChatOutcome> outcomeCompleter =
            Completer<_GatewayChatOutcome>();
        String? latestDeltaText;
        bool announcedStreaming = false;

        managedChat.eventSubscription = client.events.listen(
          (OpenClawGatewayEventFrame event) {
            if (event.event != 'chat') {
              return;
            }
            final GatewayChatEventPayload payload =
                GatewayChatEventPayload.fromJson(event.payload);
            if (payload.sessionKey.isEmpty) {
              return;
            }
            final bool shouldAccept = shouldAcceptGatewayChatEvent(
              sessionKey: managedChat.activeSessionKey,
              requestRunId: requestRunId,
              responseRunId: managedChat.responseRunId,
              payload: payload,
            );
            if (!shouldAccept) {
              AppLogger.info(
                '[gateway] [chat] ignore event '
                'sessionKey=${payload.sessionKey} '
                'runId=${payload.runId.isEmpty ? '-' : payload.runId} '
                'state=${payload.state.isEmpty ? '-' : payload.state} '
                'expectedRequestRunId=$requestRunId '
                'expectedSessionKey=${managedChat.activeSessionKey} '
                'expectedResponseRunId='
                '${managedChat.responseRunId?.isEmpty ?? true ? '-' : managedChat.responseRunId}',
              );
              return;
            }
            if (payload.sessionKey != managedChat.activeSessionKey) {
              AppLogger.info(
                '[gateway] [chat] adopt sessionKey '
                '${managedChat.activeSessionKey} -> ${payload.sessionKey}',
              );
              managedChat.activeSessionKey = payload.sessionKey;
            }

            final String state = payload.state;
            if (state == 'delta') {
              latestDeltaText = _extractGatewayMessageText(payload.message);
              if (!announcedStreaming &&
                  latestDeltaText != null &&
                  latestDeltaText!.trim().isNotEmpty) {
                announcedStreaming = true;
                emitTerminalEvent(
                  TerminalEventType.status,
                  'OpenClaw 正在生成回复...',
                );
              }
              return;
            }

            if (state == 'final') {
              final String finalText = _extractGatewayMessageText(
                    payload.message,
                  ) ??
                  latestDeltaText ??
                  '';
              if (!outcomeCompleter.isCompleted) {
                outcomeCompleter.complete(
                  _GatewayChatOutcome.success(finalText),
                );
              }
              return;
            }

            if (state == 'error' || state == 'aborted') {
              final String? partialText =
                  _extractGatewayMessageText(payload.message) ??
                      latestDeltaText;
              if (!outcomeCompleter.isCompleted) {
                if (state == 'aborted' &&
                    partialText != null &&
                    partialText.trim().isNotEmpty) {
                  outcomeCompleter.complete(
                    _GatewayChatOutcome.success(partialText),
                  );
                } else {
                  outcomeCompleter.complete(
                    _GatewayChatOutcome.failure(
                      event.payload?['errorMessage']?.toString() ??
                          (state == 'aborted'
                              ? 'Gateway 聊天已中止。'
                              : 'Gateway 聊天失败。'),
                    ),
                  );
                }
              }
            }
          },
          onError: (Object error, StackTrace _) {
            if (!outcomeCompleter.isCompleted) {
              outcomeCompleter.complete(
                _GatewayChatOutcome.failure(error.toString()),
              );
            }
          },
        );

        final Map<String, dynamic>? response = await client.request(
          'chat.send',
          <String, dynamic>{
            'sessionKey': sessionKey,
            'message': message,
            'deliver': false,
            'idempotencyKey': requestRunId,
          },
          timeout: const Duration(seconds: 15),
        );

        final String resolvedRunId =
            response?['runId']?.toString().trim() ?? '';
        if (resolvedRunId.isNotEmpty) {
          managedChat.responseRunId = resolvedRunId;
        }
        AppLogger.info(
          '[gateway] [chat] chat.send ack sessionKey=$sessionKey '
          'requestRunId=$requestRunId '
          'responseRunId=${resolvedRunId.isEmpty ? '-' : resolvedRunId}',
        );

        emitTerminalEvent(
          TerminalEventType.status,
          '消息已发送，等待 OpenClaw 回复...',
        );

        final _GatewayChatOutcome outcome =
            await outcomeCompleter.future.timeout(const Duration(minutes: 5));
        if (outcome.errorMessage != null) {
          emitTerminalEvent(TerminalEventType.stderr, outcome.errorMessage!);
        } else {
          emitTerminalEvent(
            TerminalEventType.stdout,
            outcome.message.trim().isEmpty
                ? 'OpenClaw 已完成，但没有返回可展示的文本。'
                : outcome.message,
          );
          exitCode = 0;
        }
      } catch (error) {
        emitTerminalEvent(TerminalEventType.stderr, error.toString());
      } finally {
        final _ManagedGatewayChatSession? activeChat =
            _managedGatewayChats.remove(sessionId);
        await activeChat?.eventSubscription?.cancel();
        if (activeChat?.client != null && activeChat?.ownsClient == true) {
          await activeChat!.client!.close();
        }
        emitTerminalEvent(TerminalEventType.status, '命令执行结束，退出码：$exitCode');
        if (!controller.isClosed) {
          await controller.close();
        }
      }
    }());

    return RuntimeLaunchResult(
      session: OpenClawSession(
        id: sessionId,
        profileId: profile.id,
        status: OpenClawSessionStatus.running,
        startedAt: DateTime.now(),
        commandLabel: 'Gateway 聊天',
      ),
      events: controller.stream,
      sendInput: (String _) async {},
    );
  }

  @override
  Future<void> sendInput(String sessionId, String input) async {
    final _ManagedGatewayChatSession? managedGatewayChat =
        _managedGatewayChats[sessionId];
    if (managedGatewayChat != null) {
      return;
    }
    final ManagedProcess? managedProcess = _managedProcesses[sessionId];
    if (managedProcess == null) {
      return;
    }
    await managedProcess.write(input);
  }

  @override
  Future<void> stopSession(String sessionId) async {
    final _ManagedGatewayChatSession? managedGatewayChat =
        _managedGatewayChats.remove(sessionId);
    if (managedGatewayChat != null) {
      try {
        final OpenClawGatewayClient? client = managedGatewayChat.client;
        final String? runId = managedGatewayChat.requestRunId;
        if (client != null &&
            runId != null &&
            runId.trim().isNotEmpty &&
            managedGatewayChat.activeSessionKey.trim().isNotEmpty) {
          await client.request(
            'chat.abort',
            <String, dynamic>{
              'sessionKey': managedGatewayChat.activeSessionKey,
              'runId': runId,
            },
            timeout: const Duration(seconds: 5),
          );
        }
      } catch (_) {
        // 主动停止时忽略 abort 失败。
      } finally {
        await managedGatewayChat.eventSubscription?.cancel();
        if (managedGatewayChat.client != null &&
            managedGatewayChat.ownsClient) {
          await managedGatewayChat.client!.close();
        }
        if (!managedGatewayChat.controller.isClosed) {
          await managedGatewayChat.controller.close();
        }
      }
      return;
    }

    final ManagedProcess? managedProcess = _managedProcesses.remove(sessionId);
    if (managedProcess == null) {
      return;
    }
    managedProcess.kill();
    await managedProcess.dispose();
  }

  @override
  Future<RuntimeLaunchResult> restartSession(
      OpenClawProfile profile, String sessionId) async {
    await stopSession(sessionId);
    return startSession(profile);
  }

  Future<RuntimeLaunchResult> _startAgentChatSession({
    required String sessionId,
    required OpenClawProfile profile,
    required String executable,
    required List<String> arguments,
    required String? workingDirectory,
    required Map<String, String> environment,
    required String? preferredNodePath,
  }) async {
    final StreamController<TerminalEvent> controller =
        StreamController<TerminalEvent>();
    controller.add(
      TerminalEvent(
        type: TerminalEventType.status,
        data: '正在确认 Gateway 状态...',
        timestamp: DateTime.now(),
      ),
    );

    unawaited(() async {
      int exitCode = 1;
      try {
        final OpenClawGatewayStatus gatewayStatus =
            await ensureGatewayRunning(profile);
        controller.add(
          TerminalEvent(
            type: TerminalEventType.status,
            data: gatewayStatus.message,
            timestamp: DateTime.now(),
          ),
        );
        controller.add(
          TerminalEvent(
            type: TerminalEventType.status,
            data: '已启动 直接聊天',
            timestamp: DateTime.now(),
          ),
        );

        final CommandResult result = await _runCliCommand(
          executable: executable,
          arguments: arguments,
          workingDirectory: workingDirectory,
          environment: environment,
          preferredNodePath: preferredNodePath,
        );
        exitCode = result.exitCode;
        if (result.exitCode == 0) {
          final String response = _extractAgentMessage(result.stdoutText);
          controller.add(
            TerminalEvent(
              type: TerminalEventType.stdout,
              data: response.isEmpty ? 'OpenClaw 已完成，但没有返回可展示的文本。' : response,
              timestamp: DateTime.now(),
            ),
          );
        } else {
          final String errorText = result.mergedOutput.trim();
          controller.add(
            TerminalEvent(
              type: TerminalEventType.stderr,
              data: errorText.isEmpty ? 'OpenClaw 聊天失败。' : errorText,
              timestamp: DateTime.now(),
            ),
          );
        }
      } catch (error) {
        controller.add(
          TerminalEvent(
            type: TerminalEventType.stderr,
            data: error.toString(),
            timestamp: DateTime.now(),
          ),
        );
      } finally {
        controller.add(
          TerminalEvent(
            type: TerminalEventType.status,
            data: '命令执行结束，退出码：$exitCode',
            timestamp: DateTime.now(),
          ),
        );
        await controller.close();
      }
    }());

    return RuntimeLaunchResult(
      session: OpenClawSession(
        id: sessionId,
        profileId: profile.id,
        status: OpenClawSessionStatus.running,
        startedAt: DateTime.now(),
        commandLabel: OpenClawCommandPreset.byId(profile.commandPresetId).label,
      ),
      events: controller.stream,
      sendInput: (_) async {},
    );
  }

  String _extractAgentMessage(String output) {
    final String trimmedOutput = output.trim();
    if (trimmedOutput.isEmpty) {
      return '';
    }

    try {
      final Object? decoded = jsonDecode(trimmedOutput);
      if (decoded is Map<String, dynamic>) {
        final Map<String, dynamic>? result =
            decoded['result'] as Map<String, dynamic>?;
        final List<dynamic>? payloads = result?['payloads'] as List<dynamic>?;
        if (payloads != null && payloads.isNotEmpty) {
          final List<String> texts = payloads
              .whereType<Map<String, dynamic>>()
              .map(
                  (Map<String, dynamic> item) => item['text']?.toString() ?? '')
              .where((String item) => item.trim().isNotEmpty)
              .toList();
          if (texts.isNotEmpty) {
            return texts.join('\n\n');
          }
        }
        final String? summary = decoded['summary']?.toString();
        if (summary != null && summary.trim().isNotEmpty) {
          return summary.trim();
        }
      }
    } catch (_) {
      // 非 JSON 输出直接回退原始文本。
    }

    return trimmedOutput;
  }

  Future<String?> _detectVersion(
    String executable, {
    String? preferredNodePath,
  }) async {
    final CommandResult result = await _runCliCommand(
      executable: executable,
      arguments: const <String>['--version'],
      environment: _environmentWithPreferredNodePath(preferredNodePath),
      preferredNodePath: preferredNodePath,
    );
    if (result.exitCode != 0) {
      return null;
    }
    final List<String> lines = _extractMeaningfulLines(result.mergedOutput);
    return lines.isEmpty ? null : lines.first;
  }

  Future<String?> _detectConfigPath(
    String executable, {
    String? preferredNodePath,
  }) async {
    final CommandResult result = await _runCliCommand(
      executable: executable,
      arguments: const <String>['config', 'file'],
      environment: _environmentWithPreferredNodePath(preferredNodePath),
      preferredNodePath: preferredNodePath,
    );
    if (result.exitCode != 0) {
      return null;
    }
    final List<String> lines = _extractMeaningfulLines(result.stdoutText);
    if (lines.isEmpty) {
      return null;
    }
    return _expandHomePath(lines.first);
  }

  Future<NodeRuntimeInfo> _detectNodeRuntime({
    String? preferredNodePath,
  }) async {
    final String? executablePath = _resolveNodeExecutable(
      preferredNodePath: preferredNodePath,
    );
    final Map<String, String> environment =
        _environmentWithPreferredNodePath(preferredNodePath);
    if (executablePath == null) {
      return NodeRuntimeInfo(
        requiredVersion: AppConfig.minimumNodeVersion,
        pathEnvironment: environment['PATH'],
      );
    }

    final CommandResult result = await _processService.run(
      executable: executablePath,
      arguments: const <String>['-v'],
      environment: environment,
    );

    final String version = result.exitCode == 0
        ? result.stdoutText.trim().isNotEmpty
            ? result.stdoutText.trim()
            : result.stderrText.trim()
        : '';

    return NodeRuntimeInfo(
      requiredVersion: AppConfig.minimumNodeVersion,
      executablePath: executablePath,
      version: version.isEmpty ? null : version,
      pathEnvironment: environment['PATH'],
    );
  }

  String? _resolveNodeExecutable({String? preferredNodePath}) {
    final String? preferred = preferredNodePath?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      final File preferredFile = File(preferred);
      if (preferredFile.existsSync()) {
        return preferredFile.path;
      }
    }

    final List<String> candidates = <String>[
      ..._discoverNodeCandidates(),
      if (_resolveExecutable('node') case final String path) path,
    ];

    final Set<String> seen = <String>{};
    for (final String candidate in candidates) {
      if (seen.add(candidate) && File(candidate).existsSync()) {
        return candidate;
      }
    }
    return null;
  }

  Map<String, String> _sanitizeProfileEnvironment(Map<String, String> envVars) {
    final Map<String, String> sanitized = <String, String>{};
    envVars.forEach((String key, String value) {
      if (key.toUpperCase() == 'PATH') {
        return;
      }
      sanitized[key] = value;
    });
    return sanitized;
  }

  Map<String, String> _buildExecutionEnvironment({
    required OpenClawProfile profile,
    required String? preferredNodePath,
  }) {
    final Map<String, String> environment = <String, String>{
      ...Platform.environment,
      ..._sanitizeProfileEnvironment(profile.envVars),
    };
    final String? resolvedNodeExecutable = _resolveNodeExecutable(
      preferredNodePath: preferredNodePath,
    );
    _prependNodeDirectoryToPath(
      environment: environment,
      nodeExecutablePath: resolvedNodeExecutable,
    );
    if (profile.configPath.trim().isNotEmpty) {
      environment['OPENCLAW_CONFIG_PATH'] = profile.configPath.trim();
    }
    return environment;
  }

  Map<String, String> _environmentWithPreferredNodePath(
      String? preferredNodePath) {
    final Map<String, String> environment = <String, String>{
      ...Platform.environment,
    };
    final String? resolvedNodeExecutable = _resolveNodeExecutable(
      preferredNodePath: preferredNodePath,
    );
    _prependNodeDirectoryToPath(
      environment: environment,
      nodeExecutablePath: resolvedNodeExecutable,
    );
    return environment;
  }

  Future<OpenClawGatewayStatus> _readGatewayStatus({
    required String executable,
    required String? workingDirectory,
    required Map<String, String> environment,
    String? preferredNodePath,
  }) async {
    final CommandResult result = await _runCliCommand(
      executable: executable,
      arguments: const <String>['gateway', 'status', '--json'],
      workingDirectory: workingDirectory,
      environment: environment,
      preferredNodePath: preferredNodePath,
    );

    final String output = result.stdoutText.trim().isNotEmpty
        ? result.stdoutText.trim()
        : result.mergedOutput.trim();
    if (output.isEmpty) {
      return OpenClawGatewayStatus(
        isRunning: false,
        message: 'Gateway 状态查询没有返回内容。',
        startedByApp: _gatewayProcess != null,
      );
    }

    try {
      final String? jsonPayload = _extractJsonPayload(output);
      final Object? decoded = jsonDecode(jsonPayload ?? output);
      if (decoded is Map<String, dynamic>) {
        final Map<String, dynamic>? rpc =
            decoded['rpc'] as Map<String, dynamic>?;
        final Map<String, dynamic>? gateway =
            decoded['gateway'] as Map<String, dynamic>?;
        final Map<String, dynamic>? port =
            decoded['port'] as Map<String, dynamic>?;
        final List<dynamic> listeners =
            port?['listeners'] as List<dynamic>? ?? <dynamic>[];
        final int? pid =
            listeners.isNotEmpty && listeners.first is Map<String, dynamic>
                ? (listeners.first as Map<String, dynamic>)['pid'] as int?
                : null;
        final bool rpcReady = rpc?['ok'] == true;
        final bool portBusy = port?['status']?.toString() == 'busy';
        final bool hasListeners = listeners.isNotEmpty;
        final bool hasGatewayUrl =
            (gateway?['probeUrl']?.toString().trim().isNotEmpty ?? false) ||
                (rpc?['url']?.toString().trim().isNotEmpty ?? false);
        final String rpcError = rpc?['error']?.toString().trim() ?? '';
        final bool probeReachedGateway =
            rpcError.contains('abnormal closure') ||
                rpcError.contains('auth') ||
                rpcError.contains('pair') ||
                rpcError.contains('closed');
        final bool isRunning = rpcReady ||
            (portBusy &&
                hasListeners &&
                (hasGatewayUrl || probeReachedGateway));
        final String? url =
            rpc?['url']?.toString() ?? gateway?['probeUrl']?.toString();
        final String message = _buildGatewayStatusMessage(
          isRunning: isRunning,
          rpcReady: rpcReady,
          url: url,
          rpcError: rpcError,
          port: port,
        );
        return OpenClawGatewayStatus(
          isRunning: isRunning,
          message: message,
          url: url,
          pid: pid,
          startedByApp: _gatewayProcess != null,
        );
      }
    } catch (_) {
      // 非 JSON 输出则回退文本。
    }

    return OpenClawGatewayStatus(
      isRunning: false,
      message: _stripAnsi(output),
      startedByApp: _gatewayProcess != null,
    );
  }

  List<String> _discoverNodeCandidates() {
    final List<String> candidates = <String>[
      '/opt/homebrew/bin/node',
      '/usr/local/bin/node',
    ];

    final String? home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      final Directory nvmDirectory = Directory('$home/.nvm/versions/node');
      if (nvmDirectory.existsSync()) {
        final List<Directory> versionDirectories = nvmDirectory
            .listSync(followLinks: false)
            .whereType<Directory>()
            .toList()
          ..sort(
            (Directory left, Directory right) => _compareVersionStrings(
              _basename(right.path),
              _basename(left.path),
            ),
          );
        for (final Directory versionDirectory in versionDirectories) {
          candidates.add('${versionDirectory.path}/bin/node');
        }
      }
    }

    return candidates;
  }

  String _basename(String path) {
    final String separator = Platform.pathSeparator;
    if (!path.contains(separator)) {
      return path;
    }
    return path.split(separator).last;
  }

  int _compareVersionStrings(String left, String right) {
    final List<int> leftParts = _parseVersionParts(left);
    final List<int> rightParts = _parseVersionParts(right);
    final int maxLength = leftParts.length > rightParts.length
        ? leftParts.length
        : rightParts.length;
    for (int index = 0; index < maxLength; index += 1) {
      final int leftValue = index < leftParts.length ? leftParts[index] : 0;
      final int rightValue = index < rightParts.length ? rightParts[index] : 0;
      if (leftValue != rightValue) {
        return leftValue.compareTo(rightValue);
      }
    }
    return 0;
  }

  List<int> _parseVersionParts(String value) {
    final String normalized =
        value.startsWith('v') ? value.substring(1) : value;
    return normalized
        .split('.')
        .map((String part) => int.tryParse(part) ?? 0)
        .toList();
  }

  void _prependNodeDirectoryToPath({
    required Map<String, String> environment,
    required String? nodeExecutablePath,
  }) {
    final String? executablePath = nodeExecutablePath?.trim();
    if (executablePath == null || executablePath.isEmpty) {
      return;
    }

    final File nodeFile = File(executablePath);
    if (!nodeFile.existsSync()) {
      return;
    }

    final String nodeDirectory = nodeFile.parent.path;
    final String currentPath =
        environment['PATH'] ?? Platform.environment['PATH'] ?? '';
    final List<String> segments = currentPath.isEmpty
        ? <String>[]
        : currentPath.split(Platform.isWindows ? ';' : ':');
    if (segments.contains(nodeDirectory)) {
      environment['PATH'] = currentPath;
      return;
    }
    final String separator = Platform.isWindows ? ';' : ':';
    environment['PATH'] = segments.isEmpty
        ? nodeDirectory
        : '$nodeDirectory$separator$currentPath';
  }

  Future<ConfigValidationSummary> _validateConfig({
    required String executable,
    required String configPath,
    String? preferredNodePath,
  }) async {
    final Map<String, String> environment =
        _environmentWithPreferredNodePath(preferredNodePath);
    environment['OPENCLAW_CONFIG_PATH'] = configPath;
    final CommandResult result = await _runCliCommand(
      executable: executable,
      arguments: const <String>['config', 'validate', '--json'],
      environment: environment,
      preferredNodePath: preferredNodePath,
    );

    final bool isValid = result.exitCode == 0;
    final String message = _extractValidationMessage(result);
    return ConfigValidationSummary(isValid: isValid, message: message);
  }

  String _extractValidationMessage(CommandResult result) {
    final String mergedOutput = result.mergedOutput;
    if (mergedOutput.isEmpty) {
      return result.exitCode == 0 ? '配置校验通过。' : '配置校验失败，但 CLI 未返回详细信息。';
    }

    try {
      final String? jsonPayload = _extractJsonPayload(mergedOutput);
      final Object? decoded = jsonDecode(jsonPayload ?? mergedOutput);
      if (decoded is Map<String, dynamic>) {
        final String? message =
            decoded['message']?.toString() ?? decoded['summary']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      // 某些版本可能返回普通文本而不是 JSON，这里直接回退原始输出。
    }

    return _stripAnsi(mergedOutput);
  }

  String _buildGatewayStatusMessage({
    required bool isRunning,
    required bool rpcReady,
    required String? url,
    required String rpcError,
    required Map<String, dynamic>? port,
  }) {
    if (isRunning) {
      if (rpcReady) {
        return 'Gateway 已就绪${url == null ? '' : '：$url'}';
      }
      return 'Gateway 正在运行${url == null ? '' : '：$url'}';
    }

    final String portHints = ((port?['hints'] as List<dynamic>?) ?? <dynamic>[])
        .map((dynamic item) => item.toString())
        .where((String item) => item.trim().isNotEmpty)
        .join('；');
    if (rpcError.isNotEmpty) {
      return rpcError;
    }
    if (portHints.isNotEmpty) {
      return portHints;
    }
    return 'Gateway 尚未就绪。';
  }

  List<String> _extractMeaningfulLines(String output) {
    return _stripAnsi(output)
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) {
      if (line.isEmpty) {
        return false;
      }
      if (line.startsWith('[plugins]') ||
          line.startsWith('[gateway]') ||
          line.startsWith('[info]') ||
          line.startsWith('[ws]') ||
          line.startsWith('[bonjour]') ||
          line.startsWith('[canvas]') ||
          line.startsWith('[heartbeat]') ||
          line.startsWith('[health-monitor]') ||
          line.startsWith('[hooks')) {
        return false;
      }
      return true;
    }).toList();
  }

  String? _extractJsonPayload(String output) {
    final List<String> lines = output.split('\n');
    for (int index = 0; index < lines.length; index += 1) {
      final String trimmedLine = lines[index].trimLeft();
      if (!trimmedLine.startsWith('{') && !trimmedLine.startsWith('[')) {
        continue;
      }
      final String candidate = lines.sublist(index).join('\n').trim();
      if (candidate.isEmpty) {
        continue;
      }
      try {
        jsonDecode(candidate);
        return candidate;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  String _stripAnsi(String value) {
    return value.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
  }

  List<String> _fallbackConfigCandidates() {
    final String? home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      return const <String>[];
    }

    final List<String> results = <String>[];
    for (final String relativePath in AppConfig.openClawConfigCandidates) {
      final File file = File('$home/$relativePath');
      if (file.existsSync()) {
        results.add(file.path);
      }
    }
    return results;
  }

  /// 统一执行 OpenClaw CLI，避免依赖 shebang 再次解析 Node。
  ///
  /// 部分 macOS 桌面环境下，直接启动 npm 安装的 CLI 文件时，
  /// 即使 PATH 中已经包含了正确版本的 Node，实际运行进程仍可能落到
  /// 旧版本 Node 上。这里改为在识别出“Node 脚本入口”后，
  /// 显式使用选中的 Node 可执行文件来启动脚本，确保 `process.execPath`
  /// 与设置页展示的一致。
  Future<CommandResult> _runCliCommand({
    required String executable,
    required List<String> arguments,
    String? workingDirectory,
    required Map<String, String> environment,
    String? preferredNodePath,
  }) async {
    final _ResolvedProcessInvocation invocation = _resolveCliInvocation(
      executable: executable,
      arguments: arguments,
      preferredNodePath: preferredNodePath,
    );
    return _processService.run(
      executable: invocation.executable,
      arguments: invocation.arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );
  }

  Future<ManagedProcess> _startCliProcess({
    required String executable,
    required List<String> arguments,
    String? workingDirectory,
    required Map<String, String> environment,
    String? preferredNodePath,
  }) async {
    final _ResolvedProcessInvocation invocation = _resolveCliInvocation(
      executable: executable,
      arguments: arguments,
      preferredNodePath: preferredNodePath,
    );
    return _processService.start(
      executable: invocation.executable,
      arguments: invocation.arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );
  }

  _ResolvedProcessInvocation _resolveCliInvocation({
    required String executable,
    required List<String> arguments,
    String? preferredNodePath,
  }) {
    final String? nodeScriptEntry = _resolveNodeScriptEntry(executable);
    final String? resolvedNodeExecutable = _resolveNodeExecutable(
      preferredNodePath: preferredNodePath,
    );
    if (nodeScriptEntry != null && resolvedNodeExecutable != null) {
      return _ResolvedProcessInvocation(
        executable: resolvedNodeExecutable,
        arguments: <String>[nodeScriptEntry, ...arguments],
      );
    }
    return _ResolvedProcessInvocation(
      executable: executable,
      arguments: arguments,
    );
  }

  String? _resolveNodeScriptEntry(String executable) {
    final String? resolvedExecutable = _resolveExecutable(executable);
    if (resolvedExecutable == null) {
      return null;
    }
    final File executableFile = File(resolvedExecutable);
    if (!executableFile.existsSync()) {
      return null;
    }

    final String normalizedPath = resolvedExecutable.toLowerCase();
    if (normalizedPath.endsWith('.mjs') ||
        normalizedPath.endsWith('.cjs') ||
        normalizedPath.endsWith('.js')) {
      return resolvedExecutable;
    }

    try {
      final List<String> lines = executableFile.readAsLinesSync();
      final String firstLine = lines.isEmpty ? '' : lines.first;
      if (firstLine.startsWith('#!') && firstLine.contains('node')) {
        return resolvedExecutable;
      }
    } catch (_) {
      // 二进制文件或不可读文件直接视为非 Node 脚本。
    }

    return null;
  }

  String? _resolveExecutable(String executable) {
    final String candidate = executable.trim();
    if (candidate.isEmpty) {
      return null;
    }

    final File directFile = File(candidate);
    if (directFile.existsSync()) {
      return directFile.path;
    }

    final String? pathValue = Platform.environment['PATH'];
    if (pathValue == null || pathValue.isEmpty) {
      return null;
    }

    for (final String directoryPath
        in pathValue.split(Platform.isWindows ? ';' : ':')) {
      if (directoryPath.trim().isEmpty) {
        continue;
      }
      final File file = File('${directoryPath.trim()}/$candidate');
      if (file.existsSync()) {
        return file.path;
      }
    }

    return null;
  }

  void _emitGatewayConnectionState(OpenClawGatewayConnectionState state) {
    _gatewayConnectionState = state;
    if (!_gatewayConnectionStateController.isClosed) {
      _gatewayConnectionStateController.add(state);
    }
  }

  void _observeSharedGatewayClient(OpenClawGatewayClient client) {
    unawaited(client.done.then((_) {
      if (!identical(_sharedGatewayClient, client)) {
        return;
      }
      _sharedGatewayClient = null;
      _sharedGatewayUrl = null;
      _emitGatewayConnectionState(
        const OpenClawGatewayConnectionState.disconnected(
          message: 'Gateway 连接已关闭',
        ),
      );
    }));
  }

  Future<_GatewayConnectionOptions> _resolveGatewayConnectionOptions({
    required OpenClawProfile profile,
    required String executable,
    required String? preferredNodePath,
    required OpenClawGatewayStatus gatewayStatus,
    OpenClawGatewayConnectionRequest? request,
  }) async {
    final _GatewayRuntimeContext runtimeContext =
        await _resolveGatewayRuntimeContext(
      profile: profile,
      executable: executable,
      preferredNodePath: preferredNodePath,
    );
    final String url = request?.normalizedUrl ??
        (gatewayStatus.url?.trim().isNotEmpty == true
            ? gatewayStatus.url!.trim()
            : 'ws://127.0.0.1:18789');
    final _GatewayAuthConfig authConfig = runtimeContext.authConfig;
    return _GatewayConnectionOptions(
      url: url,
      token: request?.normalizedToken ?? authConfig.token,
      password: request?.normalizedPassword ?? authConfig.password,
    );
  }

  Future<_GatewayRuntimeContext> _resolveGatewayRuntimeContext({
    required OpenClawProfile profile,
    required String executable,
    required String? preferredNodePath,
  }) async {
    final String? configPath = await _resolveConfigPathForGateway(
      profile: profile,
      executable: executable,
      preferredNodePath: preferredNodePath,
    );
    final _GatewayAuthConfig authConfig =
        await _loadGatewayAuthConfig(configPath);
    return _GatewayRuntimeContext(
      configPath: configPath,
      authSummary: authConfig.summary,
      authConfig: authConfig,
    );
  }

  OpenClawGatewayStatus _mergeGatewayRuntimeContext(
    OpenClawGatewayStatus status,
    _GatewayRuntimeContext runtimeContext,
  ) {
    return OpenClawGatewayStatus(
      isRunning: status.isRunning,
      message: status.message,
      url: status.url,
      pid: status.pid,
      startedByApp: status.startedByApp,
      configPath: runtimeContext.configPath,
      authSummary: runtimeContext.authSummary,
    );
  }

  Future<String?> _resolveConfigPathForGateway({
    required OpenClawProfile profile,
    required String executable,
    required String? preferredNodePath,
  }) async {
    final String configuredPath = profile.configPath.trim();
    if (configuredPath.isNotEmpty) {
      return _expandHomePath(configuredPath);
    }
    final String? detectedPath = await _detectConfigPath(
      executable,
      preferredNodePath: preferredNodePath,
    );
    if (detectedPath != null && detectedPath.trim().isNotEmpty) {
      return detectedPath.trim();
    }
    final List<String> candidates = _fallbackConfigCandidates();
    return candidates.isEmpty ? null : candidates.first;
  }

  Future<_GatewayAuthConfig> _loadGatewayAuthConfig(String? configPath) async {
    final String? normalizedPath = _expandHomePath(configPath);
    if (normalizedPath == null || normalizedPath.isEmpty) {
      return _gatewayAuthFromEnvironment();
    }

    final File configFile = File(normalizedPath);
    if (!configFile.existsSync()) {
      return _gatewayAuthFromEnvironment();
    }

    try {
      final Object? decoded = jsonDecode(await configFile.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return _gatewayAuthFromEnvironment();
      }
      final Map<String, dynamic>? gateway =
          decoded['gateway'] as Map<String, dynamic>?;
      final Map<String, dynamic>? auth =
          gateway?['auth'] as Map<String, dynamic>?;
      return _GatewayAuthConfig(
        token: _resolveSecretValue(auth?['token']) ??
            Platform.environment['OPENCLAW_GATEWAY_TOKEN'],
        password: _resolveSecretValue(auth?['password']) ??
            Platform.environment['OPENCLAW_GATEWAY_PASSWORD'],
        sourceDescription: _resolveGatewayAuthSourceDescription(
          auth: auth,
          fromConfigFile: true,
        ),
      );
    } catch (_) {
      return _gatewayAuthFromEnvironment();
    }
  }

  _GatewayAuthConfig _gatewayAuthFromEnvironment() {
    return _GatewayAuthConfig(
      token: Platform.environment['OPENCLAW_GATEWAY_TOKEN'],
      password: Platform.environment['OPENCLAW_GATEWAY_PASSWORD'],
      sourceDescription: _resolveGatewayAuthSourceDescription(
        auth: null,
        fromConfigFile: false,
      ),
    );
  }

  String _resolveGatewayAuthSourceDescription({
    required Map<String, dynamic>? auth,
    required bool fromConfigFile,
  }) {
    final String sourceLabel = fromConfigFile ? '配置文件' : '环境变量';
    final String mode = auth?['mode']?.toString().trim() ?? '';
    final bool hasToken = _resolveSecretValue(auth?['token']) != null ||
        (auth == null &&
            (Platform.environment['OPENCLAW_GATEWAY_TOKEN']
                    ?.trim()
                    .isNotEmpty ==
                true));
    final bool hasPassword = _resolveSecretValue(auth?['password']) != null ||
        (auth == null &&
            (Platform.environment['OPENCLAW_GATEWAY_PASSWORD']
                    ?.trim()
                    .isNotEmpty ==
                true));

    if (hasToken) {
      return 'token${mode.isEmpty ? '' : ' · mode=$mode'} · 来源：$sourceLabel';
    }
    if (hasPassword) {
      return 'password${mode.isEmpty ? '' : ' · mode=$mode'} · 来源：$sourceLabel';
    }
    if (mode.isNotEmpty) {
      return 'mode=$mode · 来源：$sourceLabel';
    }
    return '未检测到显式 Gateway 鉴权';
  }

  String? _resolveSecretValue(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is Map<String, dynamic>) {
      final String envKey = value['env']?.toString().trim() ?? '';
      if (envKey.isNotEmpty) {
        final String? envValue = Platform.environment[envKey];
        if (envValue != null && envValue.trim().isNotEmpty) {
          return envValue.trim();
        }
      }
      final String filePath = value['file']?.toString().trim() ?? '';
      if (filePath.isNotEmpty) {
        final File secretFile = File(_expandHomePath(filePath) ?? filePath);
        if (secretFile.existsSync()) {
          final String fileValue = secretFile.readAsStringSync().trim();
          if (fileValue.isNotEmpty) {
            return fileValue;
          }
        }
      }
    }
    return null;
  }

  String? _expandHomePath(String? rawPath) {
    final String? path = rawPath?.trim();
    if (path == null || path.isEmpty) {
      return null;
    }
    if (!path.startsWith('~/')) {
      return path;
    }
    final String? home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      return path;
    }
    return '$home/${path.substring(2)}';
  }

  String? _extractGatewayMessageText(Object? message) {
    if (message is String) {
      final String trimmed = message.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (message is Map<String, dynamic>) {
      if (message['text'] is String &&
          (message['text'] as String).trim().isNotEmpty) {
        return (message['text'] as String).trim();
      }
      final Object? content = message['content'];
      if (content is String && content.trim().isNotEmpty) {
        return content.trim();
      }
      if (content is List<dynamic>) {
        final List<String> parts = <String>[];
        for (final dynamic item in content) {
          if (item is Map<String, dynamic>) {
            final String type = item['type']?.toString() ?? '';
            if (type == 'text') {
              final String text = item['text']?.toString().trim() ?? '';
              if (text.isNotEmpty) {
                parts.add(text);
              }
            }
          }
        }
        if (parts.isNotEmpty) {
          return parts.join('\n').trim();
        }
      }
    }
    return null;
  }

  List<String> _extractGatewayScopes(Map<String, dynamic>? helloPayload) {
    final Map<String, dynamic>? auth =
        helloPayload?['auth'] as Map<String, dynamic>?;
    final List<dynamic> rawScopes = auth?['scopes'] as List<dynamic>? ??
        helloPayload?['scopes'] as List<dynamic>? ??
        <dynamic>[];
    return rawScopes
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }
}

class ConfigValidationSummary {
  const ConfigValidationSummary({required this.isValid, required this.message});

  final bool isValid;
  final String message;
}

class _ManagedGatewayChatSession {
  _ManagedGatewayChatSession({
    required this.sessionKey,
    required this.controller,
  }) : activeSessionKey = sessionKey;

  final String sessionKey;
  String activeSessionKey;
  final StreamController<TerminalEvent> controller;
  OpenClawGatewayClient? client;
  StreamSubscription<OpenClawGatewayEventFrame>? eventSubscription;
  String? requestRunId;
  String? responseRunId;
  bool ownsClient = false;
}

class _GatewayConnectionOptions {
  const _GatewayConnectionOptions({
    required this.url,
    this.token,
    this.password,
  });

  final String url;
  final String? token;
  final String? password;
}

class _ResolvedProcessInvocation {
  const _ResolvedProcessInvocation({
    required this.executable,
    required this.arguments,
  });

  final String executable;
  final List<String> arguments;
}

class _GatewayAuthConfig {
  const _GatewayAuthConfig({
    this.token,
    this.password,
    this.sourceDescription,
  });

  final String? token;
  final String? password;
  final String? sourceDescription;

  String get summary {
    final String normalized = sourceDescription?.trim() ?? '';
    return normalized.isEmpty ? '未检测到显式 Gateway 鉴权' : normalized;
  }
}

class _GatewayRuntimeContext {
  const _GatewayRuntimeContext({
    required this.configPath,
    required this.authSummary,
    required this.authConfig,
  });

  final String? configPath;
  final String authSummary;
  final _GatewayAuthConfig authConfig;
}

class _GatewayChatOutcome {
  const _GatewayChatOutcome._({
    required this.message,
    required this.errorMessage,
  });

  factory _GatewayChatOutcome.success(String message) {
    return _GatewayChatOutcome._(
      message: message,
      errorMessage: null,
    );
  }

  factory _GatewayChatOutcome.failure(String errorMessage) {
    return _GatewayChatOutcome._(
      message: '',
      errorMessage: errorMessage,
    );
  }

  final String message;
  final String? errorMessage;
}
