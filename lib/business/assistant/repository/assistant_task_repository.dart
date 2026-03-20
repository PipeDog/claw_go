import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../foundation/storage/local_json_storage.dart';
import '../model/assistant_task.dart';

/// 任务历史仓库。
final assistantTaskRepositoryProvider =
    Provider<AssistantTaskRepository>((Ref ref) {
  return AssistantTaskRepository(
    storage: ref.watch(localJsonStorageProvider),
  );
});

class AssistantTaskRepository {
  const AssistantTaskRepository({required LocalJsonStorage storage})
      : _storage = storage;

  final LocalJsonStorage _storage;

  Future<List<AssistantTask>> loadTasks() async {
    final Map<String, dynamic> json =
        await _storage.readJson(AppConfig.tasksFileName);
    final List<dynamic> rawTasks =
        json['tasks'] as List<dynamic>? ?? <dynamic>[];

    return rawTasks
        .whereType<Map<String, dynamic>>()
        .map(AssistantTask.fromJson)
        .toList();
  }

  Future<Set<String>> loadFavoriteActionIds() async {
    final Map<String, dynamic> json =
        await _storage.readJson(AppConfig.tasksFileName);
    final List<dynamic> rawIds =
        json['favorite_action_ids'] as List<dynamic>? ?? <dynamic>[];

    return rawIds.map((dynamic item) => item.toString()).toSet();
  }

  Future<void> save({
    required List<AssistantTask> tasks,
    required Set<String> favoriteActionIds,
  }) {
    return _storage.writeJson(
      AppConfig.tasksFileName,
      <String, dynamic>{
        'tasks': tasks.map((AssistantTask item) => item.toJson()).toList(),
        'favorite_action_ids': favoriteActionIds.toList(),
      },
    );
  }
}
