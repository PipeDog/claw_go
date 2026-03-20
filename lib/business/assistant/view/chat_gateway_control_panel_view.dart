import 'package:flutter/material.dart';

import '../../../component/openclaw_runtime/model/openclaw_gateway_connection_state.dart';
import '../../../component/openclaw_runtime/model/openclaw_gateway_status.dart';
import '../../../component/openclaw_runtime/model/openclaw_profile.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../../../foundation/ui/app_panel.dart';

/// Chat 页的 Gateway 控制面板。
class ChatGatewayControlPanelView extends StatelessWidget {
  const ChatGatewayControlPanelView({
    super.key,
    required this.profile,
    required this.gatewayStatus,
    required this.connectionState,
  });

  final OpenClawProfile? profile;
  final OpenClawGatewayStatus gatewayStatus;
  final OpenClawGatewayConnectionState connectionState;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return AppPanel(
      title: l10n.text('chat.gateway_title'),
      subtitle: l10n.text('chat.gateway_subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _StatusLine(
            label: l10n.text('settings.current_environment'),
            value: profile?.name ?? l10n.text('setup.not_found'),
            maxLines: 1,
          ),
          const SizedBox(height: 8),
          _StatusLine(
            label: l10n.text('chat.gateway_process'),
            value: gatewayStatus.message,
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          _StatusLine(
            label: l10n.text('chat.gateway_connection'),
            value: connectionState.message,
            maxLines: 2,
            valueColor: connectionState.isConnected
                ? theme.colorScheme.primary
                : connectionState.phase == OpenClawGatewayConnectionPhase.error
                    ? theme.colorScheme.error
                    : null,
          ),
          if ((connectionState.url ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            _StatusLine(
              label: l10n.text('console.gateway_url'),
              value: connectionState.url!,
              maxLines: 1,
            ),
          ],
          if ((gatewayStatus.configPath ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            _StatusLine(
              label: l10n.text('chat.gateway_config_path'),
              value: gatewayStatus.configPath!,
              maxLines: 1,
            ),
          ],
          if ((gatewayStatus.authSummary ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            _StatusLine(
              label: l10n.text('chat.gateway_auth_source'),
              value: gatewayStatus.authSummary!,
              maxLines: 2,
            ),
          ],
          if (connectionState.grantedScopes.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            _StatusLine(
              label: l10n.text('chat.gateway_scopes'),
              value: connectionState.grantedScopes.join(', '),
              maxLines: 3,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.label,
    required this.value,
    this.valueColor,
    this.maxLines = 2,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String displayValue = value.trim().isEmpty ? '—' : value.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Tooltip(
          message: displayValue,
          waitDuration: const Duration(milliseconds: 400),
          child: Text(
            displayValue,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
