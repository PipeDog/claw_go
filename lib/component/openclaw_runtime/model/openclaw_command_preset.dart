/// OpenClaw 命令预设。
///
/// 这里接入的是基于官方文档整理出来的真实命令约定，
/// 用于在桌面端为用户提供更明确的“要执行什么”选择。
class OpenClawCommandPreset {
  const OpenClawCommandPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.arguments,
  });

  final String id;
  final String label;
  final String description;
  final List<String> arguments;

  static const String gatewayStatusId = 'gateway_status';
  static const String gatewayRunId = 'gateway_run';
  static const String healthId = 'health';
  static const String agentChatId = 'agent_chat';
  static const String sessionsId = 'sessions';
  static const String logsId = 'logs';
  static const String configureId = 'configure';
  static const String onboardId = 'onboard';

  static const List<OpenClawCommandPreset> values = <OpenClawCommandPreset>[
    OpenClawCommandPreset(
      id: agentChatId,
      label: '直接聊天',
      description:
          '执行 openclaw agent --session-id main --message "<prompt>" --json，与 OpenClaw 直接聊天。',
      arguments: <String>['agent', '--session-id', 'main', '--json'],
    ),
    OpenClawCommandPreset(
      id: gatewayRunId,
      label: '启动 Gateway',
      description: '执行 openclaw gateway run --force --port 18789，在应用内直接启动本地网关。',
      arguments: <String>['gateway', 'run', '--force', '--port', '18789'],
    ),
    OpenClawCommandPreset(
      id: gatewayStatusId,
      label: '网关状态',
      description: '执行 openclaw gateway status --json，查看本地网关与代理状态。',
      arguments: <String>['gateway', 'status', '--json'],
    ),
    OpenClawCommandPreset(
      id: healthId,
      label: '健康检查',
      description: '执行 openclaw health --json，检查当前安装和运行健康度。',
      arguments: <String>['health', '--json'],
    ),
    OpenClawCommandPreset(
      id: sessionsId,
      label: '会话列表',
      description: '执行 openclaw sessions --json，查看当前 CLI 会话信息。',
      arguments: <String>['sessions', '--json'],
    ),
    OpenClawCommandPreset(
      id: logsId,
      label: '查看日志',
      description: '执行 openclaw logs --plain，用纯文本方式查看日志输出。',
      arguments: <String>['logs', '--plain'],
    ),
    OpenClawCommandPreset(
      id: configureId,
      label: '启动配置向导',
      description: '执行 openclaw configure，进入官方配置流程。',
      arguments: <String>['configure'],
    ),
    OpenClawCommandPreset(
      id: onboardId,
      label: '执行 Onboard',
      description: '执行 openclaw onboard --install-daemon，完成环境初始化。',
      arguments: <String>['onboard', '--install-daemon'],
    ),
  ];

  static OpenClawCommandPreset byId(String id) {
    return values.firstWhere(
      (OpenClawCommandPreset item) => item.id == id,
      orElse: () => values.first,
    );
  }
}
