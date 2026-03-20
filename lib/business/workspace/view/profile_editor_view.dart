import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../component/openclaw_runtime/model/openclaw_command_preset.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../model/environment_glossary_catalog.dart';
import '../model/environment_glossary_item.dart';
import 'term_info_button_view.dart';

/// Environment 编辑表单。
class ProfileEditorView extends StatelessWidget {
  const ProfileEditorView({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.cliPathController,
    required this.workingDirectoryController,
    required this.configPathController,
    required this.customArgsController,
    required this.selectedPresetId,
    required this.onPresetChanged,
    required this.isDefault,
    required this.onDefaultChanged,
    required this.onValidate,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController cliPathController;
  final TextEditingController workingDirectoryController;
  final TextEditingController configPathController;
  final TextEditingController customArgsController;
  final String selectedPresetId;
  final ValueChanged<String?> onPresetChanged;
  final bool isDefault;
  final ValueChanged<bool> onDefaultChanged;
  final VoidCallback onValidate;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final OpenClawCommandPreset selectedPreset =
        OpenClawCommandPreset.byId(selectedPresetId);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.sectionMutedOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.text('profiles.editor_title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.text('profiles.editor_subtitle'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      label: _FieldLabel(
                        text: l10n.text('profiles.name'),
                        item: EnvironmentGlossaryCatalog.byId(
                          EnvironmentGlossaryCatalog.environmentNameId,
                        ),
                      ),
                    ),
                    validator: (String? value) {
                      final String text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return l10n.text('profiles.name_required');
                      }
                      if (text.length < 2) {
                        return l10n.text('profiles.name_too_short');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: cliPathController,
                    decoration: InputDecoration(
                      label: _FieldLabel(
                        text: l10n.text('profiles.cli_path'),
                        item: EnvironmentGlossaryCatalog.byId(
                          EnvironmentGlossaryCatalog.cliPathId,
                        ),
                      ),
                      hintText: l10n.text('profiles.cli_path_hint'),
                    ),
                    validator: (String? value) {
                      if ((value ?? '').trim().isEmpty) {
                        return l10n.text('profiles.cli_path_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: workingDirectoryController,
                    decoration: InputDecoration(
                      label: _FieldLabel(
                        text: l10n.text('profiles.workdir'),
                        item: EnvironmentGlossaryCatalog.byId(
                          EnvironmentGlossaryCatalog.workingDirectoryId,
                        ),
                      ),
                      hintText: l10n.text('profiles.workdir_hint'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: configPathController,
                    decoration: InputDecoration(
                      label: _FieldLabel(
                        text: l10n.text('profiles.config_path'),
                        item: EnvironmentGlossaryCatalog.byId(
                          EnvironmentGlossaryCatalog.configFileId,
                        ),
                      ),
                      hintText: l10n.text('profiles.config_path_hint'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPresetId,
                    decoration: InputDecoration(
                      label: _FieldLabel(
                        text: l10n.text('profiles.default_preset'),
                        item: EnvironmentGlossaryCatalog.byId(
                          EnvironmentGlossaryCatalog.defaultPresetId,
                        ),
                      ),
                    ),
                    items: OpenClawCommandPreset.values
                        .map(
                          (OpenClawCommandPreset preset) =>
                              DropdownMenuItem<String>(
                            value: preset.id,
                            child: Text(preset.label),
                          ),
                        )
                        .toList(),
                    onChanged: onPresetChanged,
                  ),
                  const SizedBox(height: 8),
                  Text(selectedPreset.description),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: customArgsController,
                    decoration: InputDecoration(
                      label: _FieldLabel(
                        text: l10n.text('profiles.extra_args'),
                        item: EnvironmentGlossaryCatalog.byId(
                          EnvironmentGlossaryCatalog.extraArgumentsId,
                        ),
                      ),
                      hintText: l10n.text('profiles.extra_args_hint'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        l10n.text('environment.related_concepts'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      _ConceptChip(
                        text: l10n.text('environment.glossary.gateway.term'),
                        item: EnvironmentGlossaryCatalog.byId(
                          EnvironmentGlossaryCatalog.gatewayId,
                        ),
                      ),
                      _ConceptChip(
                        text: l10n.text('environment.glossary.agent.term'),
                        item: EnvironmentGlossaryCatalog.byId(
                          EnvironmentGlossaryCatalog.agentId,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isDefault,
                    title: Text(l10n.text('profiles.set_default')),
                    onChanged: onDefaultChanged,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: onValidate,
                        icon: const Icon(Icons.verified_outlined),
                        label: Text(l10n.text('profiles.validate')),
                      ),
                      FilledButton.icon(
                        onPressed: onSave,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(l10n.text('profiles.validate_save')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.text,
    required this.item,
  });

  final String text;
  final EnvironmentGlossaryItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(text),
        const SizedBox(width: 4),
        TermInfoButtonView(item: item),
      ],
    );
  }
}

class _ConceptChip extends StatelessWidget {
  const _ConceptChip({
    required this.text,
    required this.item,
  });

  final String text;
  final EnvironmentGlossaryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(text),
          const SizedBox(width: 4),
          TermInfoButtonView(item: item),
        ],
      ),
    );
  }
}
