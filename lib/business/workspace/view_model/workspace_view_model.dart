import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../component/openclaw_runtime/model/openclaw_profile.dart';
import '../../../component/openclaw_runtime/model/profile_validation_result.dart';
import '../../../foundation/base/base_view_model.dart';
import '../../../foundation/utils/id_generator.dart';
import '../repository/workspace_repository.dart';

/// OpenClaw Environment 管理 ViewModel。
final workspaceViewModelProvider =
    ChangeNotifierProvider<WorkspaceViewModel>((Ref ref) {
  return WorkspaceViewModel(
    repository: ref.watch(workspaceRepositoryProvider),
  );
});

class WorkspaceViewModel extends BaseViewModel {
  WorkspaceViewModel({required WorkspaceRepository repository})
      : _repository = repository {
    unawaited(loadProfiles());
  }

  final WorkspaceRepository _repository;
  List<OpenClawProfile> _profiles = <OpenClawProfile>[];
  String? _selectedProfileId;
  ProfileValidationResult? _lastValidationResult;

  List<OpenClawProfile> get profiles => _profiles;
  String? get selectedProfileId => _selectedProfileId;
  ProfileValidationResult? get lastValidationResult => _lastValidationResult;

  OpenClawProfile? get selectedProfile {
    for (final OpenClawProfile profile in _profiles) {
      if (profile.id == _selectedProfileId) {
        return profile;
      }
    }
    return null;
  }

  Future<void> loadProfiles() async {
    setLoading(true);
    clearError();
    try {
      _profiles = await _repository.loadProfiles();
      _selectedProfileId = _profiles
              .firstWhereOrNull((OpenClawProfile item) => item.isDefault)
              ?.id ??
          _profiles.firstOrNull?.id;
      notifyListeners();
    } catch (error) {
      setErrorMessage('加载 OpenClaw Environment 失败：$error');
    } finally {
      setLoading(false);
    }
  }

  Future<ProfileValidationResult> validateProfile(
      OpenClawProfile profile) async {
    setLoading(true);
    clearError();
    try {
      _lastValidationResult = await _repository.validateProfile(profile);
      notifyListeners();
      return _lastValidationResult!;
    } catch (error) {
      final ProfileValidationResult result = ProfileValidationResult(
        isValid: false,
        message: '校验失败：$error',
      );
      _lastValidationResult = result;
      setErrorMessage(result.message);
      return result;
    } finally {
      setLoading(false);
    }
  }

  Future<void> saveProfile(OpenClawProfile profile) async {
    final bool exists =
        _profiles.any((OpenClawProfile item) => item.id == profile.id);
    final OpenClawProfile normalizedProfile = profile.name.trim().isEmpty
        ? profile.copyWith(name: 'Environment ${_profiles.length + 1}')
        : profile;

    if (exists) {
      _profiles = _profiles
          .map((OpenClawProfile item) =>
              item.id == normalizedProfile.id ? normalizedProfile : item)
          .toList();
    } else {
      _profiles = <OpenClawProfile>[..._profiles, normalizedProfile];
    }

    final String defaultId = normalizedProfile.isDefault
        ? normalizedProfile.id
        : (_selectedProfileId ?? normalizedProfile.id);
    _profiles = _applyDefaultProfile(defaultId);
    _selectedProfileId = normalizedProfile.id;
    await _repository.saveProfiles(_profiles);
    notifyListeners();
  }

  Future<void> createEmptyProfile() async {
    final OpenClawProfile profile =
        OpenClawProfile.empty(id: IdGenerator.next('profile'));
    await saveProfile(profile);
  }

  Future<void> deleteProfile(String id) async {
    _profiles =
        _profiles.where((OpenClawProfile profile) => profile.id != id).toList();
    _selectedProfileId = _profiles
            .firstWhereOrNull((OpenClawProfile item) => item.isDefault)
            ?.id ??
        _profiles.firstOrNull?.id;
    await _repository.saveProfiles(_profiles);
    notifyListeners();
  }

  Future<void> selectProfile(String id) async {
    _selectedProfileId = id;
    notifyListeners();
  }

  Future<void> setDefaultProfile(String id) async {
    _profiles = _applyDefaultProfile(id);
    _selectedProfileId = id;
    await _repository.saveProfiles(_profiles);
    notifyListeners();
  }

  List<OpenClawProfile> _applyDefaultProfile(String id) {
    return _profiles
        .map((OpenClawProfile profile) =>
            profile.copyWith(isDefault: profile.id == id))
        .toList();
  }
}

extension _IterableX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? firstWhereOrNull(bool Function(T item) test) {
    for (final T item in this) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }
}
