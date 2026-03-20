import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';

/// Gateway 连接引导视图。
///
/// 文案参考 `/agents` 当前未授权态页面，
/// 先把“如何拿到连接所需信息”清晰表达出来，
/// 降低用户在 WebSocket / Token / Password 上的理解成本。
class GatewayConnectionGuideView extends StatelessWidget {
  const GatewayConnectionGuideView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.text('console.gateway_helper_intro'),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        _CommandStepView(
          indexLabel: '01',
          title: l10n.text('console.gateway_helper_step_gateway'),
          command: 'openclaw gateway run',
        ),
        const SizedBox(height: 12),
        _CommandStepView(
          indexLabel: '02',
          title: l10n.text('console.gateway_helper_step_dashboard'),
          command: 'openclaw dashboard --no-open',
        ),
        const SizedBox(height: 12),
        _CommandStepView(
          indexLabel: '03',
          title: l10n.text('console.gateway_helper_step_paste'),
          command: 'WebSocket URL + Gateway Token',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.warning.withValues(alpha: 0.24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.text('console.gateway_helper_error_title'),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.text('console.gateway_helper_error_desc'),
                style: theme.textTheme.bodySmall?.copyWith(height: 1.55),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.text('console.gateway_helper_note'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondaryOf(context),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _CommandStepView extends StatelessWidget {
  const _CommandStepView({
    required this.indexLabel,
    required this.title,
    required this.command,
  });

  final String indexLabel;
  final String title;
  final String command;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            indexLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.panelSecondaryOf(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderOf(context)),
                ),
                child: SelectableText(
                  command,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
