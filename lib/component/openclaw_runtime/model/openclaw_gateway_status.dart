/// OpenClaw Gateway 运行状态。
class OpenClawGatewayStatus {
  const OpenClawGatewayStatus({
    required this.isRunning,
    required this.message,
    this.url,
    this.pid,
    this.startedByApp = false,
    this.configPath,
    this.authSummary,
  });

  final bool isRunning;
  final String message;
  final String? url;
  final int? pid;
  final bool startedByApp;
  final String? configPath;
  final String? authSummary;
}
