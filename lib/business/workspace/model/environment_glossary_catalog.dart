import 'environment_glossary_item.dart';

/// OpenClaw Environment 术语目录。
class EnvironmentGlossaryCatalog {
  const EnvironmentGlossaryCatalog._();

  static const String environmentId = 'environment';
  static const String openClawProfileId = 'openclaw_profile';
  static const String environmentNameId = 'environment_name';
  static const String cliPathId = 'cli_path';
  static const String configFileId = 'config_file';
  static const String workingDirectoryId = 'working_directory';
  static const String defaultPresetId = 'default_preset';
  static const String extraArgumentsId = 'extra_arguments';
  static const String gatewayId = 'gateway';
  static const String agentId = 'agent';
  static const String workspaceId = 'workspace';
  static const String modelProviderId = 'model_provider';
  static const String authProfileId = 'auth_profile';
  static const String sessionId = 'session';

  static const List<EnvironmentGlossaryItem> items = <EnvironmentGlossaryItem>[
    EnvironmentGlossaryItem(
      id: environmentId,
      termKey: 'environment.glossary.environment.term',
      descriptionKey: 'environment.glossary.environment.desc',
      mappingKey: 'environment.glossary.environment.mapping',
      sourceType: EnvironmentGlossarySourceType.clawGo,
    ),
    EnvironmentGlossaryItem(
      id: openClawProfileId,
      termKey: 'environment.glossary.openclaw_profile.term',
      descriptionKey: 'environment.glossary.openclaw_profile.desc',
      mappingKey: 'environment.glossary.openclaw_profile.mapping',
      sourceType: EnvironmentGlossarySourceType.openClaw,
    ),
    EnvironmentGlossaryItem(
      id: environmentNameId,
      termKey: 'environment.glossary.environment_name.term',
      descriptionKey: 'environment.glossary.environment_name.desc',
      mappingKey: 'environment.glossary.environment_name.mapping',
      sourceType: EnvironmentGlossarySourceType.clawGo,
    ),
    EnvironmentGlossaryItem(
      id: cliPathId,
      termKey: 'environment.glossary.cli_path.term',
      descriptionKey: 'environment.glossary.cli_path.desc',
      mappingKey: 'environment.glossary.cli_path.mapping',
      sourceType: EnvironmentGlossarySourceType.clawGo,
    ),
    EnvironmentGlossaryItem(
      id: configFileId,
      termKey: 'environment.glossary.config_file.term',
      descriptionKey: 'environment.glossary.config_file.desc',
      mappingKey: 'environment.glossary.config_file.mapping',
      sourceType: EnvironmentGlossarySourceType.mixed,
    ),
    EnvironmentGlossaryItem(
      id: workingDirectoryId,
      termKey: 'environment.glossary.working_directory.term',
      descriptionKey: 'environment.glossary.working_directory.desc',
      mappingKey: 'environment.glossary.working_directory.mapping',
      sourceType: EnvironmentGlossarySourceType.clawGo,
    ),
    EnvironmentGlossaryItem(
      id: defaultPresetId,
      termKey: 'environment.glossary.default_preset.term',
      descriptionKey: 'environment.glossary.default_preset.desc',
      mappingKey: 'environment.glossary.default_preset.mapping',
      sourceType: EnvironmentGlossarySourceType.clawGo,
    ),
    EnvironmentGlossaryItem(
      id: extraArgumentsId,
      termKey: 'environment.glossary.extra_arguments.term',
      descriptionKey: 'environment.glossary.extra_arguments.desc',
      mappingKey: 'environment.glossary.extra_arguments.mapping',
      sourceType: EnvironmentGlossarySourceType.clawGo,
    ),
    EnvironmentGlossaryItem(
      id: gatewayId,
      termKey: 'environment.glossary.gateway.term',
      descriptionKey: 'environment.glossary.gateway.desc',
      mappingKey: 'environment.glossary.gateway.mapping',
      sourceType: EnvironmentGlossarySourceType.openClaw,
    ),
    EnvironmentGlossaryItem(
      id: agentId,
      termKey: 'environment.glossary.agent.term',
      descriptionKey: 'environment.glossary.agent.desc',
      mappingKey: 'environment.glossary.agent.mapping',
      sourceType: EnvironmentGlossarySourceType.openClaw,
    ),
    EnvironmentGlossaryItem(
      id: workspaceId,
      termKey: 'environment.glossary.workspace.term',
      descriptionKey: 'environment.glossary.workspace.desc',
      mappingKey: 'environment.glossary.workspace.mapping',
      sourceType: EnvironmentGlossarySourceType.openClaw,
    ),
    EnvironmentGlossaryItem(
      id: modelProviderId,
      termKey: 'environment.glossary.model_provider.term',
      descriptionKey: 'environment.glossary.model_provider.desc',
      mappingKey: 'environment.glossary.model_provider.mapping',
      sourceType: EnvironmentGlossarySourceType.openClaw,
    ),
    EnvironmentGlossaryItem(
      id: authProfileId,
      termKey: 'environment.glossary.auth_profile.term',
      descriptionKey: 'environment.glossary.auth_profile.desc',
      mappingKey: 'environment.glossary.auth_profile.mapping',
      sourceType: EnvironmentGlossarySourceType.openClaw,
    ),
    EnvironmentGlossaryItem(
      id: sessionId,
      termKey: 'environment.glossary.session.term',
      descriptionKey: 'environment.glossary.session.desc',
      mappingKey: 'environment.glossary.session.mapping',
      sourceType: EnvironmentGlossarySourceType.mixed,
    ),
  ];

  static EnvironmentGlossaryItem byId(String id) {
    return items.firstWhere(
      (EnvironmentGlossaryItem item) => item.id == id,
      orElse: () => items.first,
    );
  }
}
