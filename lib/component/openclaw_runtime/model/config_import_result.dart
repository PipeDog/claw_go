import 'node_runtime_info.dart';
import 'openclaw_gateway_status.dart';

/// 自动探测结果。
class ConfigImportResult {
  const ConfigImportResult({
    this.detectedCliPaths = const <String>[],
    this.detectedConfigPaths = const <String>[],
    this.envHints = const <String, String>{},
    this.warnings = const <String>[],
    this.cliVersion,
    this.configValid,
    this.configValidationMessage,
    this.nodeRuntimeInfo,
    this.gatewayStatus,
  });

  final List<String> detectedCliPaths;
  final List<String> detectedConfigPaths;
  final Map<String, String> envHints;
  final List<String> warnings;
  final String? cliVersion;
  final bool? configValid;
  final String? configValidationMessage;
  final NodeRuntimeInfo? nodeRuntimeInfo;
  final OpenClawGatewayStatus? gatewayStatus;

  String? get primaryCliPath =>
      detectedCliPaths.isEmpty ? null : detectedCliPaths.first;

  String? get primaryConfigPath =>
      detectedConfigPaths.isEmpty ? null : detectedConfigPaths.first;

  bool get isOpenClawDetected => primaryCliPath != null;

  bool get isNodeSatisfied => nodeRuntimeInfo?.isSatisfied ?? false;

  bool get isConfigValid => configValid == true;

  bool get isGatewayReady => gatewayStatus?.isRunning ?? false;

  bool get requiresManualFix =>
      !isOpenClawDetected || !isNodeSatisfied || !isConfigValid;
}
