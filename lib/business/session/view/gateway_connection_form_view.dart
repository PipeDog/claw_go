import 'package:flutter/material.dart';

import '../../../component/openclaw_runtime/model/openclaw_profile.dart';
import '../../../foundation/i18n/app_localizations.dart';

/// Gateway 连接表单。
///
/// 该组件只负责表单录入与按钮排布，不承担业务逻辑，
/// 便于页面层后续继续演进为独立的连接工作区。
class GatewayConnectionFormView extends StatelessWidget {
  const GatewayConnectionFormView({
    super.key,
    required this.profiles,
    required this.selectedProfileId,
    required this.onProfileChanged,
    required this.webSocketUrlController,
    required this.gatewayTokenController,
    required this.passwordController,
    required this.showGatewayToken,
    required this.showPassword,
    required this.onToggleGatewayTokenVisibility,
    required this.onTogglePasswordVisibility,
    required this.onConnectPressed,
    required this.onDisconnectPressed,
    required this.onRefreshStatusPressed,
    required this.onStartGatewayPressed,
    required this.onRestartGatewayPressed,
    required this.onStopGatewayPressed,
    required this.onClearOverridesPressed,
    required this.gatewayConnected,
    required this.loading,
  });

  final List<OpenClawProfile> profiles;
  final String? selectedProfileId;
  final ValueChanged<String?> onProfileChanged;
  final TextEditingController webSocketUrlController;
  final TextEditingController gatewayTokenController;
  final TextEditingController passwordController;
  final bool showGatewayToken;
  final bool showPassword;
  final VoidCallback onToggleGatewayTokenVisibility;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback? onConnectPressed;
  final VoidCallback? onDisconnectPressed;
  final VoidCallback? onRefreshStatusPressed;
  final VoidCallback? onStartGatewayPressed;
  final VoidCallback? onRestartGatewayPressed;
  final VoidCallback? onStopGatewayPressed;
  final VoidCallback? onClearOverridesPressed;
  final bool gatewayConnected;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey<String?>('gateway-profile-$selectedProfileId'),
                initialValue: selectedProfileId,
                decoration: InputDecoration(
                  labelText: l10n.text('console.gateway_profile'),
                ),
                items: profiles
                    .map(
                      (OpenClawProfile profile) => DropdownMenuItem<String>(
                        value: profile.id,
                        child: Text(profile.name),
                      ),
                    )
                    .toList(),
                onChanged: profiles.isEmpty ? null : onProfileChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: webSocketUrlController,
          decoration: InputDecoration(
            labelText: l10n.text('console.gateway_websocket_url'),
            hintText: l10n.text('console.gateway_websocket_url_hint'),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: gatewayTokenController,
          obscureText: !showGatewayToken,
          decoration: InputDecoration(
            labelText: l10n.text('console.gateway_token'),
            hintText: l10n.text('console.gateway_token_hint'),
            suffixIcon: IconButton(
              onPressed: onToggleGatewayTokenVisibility,
              icon: Icon(
                showGatewayToken
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: passwordController,
          obscureText: !showPassword,
          decoration: InputDecoration(
            labelText: l10n.text('console.gateway_password'),
            hintText: l10n.text('console.gateway_password_hint'),
            suffixIcon: IconButton(
              onPressed: onTogglePasswordVisibility,
              icon: Icon(
                showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.text('console.gateway_override_hint'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            FilledButton.icon(
              onPressed:
                  gatewayConnected ? onDisconnectPressed : onConnectPressed,
              icon: Icon(
                gatewayConnected ? Icons.link_off_rounded : Icons.link_rounded,
              ),
              label: Text(
                gatewayConnected
                    ? l10n.text('chat.gateway_disconnect')
                    : l10n.text('console.gateway_connect_and_save'),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onRefreshStatusPressed,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.text('common.refresh')),
            ),
            OutlinedButton.icon(
              onPressed: onStartGatewayPressed,
              icon: const Icon(Icons.rocket_launch_outlined),
              label: Text(l10n.text('console.gateway_start')),
            ),
            OutlinedButton.icon(
              onPressed: onRestartGatewayPressed,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(l10n.text('chat.gateway_restart')),
            ),
            OutlinedButton.icon(
              onPressed: onStopGatewayPressed,
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(l10n.text('console.gateway_stop')),
            ),
            OutlinedButton.icon(
              onPressed: loading ? null : onClearOverridesPressed,
              icon: const Icon(Icons.layers_clear_outlined),
              label: Text(l10n.text('console.gateway_clear_overrides')),
            ),
          ],
        ),
      ],
    );
  }
}
