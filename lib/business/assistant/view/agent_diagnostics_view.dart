import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../component/openclaw_runtime/model/openclaw_gateway_connection_state.dart';
import '../../../component/openclaw_runtime/model/openclaw_gateway_status.dart';
import '../../../foundation/i18n/app_localizations.dart';

/// Agent 诊断视图。
///
/// 这里避免直接塞入完整日志页，而是提供 Agent 语义下真正有用的诊断摘要：
/// - 当前 Gateway / 连接状态
/// - 最近几条诊断日志
/// - 跳转到 Connect 的明确入口
class AgentDiagnosticsView extends StatelessWidget {
  const AgentDiagnosticsView({
    super.key,
    required this.gatewayStatus,
    required this.connectionState,
    required this.logs,
    required this.onOpenConnect,
  });

  final OpenClawGatewayStatus gatewayStatus;
  final OpenClawGatewayConnectionState connectionState;
  final List<String> logs;
  final VoidCallback onOpenConnect;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<String> recentLogs = logs.reversed.take(6).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _StatusCard(
              label: l10n.text('console.gateway_status_process'),
              value: gatewayStatus.message,
              color:
                  gatewayStatus.isRunning ? AppTheme.success : AppTheme.warning,
            ),
            _StatusCard(
              label: l10n.text('console.gateway_status_connection'),
              value: connectionState.message,
              color: connectionState.isConnected
                  ? AppTheme.success
                  : connectionState.isConnecting
                      ? const Color(0xFF60A5FA)
                      : AppTheme.warning,
            ),
            _StatusCard(
              label: l10n.text('console.gateway_status_auth'),
              value: gatewayStatus.authSummary ?? l10n.text('common.none'),
              color: AppTheme.accent,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.sectionMutedOf(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.text('agents.diagnostics_title'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.text('agents.diagnostics_desc'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryOf(context),
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 14),
              if (recentLogs.isEmpty)
                Text(l10n.text('chat.logs_empty'))
              else
                ...recentLogs.map(
                  (String line) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SelectableText(
                      line,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            height: 1.5,
                          ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onOpenConnect,
                  icon: const Icon(Icons.link_rounded),
                  label: Text(l10n.text('agents.action_open_connect')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.sectionMutedOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryOf(context),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
