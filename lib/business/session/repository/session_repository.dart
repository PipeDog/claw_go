import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../component/openclaw_runtime/api/openclaw_runtime_adapter.dart';
import '../../../component/openclaw_runtime/impl/default_openclaw_runtime_adapter.dart';
import '../../../component/openclaw_runtime/model/openclaw_gateway_connection_request.dart';
import '../../../component/openclaw_runtime/model/openclaw_profile.dart';
import '../../../component/openclaw_runtime/model/openclaw_gateway_connection_state.dart';
import '../../../component/openclaw_runtime/model/openclaw_gateway_status.dart';
import '../../../component/openclaw_runtime/model/openclaw_session.dart';
import '../../../component/openclaw_runtime/model/runtime_launch_result.dart';
import '../../../component/openclaw_runtime/model/terminal_event.dart';
import '../../../foundation/storage/local_json_storage.dart';
import '../../../foundation/storage/secure_storage_service.dart';
import '../model/gateway_connection_preferences.dart';

/// 会话仓库。
final sessionRepositoryProvider = Provider<SessionRepository>((Ref ref) {
  return SessionRepository(
    runtimeAdapter: ref.watch(openClawRuntimeAdapterProvider),
    storage: ref.watch(localJsonStorageProvider),
    secureStorageService: ref.watch(secureStorageServiceProvider),
  );
});

class SessionRepository {
  const SessionRepository({
    required OpenClawRuntimeAdapter runtimeAdapter,
    required LocalJsonStorage storage,
    required SecureStorageService secureStorageService,
  })  : _runtimeAdapter = runtimeAdapter,
        _storage = storage,
        _secureStorageService = secureStorageService;

  final OpenClawRuntimeAdapter _runtimeAdapter;
  final LocalJsonStorage _storage;
  final SecureStorageService _secureStorageService;
  static const String _gatewayWebSocketUrlKey = 'gateway_websocket_url';

  Future<RuntimeLaunchResult> start(OpenClawProfile profile) {
    return _runtimeAdapter.startSession(profile);
  }

  Future<RuntimeLaunchResult> startGatewayChat({
    required OpenClawProfile profile,
    required String message,
    String sessionKey = 'main',
  }) {
    return _runtimeAdapter.startGatewayChatSession(
      profile: profile,
      message: message,
      sessionKey: sessionKey,
    );
  }

  Future<OpenClawGatewayStatus> getGatewayStatus(OpenClawProfile profile) {
    return _runtimeAdapter.getGatewayStatus(profile);
  }

  Future<OpenClawGatewayStatus> ensureGatewayRunning(OpenClawProfile profile) {
    return _runtimeAdapter.ensureGatewayRunning(profile);
  }

  Future<OpenClawGatewayStatus> restartGateway(OpenClawProfile profile) {
    return _runtimeAdapter.restartGateway(profile);
  }

  Future<void> stopGateway() {
    return _runtimeAdapter.stopGateway();
  }

  Future<OpenClawGatewayConnectionState> connectGateway(
    OpenClawProfile profile, {
    OpenClawGatewayConnectionRequest? request,
  }) {
    return _runtimeAdapter.connectGateway(profile, request: request);
  }

  /// 读取本地保存的 Gateway 连接偏好。
  ///
  /// 这里故意只保存“用户主动覆盖”的 URL 与 Token，
  /// 没有填写时仍然允许 Runtime 回退到配置文件或环境变量自动探测。
  Future<GatewayConnectionPreferences>
      loadGatewayConnectionPreferences() async {
    final Map<String, dynamic> json =
        await _storage.readJson(AppConfig.settingsFileName);
    final String? token =
        await _secureStorageService.read(AppConfig.secureGatewayTokenName);
    return GatewayConnectionPreferences(
      webSocketUrl: json[_gatewayWebSocketUrlKey] as String?,
      gatewayToken: token,
    );
  }

  /// 保存 Gateway 连接偏好。
  ///
  /// - URL 明文保存在 settings.json；
  /// - Token 写入安全存储；
  /// - Password 不持久化。
  Future<void> saveGatewayConnectionPreferences(
    GatewayConnectionPreferences preferences,
  ) async {
    final Map<String, dynamic> json =
        await _storage.readJson(AppConfig.settingsFileName);
    final String? url = preferences.normalizedWebSocketUrl;
    if (url == null) {
      json.remove(_gatewayWebSocketUrlKey);
    } else {
      json[_gatewayWebSocketUrlKey] = url;
    }
    await _storage.writeJson(AppConfig.settingsFileName, json);
    await _secureStorageService.write(
      key: AppConfig.secureGatewayTokenName,
      value: preferences.normalizedGatewayToken,
    );
  }

  Future<void> disconnectGateway() {
    return _runtimeAdapter.disconnectGateway();
  }

  OpenClawGatewayConnectionState get gatewayConnectionState =>
      _runtimeAdapter.getGatewayConnectionState();

  Stream<OpenClawGatewayConnectionState> watchGatewayConnectionState() {
    return _runtimeAdapter.watchGatewayConnectionState();
  }

  Future<void> stop(OpenClawSession session) {
    return _runtimeAdapter.stopSession(session.id);
  }

  Future<void> sendInput(OpenClawSession session, String input) {
    return _runtimeAdapter.sendInput(session.id, input);
  }

  StreamSubscription<TerminalEvent> listen(
    RuntimeLaunchResult launchResult,
    void Function(TerminalEvent event) onEvent,
  ) {
    return launchResult.events.listen(onEvent);
  }
}
