import '../model/config_import_result.dart';
import '../model/openclaw_gateway_connection_request.dart';
import '../model/openclaw_gateway_connection_state.dart';
import '../model/openclaw_gateway_status.dart';
import '../model/openclaw_profile.dart';
import '../model/profile_validation_result.dart';
import '../model/runtime_launch_result.dart';

/// OpenClaw Runtime 适配层抽象。
abstract class OpenClawRuntimeAdapter {
  Future<ConfigImportResult> detect();

  Future<ProfileValidationResult> validateProfile(OpenClawProfile profile);

  Future<OpenClawGatewayStatus> getGatewayStatus(OpenClawProfile profile);

  Future<OpenClawGatewayStatus> ensureGatewayRunning(OpenClawProfile profile);

  Future<OpenClawGatewayStatus> restartGateway(OpenClawProfile profile);

  Future<void> stopGateway();

  Future<OpenClawGatewayConnectionState> connectGateway(
    OpenClawProfile profile, {
    OpenClawGatewayConnectionRequest? request,
  });

  Future<void> disconnectGateway();

  OpenClawGatewayConnectionState getGatewayConnectionState();

  Stream<OpenClawGatewayConnectionState> watchGatewayConnectionState();

  Future<RuntimeLaunchResult> startSession(OpenClawProfile profile);

  Future<RuntimeLaunchResult> startGatewayChatSession({
    required OpenClawProfile profile,
    required String message,
    String sessionKey,
  });

  Future<void> sendInput(String sessionId, String input);

  Future<void> stopSession(String sessionId);

  Future<RuntimeLaunchResult> restartSession(
      OpenClawProfile profile, String sessionId);
}
