import 'dart:convert';
import 'dart:io';

import '../../../component/openclaw_runtime/model/openclaw_profile.dart';
import '../model/assistant_agent_directory_item.dart';
import '../model/assistant_agent_directory_snapshot.dart';
import '../model/chat_runtime_config.dart';
import '../model/chat_runtime_option.dart';

/// 聊天运行配置仓库。
///
/// 负责读取并更新 openclaw.json 中与聊天相关的 Agent / 模型配置。
class ChatRuntimeRepository {
  const ChatRuntimeRepository();

  Future<ChatRuntimeConfig> loadConfig(OpenClawProfile profile) async {
    final File file = _resolveConfigFile(profile);
    if (!file.existsSync()) {
      throw StateError('未找到 OpenClaw 配置文件：${file.path}');
    }

    final Map<String, dynamic> root = await _readRootMap(file);
    final List<ChatRuntimeOption> agents = _parseAgents(root);
    final List<ChatRuntimeOption> models = _parseModels(root);

    return ChatRuntimeConfig(
      agents: agents,
      models: models,
      selectedAgentId: _resolveSelectedAgentId(root, agents),
      selectedModelId: _resolveSelectedModelId(root, models),
    );
  }

  Future<AssistantAgentDirectorySnapshot> loadAgentDirectory(
    OpenClawProfile profile,
  ) async {
    final File file = _resolveConfigFile(profile);
    if (!file.existsSync()) {
      throw StateError('未找到 OpenClaw 配置文件：${file.path}');
    }

    final Map<String, dynamic> root = await _readRootMap(file);
    final List<ChatRuntimeOption> models = _parseModels(root);
    final String? selectedModelId = _resolveSelectedModelId(root, models);
    final Map<String, String> modelLabelById = <String, String>{
      for (final ChatRuntimeOption item in models) item.id: item.label,
    };
    final List<AssistantAgentDirectoryItem> items = _parseAgentDirectoryItems(
      root,
      selectedModelId: selectedModelId,
      modelLabelById: modelLabelById,
    );

    return AssistantAgentDirectorySnapshot(
      items: items,
      selectedAgentId: _resolveSelectedAgentId(
        root,
        items
            .map(
              (AssistantAgentDirectoryItem item) => ChatRuntimeOption(
                id: item.id,
                label: item.displayLabel,
              ),
            )
            .toList(),
      ),
      selectedModelId: selectedModelId,
      selectedModelLabel: selectedModelId == null
          ? null
          : modelLabelById[selectedModelId] ?? selectedModelId,
    );
  }

  Future<void> updateSelectedAgent({
    required OpenClawProfile profile,
    required String agentId,
  }) async {
    final File file = _resolveConfigFile(profile);
    final Map<String, dynamic> root = await _readRootMap(file);
    final Map<String, dynamic> agents = Map<String, dynamic>.from(
        root['agents'] as Map? ?? <String, dynamic>{});
    final List<dynamic> rawList = List<dynamic>.from(
      agents['list'] as List<dynamic>? ?? <dynamic>[],
    );

    final List<Map<String, dynamic>> normalized = rawList.map((dynamic item) {
      return Map<String, dynamic>.from(item as Map);
    }).toList();

    bool found = false;
    for (final Map<String, dynamic> item in normalized) {
      final String id = item['id']?.toString().trim() ?? '';
      final bool isSelected = id == agentId;
      if (isSelected) {
        found = true;
        item['default'] = true;
      } else {
        item.remove('default');
      }
    }

    if (!found) {
      throw StateError('未找到 Agent：$agentId');
    }

    agents['list'] = normalized;
    root['agents'] = agents;
    await _writeRootMap(file, root);
  }

  Future<void> updateSelectedModel({
    required OpenClawProfile profile,
    required String modelId,
  }) async {
    final File file = _resolveConfigFile(profile);
    final Map<String, dynamic> root = await _readRootMap(file);
    final Map<String, dynamic> agents = Map<String, dynamic>.from(
        root['agents'] as Map? ?? <String, dynamic>{});
    final Map<String, dynamic> defaults = Map<String, dynamic>.from(
      agents['defaults'] as Map? ?? <String, dynamic>{},
    );
    final Map<String, dynamic> model = Map<String, dynamic>.from(
      defaults['model'] as Map? ?? <String, dynamic>{},
    );

    model['primary'] = modelId;
    defaults['model'] = model;
    agents['defaults'] = defaults;
    root['agents'] = agents;

    await _writeRootMap(file, root);
  }

  File _resolveConfigFile(OpenClawProfile profile) {
    final String configuredPath = profile.configPath.trim();
    if (configuredPath.isEmpty) {
      throw StateError('当前 Environment 未配置 openclaw.json 路径。');
    }
    return File(_expandHomePath(configuredPath));
  }

  Future<Map<String, dynamic>> _readRootMap(File file) async {
    final Object? decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw StateError('OpenClaw 配置文件格式不正确。');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> _writeRootMap(File file, Map<String, dynamic> root) async {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(root)}\n');
  }

  List<ChatRuntimeOption> _parseAgents(Map<String, dynamic> root) {
    final Map<String, dynamic> agents = Map<String, dynamic>.from(
        root['agents'] as Map? ?? <String, dynamic>{});
    final List<dynamic> rawList =
        List<dynamic>.from(agents['list'] as List<dynamic>? ?? <dynamic>[]);

    return rawList
        .map((dynamic item) {
          final Map<String, dynamic> agent =
              Map<String, dynamic>.from(item as Map);
          final String id = agent['id']?.toString().trim() ?? '';
          final String name = agent['name']?.toString().trim() ?? '';
          return ChatRuntimeOption(
            id: id,
            label: name.isEmpty ? id : '$name · $id',
          );
        })
        .where((ChatRuntimeOption item) => item.id.isNotEmpty)
        .toList();
  }

  List<ChatRuntimeOption> _parseModels(Map<String, dynamic> root) {
    final Map<String, dynamic> models = Map<String, dynamic>.from(
        root['models'] as Map? ?? <String, dynamic>{});
    final Map<String, dynamic> providers = Map<String, dynamic>.from(
      models['providers'] as Map? ?? <String, dynamic>{},
    );
    final List<ChatRuntimeOption> items = <ChatRuntimeOption>[];

    for (final MapEntry<String, dynamic> entry in providers.entries) {
      final String providerId = entry.key.trim();
      final Map<String, dynamic> provider = Map<String, dynamic>.from(
        entry.value as Map,
      );
      final List<dynamic> rawModels = List<dynamic>.from(
          provider['models'] as List<dynamic>? ?? <dynamic>[]);

      for (final dynamic rawModel in rawModels) {
        final Map<String, dynamic> model = Map<String, dynamic>.from(
          rawModel as Map,
        );
        final String modelId = model['id']?.toString().trim() ?? '';
        if (providerId.isEmpty || modelId.isEmpty) {
          continue;
        }
        final String name = model['name']?.toString().trim() ?? '';
        items.add(
          ChatRuntimeOption(
            id: '$providerId/$modelId',
            label: name.isEmpty ? '$providerId/$modelId' : name,
          ),
        );
      }
    }

    return items;
  }

  List<AssistantAgentDirectoryItem> _parseAgentDirectoryItems(
    Map<String, dynamic> root, {
    required String? selectedModelId,
    required Map<String, String> modelLabelById,
  }) {
    final Map<String, dynamic> agents = Map<String, dynamic>.from(
      root['agents'] as Map? ?? <String, dynamic>{},
    );
    final Map<String, dynamic> defaults = Map<String, dynamic>.from(
      agents['defaults'] as Map? ?? <String, dynamic>{},
    );
    final String defaultWorkspace =
        defaults['workspace']?.toString().trim() ?? '';
    final List<dynamic> rawList =
        List<dynamic>.from(agents['list'] as List<dynamic>? ?? <dynamic>[]);
    final String? selectedAgentId = _resolveSelectedAgentId(
      root,
      rawList
          .map((dynamic item) {
            final Map<String, dynamic> agent =
                Map<String, dynamic>.from(item as Map);
            final String id = agent['id']?.toString().trim() ?? '';
            final String name = agent['name']?.toString().trim() ?? '';
            return ChatRuntimeOption(
              id: id,
              label: name.isEmpty ? id : name,
            );
          })
          .where((ChatRuntimeOption item) => item.id.isNotEmpty)
          .toList(),
    );

    return rawList
        .map((dynamic item) {
          final Map<String, dynamic> agent =
              Map<String, dynamic>.from(item as Map);
          final String id = agent['id']?.toString().trim() ?? '';
          if (id.isEmpty) {
            return null;
          }
          final String name = agent['name']?.toString().trim() ?? id;
          final String workspace =
              agent['workspace']?.toString().trim() ?? defaultWorkspace;
          final bool isDefault = agent['default'] == true;
          final String modelId = _resolveAgentModelId(
            agent: agent,
            fallbackModelId: selectedModelId,
          );
          final String modelLabel =
              modelLabelById[modelId] ?? (modelId.isEmpty ? '未配置' : modelId);
          final String? description = _resolveAgentDescription(agent);
          return AssistantAgentDirectoryItem(
            id: id,
            name: name,
            displayLabel: name == id ? id : '$name · $id',
            workspace: workspace,
            modelId: modelId,
            modelLabel: modelLabel,
            isDefault: isDefault,
            isSelected: id == selectedAgentId,
            description: description,
          );
        })
        .whereType<AssistantAgentDirectoryItem>()
        .toList();
  }

  String? _resolveSelectedAgentId(
    Map<String, dynamic> root,
    List<ChatRuntimeOption> agents,
  ) {
    final Map<String, dynamic> agentRoot = Map<String, dynamic>.from(
        root['agents'] as Map? ?? <String, dynamic>{});
    final List<dynamic> rawList =
        List<dynamic>.from(agentRoot['list'] as List<dynamic>? ?? <dynamic>[]);

    for (final dynamic item in rawList) {
      final Map<String, dynamic> agent = Map<String, dynamic>.from(item as Map);
      if (agent['default'] == true) {
        final String id = agent['id']?.toString().trim() ?? '';
        if (id.isNotEmpty) {
          return id;
        }
      }
    }

    return agents.isEmpty ? null : agents.first.id;
  }

  String _resolveAgentModelId({
    required Map<String, dynamic> agent,
    required String? fallbackModelId,
  }) {
    final Object? rawModel = agent['model'];
    if (rawModel is String && rawModel.trim().isNotEmpty) {
      return rawModel.trim();
    }
    if (rawModel is Map) {
      final Map<String, dynamic> model = Map<String, dynamic>.from(rawModel);
      final String primary = model['primary']?.toString().trim() ?? '';
      if (primary.isNotEmpty) {
        return primary;
      }
    }
    return fallbackModelId ?? '';
  }

  String? _resolveAgentDescription(Map<String, dynamic> agent) {
    final List<String?> candidates = <String?>[
      agent['description']?.toString(),
      agent['summary']?.toString(),
      agent['prompt']?.toString(),
      agent['instruction']?.toString(),
      agent['instructions']?.toString(),
      agent['system_prompt']?.toString(),
    ];
    for (final String? candidate in candidates) {
      final String trimmed = candidate?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  String? _resolveSelectedModelId(
    Map<String, dynamic> root,
    List<ChatRuntimeOption> models,
  ) {
    final Map<String, dynamic> agents = Map<String, dynamic>.from(
        root['agents'] as Map? ?? <String, dynamic>{});
    final Map<String, dynamic> defaults = Map<String, dynamic>.from(
      agents['defaults'] as Map? ?? <String, dynamic>{},
    );
    final Map<String, dynamic> model = Map<String, dynamic>.from(
      defaults['model'] as Map? ?? <String, dynamic>{},
    );
    final String primary = model['primary']?.toString().trim() ?? '';
    if (primary.isNotEmpty) {
      return primary;
    }
    return models.isEmpty ? null : models.first.id;
  }

  String _expandHomePath(String value) {
    if (value == '~') {
      return Platform.environment['HOME'] ?? value;
    }
    if (value.startsWith('~/')) {
      final String? home = Platform.environment['HOME'];
      if (home == null || home.isEmpty) {
        return value;
      }
      return '$home/${value.substring(2)}';
    }
    return value;
  }
}
