import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_theme.dart';
import '../../../component/openclaw_runtime/model/openclaw_command_preset.dart';
import '../../../component/openclaw_runtime/model/openclaw_gateway_connection_request.dart';
import '../../../component/openclaw_runtime/model/openclaw_profile.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../../../foundation/ui/top_notification_overlay.dart';
import '../../workspace/view_model/workspace_view_model.dart';
import '../model/gateway_connection_preferences.dart';
import '../view/gateway_connection_form_view.dart';
import '../view/gateway_connection_guide_view.dart';
import '../view/gateway_connection_status_view.dart';
import '../view/session_console_view.dart';
import '../view_model/session_view_model.dart';

/// 会话控制台页面。
class SessionPage extends ConsumerStatefulWidget {
  const SessionPage({
    super.key,
    this.showPageHeader = true,
    this.padding = const EdgeInsets.all(24),
    this.showGatewaySection = true,
    this.showCommandSection = true,
  });

  final bool showPageHeader;
  final EdgeInsetsGeometry padding;
  final bool showGatewaySection;
  final bool showCommandSection;

  @override
  ConsumerState<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends ConsumerState<SessionPage> {
  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _customArgsController = TextEditingController();
  final TextEditingController _gatewayWebSocketController =
      TextEditingController();
  final TextEditingController _gatewayTokenController = TextEditingController();
  final TextEditingController _gatewayPasswordController =
      TextEditingController();
  String? _selectedProfileId;
  String? _selectedPresetId;
  String? _gatewayStatusProfileId;
  bool _showGatewayToken = false;
  bool _showGatewayPassword = false;
  bool _gatewayPreferencesHydrated = false;

  @override
  void initState() {
    super.initState();
    unawaited(_hydrateGatewayConnectionPreferences());
  }

  @override
  void dispose() {
    _commandController.dispose();
    _customArgsController.dispose();
    _gatewayWebSocketController.dispose();
    _gatewayTokenController.dispose();
    _gatewayPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspaceViewModel = ref.watch(workspaceViewModelProvider);
    final sessionViewModel = ref.watch(sessionViewModelProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final List<OpenClawProfile> profiles = workspaceViewModel.profiles;

    _selectedProfileId ??=
        workspaceViewModel.selectedProfileId ?? _firstOrNull(profiles)?.id;
    final OpenClawProfile? selectedProfile =
        _findProfile(profiles, _selectedProfileId);
    _selectedPresetId ??= selectedProfile?.commandPresetId ??
        OpenClawCommandPreset.gatewayStatusId;
    if (selectedProfile != null &&
        _gatewayStatusProfileId != selectedProfile.id) {
      _gatewayStatusProfileId = selectedProfile.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(
          ref
              .read(sessionViewModelProvider)
              .refreshGatewayStatus(selectedProfile),
        );
      });
    }

    return SingleChildScrollView(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.showPageHeader) ...<Widget>[
            Text(
              l10n.text('console.title'),
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.text('console.description'),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
          ],
          if (widget.showGatewaySection)
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool isWide = constraints.maxWidth >= 1180;
                final Widget gatewayWorkspace = _SessionSection(
                  title: l10n.text('console.gateway_title'),
                  subtitle: l10n.text('console.gateway_subtitle'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      GatewayConnectionStatusView(
                        gatewayStatus: sessionViewModel.gatewayStatus,
                        connectionState:
                            sessionViewModel.gatewayConnectionState,
                      ),
                      const SizedBox(height: 18),
                      Divider(height: 1, color: theme.dividerColor),
                      const SizedBox(height: 18),
                      GatewayConnectionFormView(
                        profiles: profiles,
                        selectedProfileId: _selectedProfileId,
                        onProfileChanged: _handleProfileChanged,
                        webSocketUrlController: _gatewayWebSocketController,
                        gatewayTokenController: _gatewayTokenController,
                        passwordController: _gatewayPasswordController,
                        showGatewayToken: _showGatewayToken,
                        showPassword: _showGatewayPassword,
                        onToggleGatewayTokenVisibility: () {
                          setState(() {
                            _showGatewayToken = !_showGatewayToken;
                          });
                        },
                        onTogglePasswordVisibility: () {
                          setState(() {
                            _showGatewayPassword = !_showGatewayPassword;
                          });
                        },
                        onConnectPressed:
                            selectedProfile == null || sessionViewModel.loading
                                ? null
                                : () {
                                    unawaited(_connectGateway(selectedProfile));
                                  },
                        onDisconnectPressed:
                            sessionViewModel.gatewayConnectionState.isConnected
                                ? () {
                                    unawaited(
                                      ref
                                          .read(sessionViewModelProvider)
                                          .disconnectGateway(),
                                    );
                                  }
                                : null,
                        onRefreshStatusPressed: selectedProfile == null
                            ? null
                            : () {
                                unawaited(
                                  ref
                                      .read(sessionViewModelProvider)
                                      .refreshGatewayStatus(selectedProfile),
                                );
                              },
                        onStartGatewayPressed: selectedProfile == null ||
                                sessionViewModel.loading
                            ? null
                            : () {
                                unawaited(
                                  ref
                                      .read(sessionViewModelProvider)
                                      .ensureGatewayRunning(selectedProfile),
                                );
                              },
                        onRestartGatewayPressed:
                            selectedProfile == null || sessionViewModel.loading
                                ? null
                                : () {
                                    unawaited(
                                      ref
                                          .read(sessionViewModelProvider)
                                          .restartGateway(selectedProfile),
                                    );
                                  },
                        onStopGatewayPressed:
                            sessionViewModel.gatewayStatus.startedByApp
                                ? () {
                                    unawaited(
                                      ref
                                          .read(sessionViewModelProvider)
                                          .stopGateway(),
                                    );
                                  }
                                : null,
                        onClearOverridesPressed: _gatewayPreferencesHydrated
                            ? () {
                                unawaited(_clearGatewayOverrides());
                              }
                            : null,
                        gatewayConnected:
                            sessionViewModel.gatewayConnectionState.isConnected,
                        loading: sessionViewModel.loading,
                      ),
                    ],
                  ),
                );
                final Widget guidePanel = _SessionSection(
                  title: l10n.text('console.gateway_helper_title'),
                  subtitle: l10n.text('console.gateway_helper_subtitle'),
                  child: const GatewayConnectionGuideView(),
                );

                if (!isWide) {
                  return Column(
                    children: <Widget>[
                      gatewayWorkspace,
                      const SizedBox(height: 20),
                      guidePanel,
                    ],
                  );
                }

                // 大屏下采用左右结构，让连接表单和说明信息同时可见，
                // 避免用户需要频繁上下滚动来回对照命令、URL、Token。
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 7, child: gatewayWorkspace),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: guidePanel),
                  ],
                );
              },
            ),
          if (widget.showGatewaySection && widget.showCommandSection)
            const SizedBox(height: 20),
          if (widget.showCommandSection)
            _SessionSection(
              title: l10n.text('console.run_title'),
              subtitle: l10n.text('console.run_subtitle'),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey<String?>(
                            'session-profile-$_selectedProfileId',
                          ),
                          initialValue: _selectedProfileId,
                          decoration: InputDecoration(
                            labelText: l10n.text('console.select_environment'),
                          ),
                          items: profiles
                              .map(
                                (OpenClawProfile profile) =>
                                    DropdownMenuItem<String>(
                                  value: profile.id,
                                  child: Text(profile.name),
                                ),
                              )
                              .toList(),
                          onChanged:
                              profiles.isEmpty ? null : _handleProfileChanged,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey<String?>(
                            'session-preset-$_selectedPresetId',
                          ),
                          initialValue: _selectedPresetId,
                          decoration: InputDecoration(
                            labelText: l10n.text('console.command_label'),
                          ),
                          items: OpenClawCommandPreset.values
                              .map(
                                (OpenClawCommandPreset preset) =>
                                    DropdownMenuItem<String>(
                                  value: preset.id,
                                  child: Text(preset.label),
                                ),
                              )
                              .toList(),
                          onChanged: profiles.isEmpty
                              ? null
                              : (String? value) {
                                  setState(() {
                                    _selectedPresetId = value;
                                  });
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _customArgsController,
                    decoration: InputDecoration(
                      labelText: l10n.text('console.extra_args'),
                      hintText: l10n.text('console.extra_args_hint'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: OpenClawCommandPreset.values
                          .map(
                            (OpenClawCommandPreset preset) => ChoiceChip(
                              label: Text(preset.label),
                              selected: preset.id == _selectedPresetId,
                              onSelected: profiles.isEmpty
                                  ? null
                                  : (_) {
                                      setState(() {
                                        _selectedPresetId = preset.id;
                                      });
                                    },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: profiles.isEmpty ||
                                sessionViewModel.loading ||
                                selectedProfile == null
                            ? null
                            : () async {
                                final OpenClawProfile runtimeProfile =
                                    selectedProfile.copyWith(
                                  commandPresetId: _selectedPresetId,
                                  customArgs: _customArgsController.text.trim(),
                                );
                                await ref
                                    .read(sessionViewModelProvider)
                                    .startSession(runtimeProfile);
                              },
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.text('console.run_action')),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: sessionViewModel.currentSession == null
                            ? null
                            : () => ref
                                .read(sessionViewModelProvider)
                                .stopSession(),
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: Text(l10n.text('common.stop')),
                      ),
                    ],
                  ),
                  if (selectedProfile != null) ...<Widget>[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${l10n.text('settings.current_cli')}: ${selectedProfile.cliPath}\n'
                        '${l10n.text('settings.current_config')}: '
                        '${selectedProfile.configPath.isEmpty ? l10n.text('console.default_config') : selectedProfile.configPath}',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (widget.showCommandSection &&
              sessionViewModel.errorMessage != null) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.danger.withValues(alpha: 0.24),
                ),
              ),
              child: Text(
                sessionViewModel.errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
          if (widget.showCommandSection) ...<Widget>[
            const SizedBox(height: 20),
            SessionConsoleView(lines: sessionViewModel.terminalLines),
            const SizedBox(height: 16),
            _SessionSection(
              title: l10n.text('console.interactive_title'),
              subtitle: l10n.text('console.interactive_subtitle'),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _commandController,
                      decoration: InputDecoration(
                        labelText: l10n.text('console.interactive_field'),
                      ),
                      onSubmitted: (String value) async {
                        await ref
                            .read(sessionViewModelProvider)
                            .sendInput(value);
                        _commandController.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: sessionViewModel.currentSession == null
                        ? null
                        : () async {
                            await ref
                                .read(sessionViewModelProvider)
                                .sendInput(_commandController.text);
                            _commandController.clear();
                          },
                    child: Text(l10n.text('chat.send')),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  OpenClawProfile? _findProfile(List<OpenClawProfile> profiles, String? id) {
    if (id == null) {
      return null;
    }
    for (final OpenClawProfile profile in profiles) {
      if (profile.id == id) {
        return profile;
      }
    }
    return null;
  }

  OpenClawProfile? _firstOrNull(List<OpenClawProfile> profiles) {
    if (profiles.isEmpty) {
      return null;
    }
    return profiles.first;
  }

  void _handleProfileChanged(String? value) {
    final workspaceViewModel = ref.read(workspaceViewModelProvider);
    final List<OpenClawProfile> profiles = workspaceViewModel.profiles;
    final OpenClawProfile? nextProfile = _findProfile(profiles, value);
    setState(() {
      _selectedProfileId = value;
      _selectedPresetId =
          nextProfile?.commandPresetId ?? OpenClawCommandPreset.gatewayStatusId;
      _customArgsController.text = nextProfile?.customArgs ?? '';
    });
  }

  Future<void> _hydrateGatewayConnectionPreferences() async {
    final GatewayConnectionPreferences preferences = await ref
        .read(sessionViewModelProvider)
        .loadGatewayConnectionPreferences();
    if (!mounted) {
      return;
    }
    setState(() {
      _gatewayPreferencesHydrated = true;
      _gatewayWebSocketController.text = preferences.webSocketUrl ?? '';
      _gatewayTokenController.text = preferences.gatewayToken ?? '';
    });
  }

  Future<void> _connectGateway(OpenClawProfile profile) async {
    final OpenClawGatewayConnectionRequest request =
        OpenClawGatewayConnectionRequest(
      url: _gatewayWebSocketController.text,
      token: _gatewayTokenController.text,
      password: _gatewayPasswordController.text,
    );
    await ref.read(sessionViewModelProvider).connectGatewayWithRequest(
          profile,
          request: request,
          rememberOverrides: true,
        );
  }

  Future<void> _clearGatewayOverrides() async {
    await ref.read(sessionViewModelProvider).clearGatewayConnectionOverrides();
    if (!mounted) {
      return;
    }
    final String message =
        AppLocalizations.of(context).text('console.gateway_overrides_cleared');
    setState(() {
      _gatewayWebSocketController.clear();
      _gatewayTokenController.clear();
      _gatewayPasswordController.clear();
    });
    TopNotificationOverlay.show(
      context,
      message: message,
      style: TopNotificationStyle.success,
    );
  }
}

class _SessionSection extends StatelessWidget {
  const _SessionSection({
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
