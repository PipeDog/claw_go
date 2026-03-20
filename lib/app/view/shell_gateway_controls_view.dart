import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business/session/model/session_action_feedback.dart';
import '../../business/session/model/session_gateway_action.dart';
import '../../business/session/view_model/session_view_model.dart';
import '../../business/workspace/view_model/workspace_view_model.dart';
import '../../foundation/i18n/app_localizations.dart';
import '../../foundation/ui/top_notification_overlay.dart';

/// Chat 页在壳层 header 左侧使用的 gateway controls。
class ShellGatewayControlsView extends ConsumerWidget {
  const ShellGatewayControlsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final sessionViewModel = ref.watch(sessionViewModelProvider);
    final workspaceViewModel = ref.watch(workspaceViewModelProvider);
    final bool gatewayRunning = sessionViewModel.gatewayStatus.isRunning;
    final bool gatewayBusy = sessionViewModel
            .isGatewayActionRunning(SessionGatewayAction.startGateway) ||
        sessionViewModel.isGatewayActionRunning(
          SessionGatewayAction.stopGateway,
        );
    final bool gatewayConnected =
        sessionViewModel.gatewayConnectionState.isConnected;
    final bool connectionBusy = sessionViewModel.isGatewayActionRunning(
          SessionGatewayAction.connectGateway,
        ) ||
        sessionViewModel.isGatewayActionRunning(
          SessionGatewayAction.disconnectGateway,
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FilledButton.icon(
            onPressed: gatewayBusy
                ? null
                : () {
                    unawaited(
                      _toggleGateway(
                        context: context,
                        ref: ref,
                        gatewayRunning: gatewayRunning,
                      ),
                    );
                  },
            icon: _buildActionIcon(
              icon: gatewayRunning
                  ? Icons.stop_circle_outlined
                  : Icons.rocket_launch_outlined,
              busy: gatewayBusy,
            ),
            label: Text(
              gatewayRunning
                  ? l10n.text('console.gateway_stop')
                  : l10n.text('console.gateway_start'),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: sessionViewModel.isGatewayActionRunning(
                      SessionGatewayAction.restartGateway,
                    ) ||
                    workspaceViewModel.selectedProfile == null
                ? null
                : () {
                    unawaited(
                      _restartGateway(
                        context: context,
                        ref: ref,
                      ),
                    );
                  },
            icon: _buildActionIcon(
              icon: Icons.restart_alt_rounded,
              busy: sessionViewModel.isGatewayActionRunning(
                SessionGatewayAction.restartGateway,
              ),
            ),
            label: Text(l10n.text('chat.gateway_restart')),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: connectionBusy
                ? null
                : () {
                    unawaited(
                      _toggleConnection(
                        context: context,
                        ref: ref,
                        connected: gatewayConnected,
                      ),
                    );
                  },
            icon: _buildActionIcon(
              icon: gatewayConnected
                  ? Icons.link_off_rounded
                  : Icons.link_rounded,
              busy: connectionBusy,
            ),
            label: Text(
              gatewayConnected
                  ? l10n.text('chat.gateway_disconnect')
                  : l10n.text('chat.gateway_connect'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required bool busy,
  }) {
    if (!busy) {
      return Icon(icon);
    }
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  Future<void> _toggleGateway({
    required BuildContext context,
    required WidgetRef ref,
    required bool gatewayRunning,
  }) async {
    if (gatewayRunning) {
      final SessionActionFeedback feedback =
          await ref.read(sessionViewModelProvider).stopGateway();
      if (!context.mounted) {
        return;
      }
      _showFeedback(context, feedback);
      return;
    }

    final selectedProfile =
        ref.read(workspaceViewModelProvider).selectedProfile;
    if (selectedProfile == null) {
      _showFeedback(
        context,
        SessionActionFeedback.failure(
          AppLocalizations.of(context).text('chat.gateway_profile_required'),
        ),
      );
      return;
    }

    final SessionActionFeedback feedback = await ref
        .read(sessionViewModelProvider)
        .ensureGatewayRunning(selectedProfile);
    if (!context.mounted) {
      return;
    }
    _showFeedback(context, feedback);
  }

  Future<void> _restartGateway({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final selectedProfile =
        ref.read(workspaceViewModelProvider).selectedProfile;
    if (selectedProfile == null) {
      _showFeedback(
        context,
        SessionActionFeedback.failure(
          AppLocalizations.of(context).text('chat.gateway_profile_required'),
        ),
      );
      return;
    }

    final SessionActionFeedback feedback = await ref
        .read(sessionViewModelProvider)
        .restartGateway(selectedProfile);
    if (!context.mounted) {
      return;
    }
    _showFeedback(context, feedback);
  }

  Future<void> _toggleConnection({
    required BuildContext context,
    required WidgetRef ref,
    required bool connected,
  }) async {
    if (connected) {
      final SessionActionFeedback feedback =
          await ref.read(sessionViewModelProvider).disconnectGateway();
      if (!context.mounted) {
        return;
      }
      _showFeedback(context, feedback);
      return;
    }

    final selectedProfile =
        ref.read(workspaceViewModelProvider).selectedProfile;
    if (selectedProfile == null) {
      _showFeedback(
        context,
        SessionActionFeedback.failure(
          AppLocalizations.of(context).text('chat.gateway_profile_required'),
        ),
      );
      return;
    }

    final SessionActionFeedback feedback = await ref
        .read(sessionViewModelProvider)
        .connectGateway(selectedProfile);
    if (!context.mounted) {
      return;
    }
    _showFeedback(context, feedback);
  }

  void _showFeedback(
    BuildContext context,
    SessionActionFeedback feedback,
  ) {
    TopNotificationOverlay.show(
      context,
      message: feedback.message,
      style: feedback.success
          ? TopNotificationStyle.success
          : TopNotificationStyle.error,
    );
  }
}
