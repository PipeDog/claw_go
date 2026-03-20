import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config/app_config.dart';
import '../storage/local_json_storage.dart';

/// 运行时环境偏好。
class RuntimeEnvironmentPreferences {
  const RuntimeEnvironmentPreferences({
    this.preferredNodePath,
  });

  final String? preferredNodePath;
}

/// 运行时环境偏好读取器。
final runtimeEnvironmentPreferencesReaderProvider =
    Provider<RuntimeEnvironmentPreferencesReader>((Ref ref) {
  return RuntimeEnvironmentPreferencesReader(
    storage: ref.watch(localJsonStorageProvider),
  );
});

class RuntimeEnvironmentPreferencesReader {
  const RuntimeEnvironmentPreferencesReader({
    required LocalJsonStorage storage,
  }) : _storage = storage;

  final LocalJsonStorage _storage;

  Future<RuntimeEnvironmentPreferences> load() async {
    final Map<String, dynamic> json =
        await _storage.readJson(AppConfig.settingsFileName);
    final String? preferredNodePath = json['node_executable_path'] as String?;
    return RuntimeEnvironmentPreferences(
      preferredNodePath:
          preferredNodePath == null || preferredNodePath.trim().isEmpty
              ? null
              : preferredNodePath.trim(),
    );
  }
}
