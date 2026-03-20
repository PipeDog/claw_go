import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';

/// 设置表单视图。
class SettingsFormView extends StatelessWidget {
  const SettingsFormView({
    super.key,
    required this.shellController,
    required this.nodePathController,
    required this.logLevel,
    required this.onLogLevelChanged,
    required this.reopenLastSession,
    required this.onReopenChanged,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.localeCode,
    required this.onLocaleCodeChanged,
    required this.onSave,
  });

  final TextEditingController shellController;
  final TextEditingController nodePathController;
  final String logLevel;
  final ValueChanged<String?> onLogLevelChanged;
  final bool reopenLastSession;
  final ValueChanged<bool> onReopenChanged;
  final String themeMode;
  final ValueChanged<String?> onThemeModeChanged;
  final String localeCode;
  final ValueChanged<String?> onLocaleCodeChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                  l10n.text('config.basic_title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.text('config.basic_subtitle'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: shellController,
                  decoration: InputDecoration(
                    labelText: l10n.text('settings.default_shell'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nodePathController,
                  decoration: InputDecoration(
                    labelText: l10n.text('settings.node_path'),
                    hintText: l10n.text('settings.node_path_hint'),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: logLevel,
                  decoration: InputDecoration(
                    labelText: l10n.text('settings.log_level'),
                  ),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: 'debug',
                      child: Text('debug'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'info',
                      child: Text('info'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'warn',
                      child: Text('warn'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'error',
                      child: Text('error'),
                    ),
                  ],
                  onChanged: onLogLevelChanged,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: themeMode,
                  decoration: InputDecoration(
                    labelText: l10n.text('settings.theme_mode'),
                  ),
                  items: <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: 'system',
                      child: Text(l10n.text('common.system')),
                    ),
                    DropdownMenuItem<String>(
                      value: 'light',
                      child: Text(l10n.text('common.light')),
                    ),
                    DropdownMenuItem<String>(
                      value: 'dark',
                      child: Text(l10n.text('common.dark')),
                    ),
                  ],
                  onChanged: onThemeModeChanged,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: localeCode,
                  decoration: InputDecoration(
                    labelText: l10n.text('settings.language'),
                  ),
                  items: <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: 'zh',
                      child: Text(l10n.text('language.chinese')),
                    ),
                    DropdownMenuItem<String>(
                      value: 'en',
                      child: Text(l10n.text('language.english')),
                    ),
                  ],
                  onChanged: onLocaleCodeChanged,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: reopenLastSession,
                  title: Text(l10n.text('settings.reopen')),
                  onChanged: onReopenChanged,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(l10n.text('settings.save')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
