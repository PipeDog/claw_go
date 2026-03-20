import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business/assistant/page/agents_page.dart';
import '../../business/assistant/page/home_page.dart';
import '../../business/assistant/page/tasks_page.dart';
import '../../business/help/page/help_page.dart';
import '../../business/onboarding/view_model/onboarding_view_model.dart';
import '../../business/settings/page/settings_page.dart';
import '../../business/workspace/view_model/workspace_view_model.dart';
import '../../foundation/i18n/app_localizations.dart';
import '../../foundation/ui/app_tab_bar_view.dart';
import '../config/app_config.dart';
import '../model/app_shell_item.dart';
import '../view/app_shell_frame_view.dart';
import '../view/app_shell_header_view.dart';
import '../view/app_shell_sidebar_view.dart';
import '../view/shell_gateway_controls_view.dart';
import 'connect_page.dart';
import 'environments_page.dart';

/// 主界面骨架。
class RootPage extends ConsumerStatefulWidget {
  const RootPage({super.key});

  @override
  ConsumerState<RootPage> createState() => _RootPageState();
}

class _RootPageState extends ConsumerState<RootPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(onboardingViewModelProvider);
    final workspace = ref.watch(workspaceViewModelProvider);
    final l10n = AppLocalizations.of(context);
    final List<AppShellItem> items = <AppShellItem>[
      AppShellItem(
        id: 'chat',
        group: l10n.text('shell.group.chat'),
        label: l10n.text('shell.chat'),
        icon: Icons.chat_bubble_outline_rounded,
        selectedIcon: Icons.chat_bubble_rounded,
        page: HomePage(
          onOpenTasks: () => _selectId('sessions'),
          onOpenSettings: () => _selectId('config'),
        ),
      ),
      AppShellItem(
        id: 'sessions',
        group: l10n.text('shell.group.control'),
        label: l10n.text('shell.sessions'),
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        page: TasksPage(onOpenHome: () => _selectId('chat')),
      ),
      AppShellItem(
        id: 'connect',
        group: l10n.text('shell.group.control'),
        label: l10n.text('shell.connect'),
        icon: Icons.link_outlined,
        selectedIcon: Icons.link_rounded,
        page: const ConnectPage(),
      ),
      AppShellItem(
        id: 'agents',
        group: l10n.text('shell.group.agent'),
        label: l10n.text('shell.agents'),
        icon: Icons.hub_outlined,
        selectedIcon: Icons.hub_rounded,
        page: AgentsPage(
          onOpenChat: () => _selectId('chat'),
          onOpenSessions: () => _selectId('sessions'),
          onOpenProfiles: () => _selectId('environments'),
          onOpenConnect: () => _selectId('connect'),
        ),
      ),
      AppShellItem(
        id: 'environments',
        group: l10n.text('shell.group.agent'),
        label: l10n.text('shell.environments'),
        icon: Icons.folder_open_outlined,
        selectedIcon: Icons.folder_rounded,
        page: const EnvironmentsPage(),
      ),
      AppShellItem(
        id: 'config',
        group: l10n.text('shell.group.settings'),
        label: l10n.text('shell.config'),
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        page: const SettingsPage(),
      ),
      AppShellItem(
        id: 'docs',
        group: l10n.text('shell.group.resources'),
        label: l10n.text('shell.docs'),
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book_rounded,
        page: HelpPage(
          onOpenHome: () => _selectId('chat'),
          onOpenSettings: () => _selectId('config'),
        ),
      ),
    ];

    final AppShellItem selectedItem = items[_selectedIndex];
    final _ShellPresentation presentation = _buildPresentation(
      context: context,
      item: selectedItem,
    );

    Widget content = Row(
      children: <Widget>[
        AppShellSidebarView(
          appName: AppConfig.appName,
          appSubtitle: l10n.text('app.subtitle'),
          items: items,
          selectedIndex: _selectedIndex,
          onSelect: _selectIndex,
        ),
        Expanded(
          child: Column(
            children: <Widget>[
              AppShellHeaderView(
                leftSlot: presentation.headerLeft,
                versionText: workspace.profiles.isEmpty ? 'n/a' : 'local',
                healthText: workspace.profiles.isEmpty
                    ? l10n.text('shell.setup_required')
                    : l10n.text('shell.ready'),
                ready: workspace.profiles.isNotEmpty,
              ),
              Expanded(child: presentation.pageBody),
            ],
          ),
        ),
      ],
    );

    if (presentation.tabCount != null) {
      content = DefaultTabController(
        length: presentation.tabCount!,
        child: content,
      );
    }

    return Scaffold(
      body: AppShellFrameView(child: content),
    );
  }

  _ShellPresentation _buildPresentation({
    required BuildContext context,
    required AppShellItem item,
  }) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return switch (item.id) {
      'chat' => _ShellPresentation(
          headerLeft: const ShellGatewayControlsView(),
          pageBody: item.page,
        ),
      'connect' => _ShellPresentation(
          tabCount: 3,
          headerLeft: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: AppTabBarView(
              isScrollable: true,
              tabs: <Widget>[
                Tab(text: l10n.text('connect.tab_connection')),
                Tab(text: l10n.text('connect.tab_commands')),
                Tab(text: l10n.text('connect.tab_diagnostics')),
              ],
              drawBottomBorder: false,
              horizontalPadding: 0,
            ),
          ),
          pageBody: item.page,
        ),
      'agents' => _ShellPresentation(
          tabCount: 3,
          headerLeft: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: AppTabBarView(
              isScrollable: true,
              tabs: <Widget>[
                Tab(text: l10n.text('agents.tab_directory')),
                Tab(text: l10n.text('agents.tab_workspace')),
                Tab(text: l10n.text('agents.tab_diagnostics')),
              ],
              drawBottomBorder: false,
              horizontalPadding: 0,
            ),
          ),
          pageBody: item.page,
        ),
      'environments' => _ShellPresentation(
          tabCount: 2,
          headerLeft: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: AppTabBarView(
              isScrollable: true,
              tabs: <Widget>[
                Tab(text: l10n.text('environments.tab_discover')),
                Tab(text: l10n.text('environments.tab_manage')),
              ],
              drawBottomBorder: false,
              horizontalPadding: 0,
            ),
          ),
          pageBody: item.page,
        ),
      _ => _ShellPresentation(
          headerLeft: _ShellPageLabel(label: item.label),
          pageBody: item.page,
        ),
    };
  }

  void _selectIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _selectId(String id) {
    const List<String> orderedIds = <String>[
      'chat',
      'sessions',
      'connect',
      'agents',
      'environments',
      'config',
      'docs',
    ];
    final int index = orderedIds.indexOf(id);
    if (index == -1) {
      return;
    }
    _selectIndex(index);
  }
}

class _ShellPresentation {
  const _ShellPresentation({
    required this.headerLeft,
    required this.pageBody,
    this.tabCount,
  });

  final Widget? headerLeft;
  final Widget pageBody;
  final int? tabCount;
}

class _ShellPageLabel extends StatelessWidget {
  const _ShellPageLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
