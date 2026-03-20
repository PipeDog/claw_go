import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../../onboarding/view_model/onboarding_view_model.dart';
import '../../workspace/view_model/workspace_view_model.dart';
import '../model/app_settings.dart';
import '../view/settings_form_view.dart';
import '../view_model/settings_view_model.dart';

/// 设置页。
///
/// 按新的导航收口方案，设置页只回答两类问题：
/// 1. 用户偏好是什么；
/// 2. 当前运行时摘要是什么。
///
/// Setup / Profiles / Console 等技术工作区不再嵌进设置页，
/// 避免“一级导航已有入口，设置里又再嵌一层”的重复体验。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final TextEditingController _shellController = TextEditingController();
  final TextEditingController _nodePathController = TextEditingController();

  String _logLevel = 'info';
  bool _reopenLastSession = true;
  String _themeMode = 'system';
  String _localeCode = 'zh';
  String? _hydratedSignature;

  @override
  void dispose() {
    _shellController.dispose();
    _nodePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SettingsViewModel viewModel = ref.watch(settingsViewModelProvider);
    final onboardingViewModel = ref.watch(onboardingViewModelProvider);
    final workspaceViewModel = ref.watch(workspaceViewModelProvider);
    final AppSettings settings = viewModel.settings;
    final detectionResult = onboardingViewModel.detectionResult;
    final selectedProfile = workspaceViewModel.selectedProfile;
    final ThemeData theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final String signature = <String>[
      settings.defaultShell,
      settings.logLevel,
      settings.reopenLastSession.toString(),
      settings.themeMode,
      settings.localeCode,
      settings.nodeExecutablePath ?? '',
    ].join('|');

    if (_hydratedSignature != signature) {
      _shellController.text = settings.defaultShell;
      _nodePathController.text = settings.nodeExecutablePath ?? '';
      _logLevel = settings.logLevel;
      _reopenLastSession = settings.reopenLastSession;
      _themeMode = settings.themeMode;
      _localeCode = settings.localeCode;
      _hydratedSignature = signature;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        children: <Widget>[
          if (viewModel.errorMessage != null) ...<Widget>[
            Container(
              width: double.infinity,
              color: AppTheme.sectionMutedOf(context),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Text(
                viewModel.errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
          Divider(height: 1, color: AppTheme.borderOf(context)),
          Expanded(
            child: ColoredBox(
              color: AppTheme.sectionCanvasOf(context),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: <Widget>[
                    SettingsFormView(
                      shellController: _shellController,
                      nodePathController: _nodePathController,
                      logLevel: _logLevel,
                      onLogLevelChanged: (String? value) {
                        setState(() {
                          _logLevel = value ?? 'info';
                        });
                      },
                      reopenLastSession: _reopenLastSession,
                      onReopenChanged: (bool value) {
                        setState(() {
                          _reopenLastSession = value;
                        });
                      },
                      themeMode: _themeMode,
                      onThemeModeChanged: (String? value) {
                        setState(() {
                          _themeMode = value ?? 'system';
                        });
                      },
                      localeCode: _localeCode,
                      onLocaleCodeChanged: (String? value) {
                        setState(() {
                          _localeCode = value ?? 'zh';
                        });
                      },
                      onSave: () async {
                        final AppSettings nextSettings = AppSettings(
                          defaultShell: _shellController.text.trim(),
                          logLevel: _logLevel,
                          reopenLastSession: _reopenLastSession,
                          themeMode: _themeMode,
                          localeCode: _localeCode,
                          nodeExecutablePath:
                              _nodePathController.text.trim().isEmpty
                                  ? null
                                  : _nodePathController.text.trim(),
                          apiKey: settings.apiKey,
                        );
                        await ref
                            .read(settingsViewModelProvider)
                            .saveSettings(nextSettings);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.text('settings.saved')),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    _SettingsSection(
                      title: l10n.text('settings.runtime_title'),
                      subtitle: l10n.text('settings.runtime_subtitle'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _RuntimeInfoRow(
                            label: l10n.text('settings.current_environment'),
                            value: selectedProfile?.name ??
                                l10n.text('setup.not_found'),
                          ),
                          _RuntimeInfoRow(
                            label: l10n.text('settings.current_cli'),
                            value: detectionResult?.primaryCliPath ??
                                selectedProfile?.cliPath ??
                                l10n.text('setup.not_found'),
                          ),
                          _RuntimeInfoRow(
                            label: l10n.text('settings.current_config'),
                            value: detectionResult?.primaryConfigPath ??
                                selectedProfile?.configPath ??
                                l10n.text('setup.not_found'),
                          ),
                          _RuntimeInfoRow(
                            label: l10n.text('settings.current_node'),
                            value: detectionResult
                                    ?.nodeRuntimeInfo?.executablePath ??
                                settings.nodeExecutablePath ??
                                l10n.text('setup.not_found'),
                          ),
                          _RuntimeInfoRow(
                            label: l10n.text('settings.current_gateway'),
                            value: detectionResult?.gatewayStatus?.message ??
                                l10n.text('setup.not_checked'),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.text('settings.runtime_note'),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
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

class _RuntimeInfoRow extends StatelessWidget {
  const _RuntimeInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          SelectableText(value),
        ],
      ),
    );
  }
}
