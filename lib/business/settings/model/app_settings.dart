/// 应用偏好设置。
class AppSettings {
  const AppSettings({
    required this.defaultShell,
    required this.logLevel,
    required this.reopenLastSession,
    required this.themeMode,
    required this.localeCode,
    this.nodeExecutablePath,
    this.apiKey,
  });

  final String defaultShell;
  final String logLevel;
  final bool reopenLastSession;
  final String themeMode;
  final String localeCode;
  final String? nodeExecutablePath;
  final String? apiKey;

  factory AppSettings.initial() {
    return const AppSettings(
      defaultShell: '/bin/zsh',
      logLevel: 'info',
      reopenLastSession: true,
      themeMode: 'system',
      localeCode: 'zh',
      nodeExecutablePath: null,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json, {String? apiKey}) {
    return AppSettings(
      defaultShell: json['default_shell'] as String? ?? '/bin/zsh',
      logLevel: json['log_level'] as String? ?? 'info',
      reopenLastSession: json['reopen_last_session'] as bool? ?? true,
      themeMode: json['theme_mode'] as String? ?? 'system',
      localeCode: json['locale_code'] as String? ?? 'zh',
      nodeExecutablePath: json['node_executable_path'] as String?,
      apiKey: apiKey,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'default_shell': defaultShell,
      'log_level': logLevel,
      'reopen_last_session': reopenLastSession,
      'theme_mode': themeMode,
      'locale_code': localeCode,
      'node_executable_path': nodeExecutablePath,
    };
  }

  AppSettings copyWith({
    String? defaultShell,
    String? logLevel,
    bool? reopenLastSession,
    String? themeMode,
    String? localeCode,
    String? nodeExecutablePath,
    String? apiKey,
    bool clearApiKey = false,
  }) {
    return AppSettings(
      defaultShell: defaultShell ?? this.defaultShell,
      logLevel: logLevel ?? this.logLevel,
      reopenLastSession: reopenLastSession ?? this.reopenLastSession,
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      nodeExecutablePath: nodeExecutablePath ?? this.nodeExecutablePath,
      apiKey: clearApiKey ? null : apiKey ?? this.apiKey,
    );
  }
}
