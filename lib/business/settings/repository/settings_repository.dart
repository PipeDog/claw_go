import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../foundation/storage/local_json_storage.dart';
import '../../../foundation/storage/secure_storage_service.dart';
import '../model/app_settings.dart';

/// 设置仓库。
final settingsRepositoryProvider = Provider<SettingsRepository>((Ref ref) {
  return SettingsRepository(
    storage: ref.watch(localJsonStorageProvider),
    secureStorageService: ref.watch(secureStorageServiceProvider),
  );
});

class SettingsRepository {
  const SettingsRepository({
    required LocalJsonStorage storage,
    required SecureStorageService secureStorageService,
  })  : _storage = storage,
        _secureStorageService = secureStorageService;

  final LocalJsonStorage _storage;
  final SecureStorageService _secureStorageService;

  Future<AppSettings> loadSettings() async {
    final Map<String, dynamic> json =
        await _storage.readJson(AppConfig.settingsFileName);
    final String? apiKey =
        await _secureStorageService.read(AppConfig.secureApiKeyName);
    return AppSettings.fromJson(json, apiKey: apiKey);
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _storage.writeJson(AppConfig.settingsFileName, settings.toJson());
    await _secureStorageService.write(
      key: AppConfig.secureApiKeyName,
      value: settings.apiKey,
    );
  }
}
