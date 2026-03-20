import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_theme.dart';
import '../../../component/openclaw_runtime/model/openclaw_command_preset.dart';
import '../../../component/openclaw_runtime/model/openclaw_profile.dart';
import '../../../component/openclaw_runtime/model/profile_validation_result.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../../../foundation/utils/id_generator.dart';
import '../view/environment_glossary_panel_view.dart';
import '../view/profile_editor_view.dart';
import '../view_model/workspace_view_model.dart';

/// OpenClaw Environment 管理页面。
class WorkspacePage extends ConsumerStatefulWidget {
  const WorkspacePage({
    super.key,
    this.showPageHeader = true,
    this.padding = const EdgeInsets.all(24),
  });

  /// 是否展示页面主标题与描述。
  final bool showPageHeader;

  /// 内容区域内边距。
  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage> {
  static const double _kCompactBreakpoint = 1080;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cliPathController = TextEditingController();
  final TextEditingController _workingDirectoryController =
      TextEditingController();
  final TextEditingController _configPathController = TextEditingController();
  final TextEditingController _customArgsController = TextEditingController();

  String? _editingId;
  bool _isDefault = false;
  String _selectedPresetId = OpenClawCommandPreset.gatewayStatusId;

  @override
  void dispose() {
    _nameController.dispose();
    _cliPathController.dispose();
    _workingDirectoryController.dispose();
    _configPathController.dispose();
    _customArgsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(workspaceViewModelProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final panelSecondary = AppTheme.panelSecondaryOf(context);
    final borderColor = AppTheme.borderOf(context);
    final OpenClawProfile? selectedProfile = viewModel.selectedProfile;

    if (selectedProfile != null && _editingId != selectedProfile.id) {
      _hydrateForm(selectedProfile);
    }

    return SingleChildScrollView(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.showPageHeader) ...<Widget>[
            Text(
              l10n.text('profiles.title'),
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.text('profiles.description'),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
          ],
          const EnvironmentGlossaryPanelView(),
          const SizedBox(height: 20),
          if (viewModel.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                viewModel.errorMessage!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool isCompact = constraints.maxWidth < _kCompactBreakpoint;
              final Widget listSection = _WorkspaceSection(
                title: l10n.text('profiles.saved_list'),
                subtitle: l10n.text('profiles.saved_subtitle'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: () async {
                        await ref
                            .read(workspaceViewModelProvider)
                            .createEmptyProfile();
                      },
                      icon: const Icon(Icons.add),
                      label: Text(l10n.text('profiles.new')),
                    ),
                    const SizedBox(height: 16),
                    if (viewModel.profiles.isEmpty)
                      Text(l10n.text('profiles.empty')),
                    ...viewModel.profiles.map(
                      (OpenClawProfile profile) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: profile.id == viewModel.selectedProfileId
                              ? panelSecondary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          title: Text(profile.name),
                          subtitle: Text(
                            '${OpenClawCommandPreset.byId(profile.commandPresetId).label} · '
                            '${profile.cliPath.isEmpty ? l10n.text('profiles.cli_unset') : profile.cliPath}\n'
                            '${l10n.text('profiles.source_label')}: ${_sourceText(profile.sourceType, l10n)}',
                          ),
                          leading: Icon(
                            profile.isDefault ? Icons.star : Icons.star_border,
                          ),
                          onTap: () async {
                            await ref
                                .read(workspaceViewModelProvider)
                                .selectProfile(profile.id);
                          },
                          trailing: Wrap(
                            spacing: 4,
                            children: <Widget>[
                              IconButton(
                                tooltip: l10n.text('profiles.make_default'),
                                onPressed: () async {
                                  await ref
                                      .read(workspaceViewModelProvider)
                                      .setDefaultProfile(profile.id);
                                },
                                icon: const Icon(Icons.check_circle_outline),
                              ),
                              IconButton(
                                tooltip: l10n.text('profiles.delete'),
                                onPressed: () async {
                                  await ref
                                      .read(workspaceViewModelProvider)
                                      .deleteProfile(profile.id);
                                  _clearForm();
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );

              final Widget editorSection = Column(
                children: <Widget>[
                  ProfileEditorView(
                    formKey: _formKey,
                    nameController: _nameController,
                    cliPathController: _cliPathController,
                    workingDirectoryController: _workingDirectoryController,
                    configPathController: _configPathController,
                    customArgsController: _customArgsController,
                    selectedPresetId: _selectedPresetId,
                    onPresetChanged: (String? value) {
                      setState(() {
                        _selectedPresetId =
                            value ?? OpenClawCommandPreset.gatewayStatusId;
                      });
                    },
                    isDefault: _isDefault,
                    onDefaultChanged: (bool value) {
                      setState(() {
                        _isDefault = value;
                      });
                    },
                    onValidate: () async {
                      await _validateCurrentDraft(showSuccessMessage: true);
                    },
                    onSave: () async {
                      final ProfileValidationResult? result =
                          await _validateCurrentDraft(
                              showSuccessMessage: false);
                      if (result == null || !result.isValid) {
                        return;
                      }
                      final OpenClawProfile profile = _buildDraftProfile();
                      await ref
                          .read(workspaceViewModelProvider)
                          .saveProfile(profile);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.text('profiles.saved')),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  if (viewModel.lastValidationResult != null)
                    _ValidationResultPanel(
                      result: viewModel.lastValidationResult!,
                    ),
                ],
              );

              if (isCompact) {
                return Column(
                  children: <Widget>[
                    listSection,
                    const SizedBox(height: 18),
                    editorSection,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 3, child: listSection),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: editorSection),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  OpenClawProfile _buildDraftProfile() {
    final String cliPath = _cliPathController.text.trim();
    final String configPath = _configPathController.text.trim();

    return OpenClawProfile(
      id: _editingId ?? IdGenerator.next('profile'),
      name: _nameController.text.trim(),
      cliPath: cliPath,
      workingDirectory: _workingDirectoryController.text.trim(),
      configPath: configPath,
      commandPresetId: _selectedPresetId,
      customArgs: _customArgsController.text.trim(),
      envVars: <String, String>{
        if (configPath.isNotEmpty) 'OPENCLAW_CONFIG_PATH': configPath,
      },
      isDefault: _isDefault,
    );
  }

  Future<ProfileValidationResult?> _validateCurrentDraft(
      {required bool showSuccessMessage}) async {
    if (!_formKey.currentState!.validate()) {
      return null;
    }

    final String workdir = _workingDirectoryController.text.trim();
    if (workdir.isNotEmpty && !Directory(workdir).existsSync()) {
      _showMessage(
          AppLocalizations.of(context).text('profiles.workdir_missing'));
      return null;
    }

    final String configPath = _configPathController.text.trim();
    if (configPath.isNotEmpty && !File(configPath).existsSync()) {
      _showMessage(
        AppLocalizations.of(context).text('profiles.config_path_missing'),
      );
      return null;
    }

    final ProfileValidationResult result = await ref
        .read(workspaceViewModelProvider)
        .validateProfile(_buildDraftProfile());
    if (showSuccessMessage && mounted) {
      _showMessage(result.isValid
          ? AppLocalizations.of(context).text('profiles.validation_passed')
          : result.configValidationMessage ?? result.message);
    }
    return result;
  }

  void _hydrateForm(OpenClawProfile profile) {
    _editingId = profile.id;
    _nameController.text = profile.name;
    _cliPathController.text = profile.cliPath;
    _workingDirectoryController.text = profile.workingDirectory;
    _configPathController.text = profile.configPath;
    _customArgsController.text = profile.customArgs;
    _selectedPresetId = profile.commandPresetId;
    _isDefault = profile.isDefault;
  }

  void _clearForm() {
    setState(() {
      _editingId = null;
      _isDefault = false;
      _selectedPresetId = OpenClawCommandPreset.gatewayStatusId;
      _nameController.clear();
      _cliPathController.clear();
      _workingDirectoryController.clear();
      _configPathController.clear();
      _customArgsController.clear();
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _sourceText(String sourceType, AppLocalizations l10n) {
    switch (sourceType) {
      case OpenClawProfile.externalSourceType:
        return l10n.text('profiles.source_external');
      default:
        return sourceType;
    }
  }
}

class _ValidationResultPanel extends StatelessWidget {
  const _ValidationResultPanel({required this.result});

  final ProfileValidationResult result;

  @override
  Widget build(BuildContext context) {
    final Color color = result.isValid ? AppTheme.success : AppTheme.danger;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return _WorkspaceSection(
      title: l10n.text('profiles.validation_title'),
      subtitle: l10n.text('profiles.validation_subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.message,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          if (result.nodeRuntimeInfo != null) ...<Widget>[
            const SizedBox(height: 10),
            SelectableText(
              '${l10n.text('setup.node_version')}: '
              '${result.nodeRuntimeInfo!.version ?? l10n.text('setup.not_found')}\n'
              '${l10n.text('setup.node_path')}: '
              '${result.nodeRuntimeInfo!.executablePath ?? l10n.text('setup.not_found')}\n'
              '${l10n.text('setup.node_requirement')}: '
              '>= ${result.nodeRuntimeInfo!.requiredVersion}',
            ),
          ],
          if (result.cliVersion != null) ...<Widget>[
            const SizedBox(height: 10),
            Text('${l10n.text('setup.cli_version')}: ${result.cliVersion}'),
          ],
          if (result.configValidationMessage != null) ...<Widget>[
            const SizedBox(height: 10),
            SelectableText(
              '${l10n.text('profiles.validation_detail')}: '
              '${result.configValidationMessage}',
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkspaceSection extends StatelessWidget {
  const _WorkspaceSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: child,
          ),
        ],
      ),
    );
  }
}
