import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../component/openclaw_runtime/api/openclaw_runtime_adapter.dart';
import '../../../component/openclaw_runtime/impl/default_openclaw_runtime_adapter.dart';
import '../../../component/openclaw_runtime/model/config_import_result.dart';

/// 环境导入仓库。
final onboardingRepositoryProvider = Provider<OnboardingRepository>((Ref ref) {
  return OnboardingRepository(
    runtimeAdapter: ref.watch(openClawRuntimeAdapterProvider),
  );
});

class OnboardingRepository {
  const OnboardingRepository({required this.runtimeAdapter});

  final OpenClawRuntimeAdapter runtimeAdapter;

  Future<ConfigImportResult> detectEnvironment() {
    return runtimeAdapter.detect();
  }
}
