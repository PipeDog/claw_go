import 'package:flutter/material.dart';

import '../../app/config/app_theme.dart';

/// 统一页内 / 壳层 Tab 切换组件。
class AppTabBarView extends StatelessWidget {
  const AppTabBarView({
    super.key,
    required this.tabs,
    this.isScrollable = false,
    this.compact = false,
    this.drawBottomBorder = true,
    this.horizontalPadding,
  });

  final List<Widget> tabs;
  final bool isScrollable;
  final bool compact;
  final bool drawBottomBorder;
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: drawBottomBorder
            ? Border(
                bottom: BorderSide(
                  color: AppTheme.borderOf(context),
                ),
              )
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding ?? (compact ? 2 : 4),
        ),
        child: TabBar(
          isScrollable: isScrollable,
          indicatorPadding: EdgeInsets.zero,
          tabs: tabs,
        ),
      ),
    );
  }
}
