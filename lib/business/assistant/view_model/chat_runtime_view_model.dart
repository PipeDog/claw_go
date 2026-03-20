import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../component/openclaw_runtime/model/openclaw_profile.dart';
import '../../../foundation/base/base_view_model.dart';
import '../../workspace/view_model/workspace_view_model.dart';
import '../model/chat_runtime_option.dart';
import '../repository/chat_runtime_repository.dart';

/// 聊天运行配置 ViewModel。
final chatRuntimeViewModelProvider =
    ChangeNotifierProvider<ChatRuntimeViewModel>((Ref ref) {
  final OpenClawProfile? selectedProfile =
      ref.watch(workspaceViewModelProvider).selectedProfile;
  return ChatRuntimeViewModel(
    repository: const ChatRuntimeRepository(),
    selectedProfile: selectedProfile,
  );
});

class ChatRuntimeViewModel extends BaseViewModel {
  ChatRuntimeViewModel({
    required ChatRuntimeRepository repository,
    required OpenClawProfile? selectedProfile,
  })  : _repository = repository,
        _selectedProfile = selectedProfile {
    unawaited(load());
  }

  final ChatRuntimeRepository _repository;
  final OpenClawProfile? _selectedProfile;

  List<ChatRuntimeOption> _agents = <ChatRuntimeOption>[];
  List<ChatRuntimeOption> _models = <ChatRuntimeOption>[];
  String? _selectedAgentId;
  String? _selectedModelId;

  List<ChatRuntimeOption> get agents =>
      List<ChatRuntimeOption>.unmodifiable(_agents);
  List<ChatRuntimeOption> get models =>
      List<ChatRuntimeOption>.unmodifiable(_models);
  String? get selectedAgentId => _selectedAgentId;
  String? get selectedModelId => _selectedModelId;
  bool get isReady => _selectedProfile != null;

  Future<void> load() async {
    if (_selectedProfile == null) {
      _agents = <ChatRuntimeOption>[];
      _models = <ChatRuntimeOption>[];
      _selectedAgentId = null;
      _selectedModelId = null;
      setErrorMessage('当前还没有可用的 OpenClaw Environment。');
      return;
    }

    setLoading(true);
    clearError();
    try {
      final config = await _repository.loadConfig(_selectedProfile);
      _agents = config.agents;
      _models = config.models;
      _selectedAgentId = config.selectedAgentId;
      _selectedModelId = config.selectedModelId;
      notifyListeners();
    } catch (error) {
      _agents = <ChatRuntimeOption>[];
      _models = <ChatRuntimeOption>[];
      _selectedAgentId = null;
      _selectedModelId = null;
      setErrorMessage('加载聊天配置失败：$error');
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
      _selectedAgentId = agentId;
      notifyListeners();
    } catch (error) {
      setErrorMessage('切换 Agent 失败：$error');
    } finally {
      setLoading(false);
    }
  }

  Future<void> selectModel(String modelId) async {
    if (_selectedProfile == null || modelId == _selectedModelId) {
      return;
    }

    setLoading(true);
    clearError();
    try {
      await _repository.updateSelectedModel(
        profile: _selectedProfile,
        modelId: modelId,
      );
      _selectedModelId = modelId;
      notifyListeners();
    } catch (error) {
      setErrorMessage('切换模型失败：$error');
    } finally {
      setLoading(false);
    }
  }
}
