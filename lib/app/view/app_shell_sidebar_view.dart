import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../model/app_shell_item.dart';

/// 桌面壳层侧边栏。
class AppShellSidebarView extends StatelessWidget {
  const AppShellSidebarView({
    super.key,
    required this.appName,
    required this.appSubtitle,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final String appName;
  final String appSubtitle;
  final List<AppShellItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final panelColor = AppTheme.panelOf(context);
    final borderColor = AppTheme.borderOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final Map<String, List<_IndexedItem>> grouped =
        <String, List<_IndexedItem>>{};
    for (int index = 0; index < items.length; index += 1) {
      final AppShellItem item = items[index];
      grouped.putIfAbsent(item.group, () => <_IndexedItem>[]);
      grouped[item.group]!.add(_IndexedItem(index: index, item: item));
    }

    return Container(
      width: 252,
      decoration: BoxDecoration(
        color: panelColor,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.bug_report_outlined,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      appName.toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appSubtitle,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: grouped.entries
                  .map((MapEntry<String, List<_IndexedItem>> entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _SidebarSection(
                    title: entry.key,
                    items: entry.value,
                    selectedIndex: selectedIndex,
                    onSelect: onSelect,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({
    required this.title,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final String title;
  final List<_IndexedItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final textSecondary = AppTheme.textSecondaryOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final borderColor = AppTheme.borderOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
          child: Text(title, style: Theme.of(context).textTheme.labelLarge),
        ),
        ...items.map(((_IndexedItem item) {
          final bool selected = item.index == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onSelect(item.index),
              child: Ink(
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.accent.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: selected
                      ? Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.18),
                        )
                      : Border.all(color: Colors.transparent),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: <Widget>[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 3,
                      height: 22,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.accent
                            : borderColor.withValues(alpha: 0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      selected ? item.item.selectedIcon : item.item.icon,
                      size: 18,
                      color: selected ? AppTheme.accent : textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.item.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: selected ? textPrimary : textSecondary,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        })),
      ],
    );
  }
}

class _IndexedItem {
  const _IndexedItem({
    required this.index,
    required this.item,
  });

  final int index;
  final AppShellItem item;
}
