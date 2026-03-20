import 'node_runtime_info.dart';

/// Profile 校验结果。
class ProfileValidationResult {
  const ProfileValidationResult({
    required this.isValid,
    required this.message,
    this.cliVersion,
    this.configValidationMessage,
    this.nodeRuntimeInfo,
  });

  final bool isValid;
  final String message;
  final String? cliVersion;
  final String? configValidationMessage;
  final NodeRuntimeInfo? nodeRuntimeInfo;
}
