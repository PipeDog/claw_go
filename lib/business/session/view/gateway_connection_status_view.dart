import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../component/openclaw_runtime/model/openclaw_gateway_connection_state.dart';
import '../../../component/openclaw_runtime/model/openclaw_gateway_status.dart';
import '../../../foundation/i18n/app_localizations.dart';

/// Gateway 连接状态概览。
///
/// 这里把最关键的状态信息做成紧凑指标块，
/// 让用户进入页面后先回答四个问题：
/// 1. Gateway 进程是否已启动；
/// 2. WebSocket 是否已连通；
/// 3. 当前实际连接地址是什么；
/// 4. 鉴权信息来自哪里。
class GatewayConnectionStatusView extends StatelessWidget {
  const GatewayConnectionStatusView({
    super.key,
    required this.gatewayStatus,
    required this.connectionState,
  });

  final OpenClawGatewayStatus gatewayStatus;
  final OpenClawGatewayConnectionState connectionState;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String resolvedUrl = connectionState.url?.trim().isNotEmpty == true
        ? connectionState.url!.trim()
        : (gatewayStatus.url?.trim().isNotEmpty == true
            ? gatewayStatus.url!.trim()
            : 'ws://127.0.0.1:18789');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _StatusMetricCard(
              label: l10n.text('console.gateway_status_process'),
              value: gatewayStatus.isRunning
                  ? l10n.text('chat.gateway_running')
                  : l10n.text('chat.gateway_stopped'),
              accentColor:
                  gatewayStatus.isRunning ? AppTheme.success : AppTheme.warning,
              icon: gatewayStatus.isRunning
                  ? Icons.rocket_launch_rounded
                  : Icons.pause_circle_outline_rounded,
            ),
            _StatusMetricCard(
              label: l10n.text('console.gateway_status_connection'),
              value: connectionState.message,
              accentColor: _connectionColor(connectionState.phase),
              icon: _connectionIcon(connectionState.phase),
            ),
            _StatusMetricCard(
              label: l10n.text('console.gateway_status_url'),
              value: resolvedUrl,
              accentColor: const Color(0xFF60A5FA),
              icon: Icons.link_rounded,
            ),
            _StatusMetricCard(
              label: l10n.text('console.gateway_status_auth'),
              value: gatewayStatus.authSummary ?? l10n.text('common.none'),
              accentColor: AppTheme.accent,
              icon: Icons.vpn_key_outlined,
            ),
          ],
        ),
        if (connectionState.grantedScopes.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Text(
            l10n.text('console.gateway_status_scopes'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryOf(context),
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: connectionState.grantedScopes
                .map(
                  (String scope) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppTheme.success.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      scope,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Color _connectionColor(OpenClawGatewayConnectionPhase phase) {
    return switch (phase) {
      OpenClawGatewayConnectionPhase.connected => AppTheme.success,
      OpenClawGatewayConnectionPhase.connecting => const Color(0xFF60A5FA),
      OpenClawGatewayConnectionPhase.error => AppTheme.danger,
      OpenClawGatewayConnectionPhase.disconnected => AppTheme.warning,
    };
  }

  IconData _connectionIcon(OpenClawGatewayConnectionPhase phase) {
    return switch (phase) {
      OpenClawGatewayConnectionPhase.connected => Icons.check_circle_outline,
      OpenClawGatewayConnectionPhase.connecting => Icons.sync_rounded,
      OpenClawGatewayConnectionPhase.error => Icons.error_outline_rounded,
      OpenClawGatewayConnectionPhase.disconnected => Icons.link_off_rounded,
    };
  }
}

class _StatusMetricCard extends StatelessWidget {
  const _StatusMetricCard({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.icon,
  });

  final String label;
  final String value;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.panelSecondaryOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryOf(context),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
