import 'package:flutter/material.dart';

import '../../app/config/app_theme.dart';

/// 通用暗色面板。
///
/// 作为页面中的基础卡片容器，统一圆角、边框和内边距，
/// 避免各模块自行拼装风格导致视觉不一致。
class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.padding = const EdgeInsets.all(20),
    this.expandChild = false,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final EdgeInsetsGeometry padding;

  /// 是否让主体区域在父级已提供明确高度时占满剩余空间。
  ///
  /// 仅适用于父容器具备确定高度的场景，例如 `Expanded`、`SizedBox`
  /// 或 `Scaffold` 主体区域内的分栏布局。
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = AppTheme.borderOf(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (title != null) ...<Widget>[
              Text(
                title!,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(subtitle!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 18),
            ],
            if (expandChild) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }
}
