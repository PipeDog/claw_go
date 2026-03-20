/// 应用级静态配置。
///
/// 这里放置不会频繁变动的应用名、存储文件名、CLI 候选命令等常量，
/// 方便各业务模块统一引用，避免在页面或 ViewModel 中散落硬编码。
class AppConfig {
  const AppConfig._();

  /// 应用名称。
  static const String appName = 'Claw Go';

  /// 应用副标题。
  static const String appSubtitle = 'Desktop Control';

  /// 首页主标题。
  static const String homeHeadline = 'Chat';

  /// 本地保存 Profile 的文件名。
  static const String profilesFileName = 'profiles.json';

  /// 本地保存偏好设置的文件名。
  static const String settingsFileName = 'settings.json';

  /// 本地保存任务历史的文件名。
  static const String tasksFileName = 'tasks.json';

  /// 安全存储中保存 API Key 的键名。
  static const String secureApiKeyName = 'openclaw_api_key';

  /// 安全存储中保存 Gateway Token 的键名。
  static const String secureGatewayTokenName = 'openclaw_gateway_token';

  /// 自动探测时尝试的 OpenClaw 命令名。
  static const List<String> openClawExecutableCandidates = <String>[
    'openclaw',
    'openclaw-cli',
    'claw',
  ];

  /// 在无法通过 CLI 自动获取配置路径时尝试的默认配置候选路径。
  static const List<String> openClawConfigCandidates = <String>[
    '.openclaw/config.json',
    '.config/openclaw/config.json',
    '.claw/config.json',
  ];

  /// OpenClaw 当前要求的最低 Node 版本。
  static const String minimumNodeVersion = '22.16.0';
}
