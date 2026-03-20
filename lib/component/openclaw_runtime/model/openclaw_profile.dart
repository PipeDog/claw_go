import 'config_import_result.dart';
import 'openclaw_command_preset.dart';

/// OpenClaw 启动配置。
class OpenClawProfile {
  static const String externalSourceType = 'external';

  const OpenClawProfile({
    required this.id,
    required this.name,
    required this.cliPath,
    required this.workingDirectory,
    required this.configPath,
    required this.commandPresetId,
    required this.customArgs,
    required this.envVars,
    this.sourceType = externalSourceType,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String cliPath;
  final String workingDirectory;
  final String configPath;

  /// 当前 Profile 默认执行的命令预设。
  final String commandPresetId;

  /// 用户额外补充的参数。
  final String customArgs;

  final Map<String, String> envVars;
  final String sourceType;
  final bool isDefault;

  factory OpenClawProfile.empty({required String id}) {
    return OpenClawProfile(
      id: id,
      name: '新建 OpenClaw Environment',
      cliPath: '',
      workingDirectory: '',
      configPath: '',
      commandPresetId: OpenClawCommandPreset.gatewayStatusId,
      customArgs: '',
      envVars: const <String, String>{},
      sourceType: externalSourceType,
    );
  }

  factory OpenClawProfile.fromDetection({
    required String id,
    required ConfigImportResult detection,
  }) {
    return OpenClawProfile(
      id: id,
      name: '导入的 OpenClaw Environment',
      cliPath: detection.primaryCliPath ?? '',
      workingDirectory: detection.envHints['PWD'] ?? '',
      configPath: detection.primaryConfigPath ?? '',
      commandPresetId: OpenClawCommandPreset.gatewayStatusId,
      customArgs: '',
      envVars: const <String, String>{},
      sourceType: externalSourceType,
      isDefault: true,
    );
  }

  factory OpenClawProfile.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawEnvVars =
        (json['env_vars'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return OpenClawProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      cliPath: json['cli_path'] as String? ?? '',
      workingDirectory: json['working_directory'] as String? ?? '',
      configPath: json['config_path'] as String? ?? '',
      commandPresetId: json['command_preset_id'] as String? ??
          OpenClawCommandPreset.gatewayStatusId,
      customArgs: json['custom_args'] as String? ?? '',
      envVars: rawEnvVars.map(
        (String key, dynamic value) => MapEntry(key, value.toString()),
      )..remove('PATH'),
      sourceType: json['source_type'] as String? ?? externalSourceType,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'cli_path': cliPath,
      'working_directory': workingDirectory,
      'config_path': configPath,
      'command_preset_id': commandPresetId,
      'custom_args': customArgs,
      'env_vars': envVars,
      'source_type': sourceType,
      'is_default': isDefault,
    };
  }

  OpenClawProfile copyWith({
    String? id,
    String? name,
    String? cliPath,
    String? workingDirectory,
    String? configPath,
    String? commandPresetId,
    String? customArgs,
    Map<String, String>? envVars,
    String? sourceType,
    bool? isDefault,
  }) {
    return OpenClawProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      cliPath: cliPath ?? this.cliPath,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      configPath: configPath ?? this.configPath,
      commandPresetId: commandPresetId ?? this.commandPresetId,
      customArgs: customArgs ?? this.customArgs,
      envVars: envVars ?? this.envVars,
      sourceType: sourceType ?? this.sourceType,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
