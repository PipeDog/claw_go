import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../component/openclaw_runtime/api/openclaw_runtime_adapter.dart';
import '../../../component/openclaw_runtime/impl/default_openclaw_runtime_adapter.dart';
import '../../../component/openclaw_runtime/model/openclaw_profile.dart';
import '../../../component/openclaw_runtime/model/profile_validation_result.dart';
import '../../../foundation/storage/local_json_storage.dart';

/// Profile 仓库。
final workspaceRepositoryProvider = Provider<WorkspaceRepository>((Ref ref) {
  return WorkspaceRepository(
    storage: ref.watch(localJsonStorageProvider),
    runtimeAdapter: ref.watch(openClawRuntimeAdapterProvider),
  );
});

class WorkspaceRepository {
  const WorkspaceRepository({
    required LocalJsonStorage storage,
    required OpenClawRuntimeAdapter runtimeAdapter,
  })  : _storage = storage,
        _runtimeAdapter = runtimeAdapter;

  final LocalJsonStorage _storage;
  final OpenClawRuntimeAdapter _runtimeAdapter;

  Future<List<OpenClawProfile>> loadProfiles() async {
    final Map<String, dynamic> json =
        await _storage.readJson(AppConfig.profilesFileName);
    final List<dynamic> rawProfiles =
        json['profiles'] as List<dynamic>? ?? <dynamic>[];

    return rawProfiles
        .whereType<Map<String, dynamic>>()
        .map(OpenClawProfile.fromJson)
        .toList();
  }

  Future<void> saveProfiles(List<OpenClawProfile> profiles) {
    return _storage.writeJson(
      AppConfig.profilesFileName,
      <String, dynamic>{
        'profiles': profiles
            .map((OpenClawProfile profile) => profile.toJson())
            .toList(),
      },
    );
  }

  Future<ProfileValidationResult> validateProfile(OpenClawProfile profile) {
    return _runtimeAdapter.validateProfile(profile);
  }
}
