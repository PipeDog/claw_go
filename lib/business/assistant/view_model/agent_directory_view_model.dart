import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../component/openclaw_runtime/model/openclaw_profile.dart';
import '../../../foundation/base/base_view_model.dart';
import '../../workspace/view_model/workspace_view_model.dart';
import '../model/assistant_agent_directory_item.dart';
import '../repository/chat_runtime_repository.dart';

/// Agent 资产目录 ViewModel。
final agentDirectoryViewModelProvider =
    ChangeNotifierProvider<AgentDirectoryViewModel>((Ref ref) {
  final OpenClawProfile? selectedProfile =
      ref.watch(workspaceViewModelProvider).selectedProfile;
  return AgentDirectoryViewModel(
    repository: const ChatRuntimeRepository(),
    selectedProfile: selectedProfile,
  );
});

class AgentDirectoryViewModel extends BaseViewModel {
  AgentDirectoryViewModel({
    required ChatRuntimeRepository repository,
    required OpenClawProfile? selectedProfile,
  })  : _repository = repository,
        _selectedProfile = selectedProfile {
    unawaited(load());
  }

  final ChatRuntimeRepository _repository;
  final OpenClawProfile? _selectedProfile;

  List<AssistantAgentDirectoryItem> _items = <AssistantAgentDirectoryItem>[];
  String? _selectedAgentId;
  String? _selectedModelLabel;

  List<AssistantAgentDirectoryItem> get items =>
      List<AssistantAgentDirectoryItem>.unmodifiable(_items);
  String? get selectedAgentId => _selectedAgentId;
  String? get selectedModelLabel => _selectedModelLabel;
  OpenClawProfile? get selectedProfile => _selectedProfile;
  bool get hasProfile => _selectedProfile != null;

  AssistantAgentDirectoryItem? get selectedAgent {
    for (final AssistantAgentDirectoryItem item in _items) {
      if (item.id == _selectedAgentId) {
        return item;
      }
    }
    return null;
  }

  int get totalAgents => _items.length;

  int get defaultAgents =>
      _items.where((AssistantAgentDirectoryItem item) => item.isDefault).length;

  Future<void> load() async {
    if (_selectedProfile == null) {
      _items = <AssistantAgentDirectoryItem>[];
      _selectedAgentId = null;
      _selectedModelLabel = null;
      setErrorMessage('当前还没有可用的 OpenClaw Environment。');
      return;
    }

    setLoading(true);
    clearError();
    try {
      final snapshot = await _repository.loadAgentDirectory(_selectedProfile);
      _items = snapshot.items;
      _selectedAgentId = snapshot.selectedAgentId;
      _selectedModelLabel = snapshot.selectedModelLabel;
      notifyListeners();
    } catch (error) {
      _items = <AssistantAgentDirectoryItem>[];
      _selectedAgentId = null;
      _selectedModelLabel = null;
      setErrorMessage('加载 Agent 目录失败：$error');
    } finally {
      setLoading(false);
    }
  }

  Future<void> selectAgent(String agentId) async {
    if (_selectedProfile == null || agentId == _selectedAgentId) {
      return;
    }

    setLoading(true);
    clearError();
    try {
      await _repository.updateSelectedAgent(
        profile: _selectedProfile,
        agentId: agentId,
      );
      await load();
    } catch (error) {
      setErrorMessage('切换 Agent 失败：$error');
      setLoading(false);
    }
  }
}
