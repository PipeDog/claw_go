import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/base/base_view_model.dart';
import '../model/app_settings.dart';
import '../repository/settings_repository.dart';

/// 偏好设置 ViewModel。
final settingsViewModelProvider =
    ChangeNotifierProvider<SettingsViewModel>((Ref ref) {
  return SettingsViewModel(
    repository: ref.watch(settingsRepositoryProvider),
  );
});

class SettingsViewModel extends BaseViewModel {
  SettingsViewModel({required SettingsRepository repository})
      : _repository = repository {
    unawaited(loadSettings());
  }

  final SettingsRepository _repository;
  AppSettings _settings = AppSettings.initial();

  AppSettings get settings => _settings;

  Future<void> loadSettings() async {
    setLoading(true);
    clearError();
    try {
      _settings = await _repository.loadSettings();
      notifyListeners();
    } catch (error) {
      setErrorMessage('加载设置失败：$error');
    } finally {
      setLoading(false);
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    setLoading(true);
    clearError();
    try {
      _settings = settings;
      await _repository.saveSettings(settings);
      notifyListeners();
    } catch (error) {
      setErrorMessage('保存设置失败：$error');
    } finally {
      setLoading(false);
    }
  }
}
