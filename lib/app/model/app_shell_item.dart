import 'package:flutter/material.dart';

/// 桌面壳层导航项。
class AppShellItem {
  const AppShellItem({
    required this.id,
    required this.group,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });

  final String id;
  final String group;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}
