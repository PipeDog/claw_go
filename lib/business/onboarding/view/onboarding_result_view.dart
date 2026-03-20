import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../component/openclaw_runtime/model/config_import_result.dart';
import '../../../foundation/i18n/app_localizations.dart';

/// 自动探测结果展示组件。
class OnboardingResultView extends StatelessWidget {
  const OnboardingResultView({super.key, required this.result});

  final ConfigImportResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nodeRuntimeInfo = result.nodeRuntimeInfo;
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
                  l10n.text('setup.result_title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.text('setup.result_subtitle'),
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
                _InfoRow(
                  label: l10n.text('setup.openclaw_detected'),
                  value: result.isOpenClawDetected
                      ? l10n.text('status.completed')
                      : l10n.text('setup.not_found'),
                ),
                _InfoRow(
                  label: l10n.text('setup.gateway_status'),
                  value: result.gatewayStatus?.message ??
                      l10n.text('setup.not_checked'),
                ),
                if (nodeRuntimeInfo != null) ...<Widget>[
                  _InfoRow(
                    label: l10n.text('setup.node_path'),
                    value: nodeRuntimeInfo.executablePath ??
                        l10n.text('setup.not_found'),
                  ),
                  _InfoRow(
                    label: l10n.text('setup.node_version'),
                    value:
                        nodeRuntimeInfo.version ?? l10n.text('setup.not_found'),
                  ),
                  _InfoRow(
                    label: l10n.text('setup.node_requirement'),
                    value: '>= ${nodeRuntimeInfo.requiredVersion}',
                  ),
                  if ((nodeRuntimeInfo.pathEnvironment ?? '').isNotEmpty)
                    _InfoRow(
                      label: l10n.text('setup.path_env'),
                      value: nodeRuntimeInfo.pathEnvironment!,
                    ),
                ],
                _InfoRow(
                  label: l10n.text('setup.cli_path'),
                  value: result.detectedCliPaths.isEmpty
                      ? l10n.text('setup.not_found')
                      : result.detectedCliPaths.join('\n'),
                ),
                _InfoRow(
                  label: l10n.text('setup.cli_version'),
                  value: result.cliVersion ?? l10n.text('setup.not_found'),
                ),
                _InfoRow(
                  label: l10n.text('setup.config_file'),
                  value: result.detectedConfigPaths.isEmpty
                      ? l10n.text('setup.not_found')
                      : result.detectedConfigPaths.join('\n'),
                ),
                _InfoRow(
                  label: l10n.text('setup.config_validation'),
                  value: result.configValidationMessage ??
                      (result.isConfigValid
                          ? l10n.text('status.completed')
                          : l10n.text('setup.not_checked')),
                ),
                _InfoRow(
                  label: l10n.text('setup.env_hints'),
                  value: result.envHints.isEmpty
                      ? l10n.text('common.none')
                      : result.envHints.entries
                          .map((MapEntry<String, String> entry) =>
                              '${entry.key}=${entry.value}')
                          .join('\n'),
                ),
                if (result.warnings.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    l10n.text('setup.attention'),
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...result.warnings.map(
                    (String warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $warning'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          SelectableText(value),
        ],
      ),
    );
  }
}
