import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../component/openclaw_runtime/model/config_import_result.dart';
import '../../../foundation/base/base_view_model.dart';
import '../repository/onboarding_repository.dart';

/// 环境导入页面的 ViewModel。
final onboardingViewModelProvider =
    ChangeNotifierProvider<OnboardingViewModel>((Ref ref) {
  return OnboardingViewModel(
    repository: ref.watch(onboardingRepositoryProvider),
  );
});

class OnboardingViewModel extends BaseViewModel {
  OnboardingViewModel({required OnboardingRepository repository})
      : _repository = repository {
    unawaited(detectEnvironment());
  }

  final OnboardingRepository _repository;
  ConfigImportResult? _detectionResult;

  ConfigImportResult? get detectionResult => _detectionResult;

  Future<void> detectEnvironment() async {
    setLoading(true);
    clearError();
    try {
      _detectionResult = await _repository.detectEnvironment();
      notifyListeners();
    } catch (error) {
      setErrorMessage('自动探测失败：$error');
    } finally {
      setLoading(false);
    }
  }
}
