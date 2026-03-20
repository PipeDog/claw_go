import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// 应用级桌面工作区容器。
///
/// 以 16:9 作为最佳视觉参考，但不会强制锁死比例。
/// 在超宽窗口下会适度限制最大宽度，避免界面被横向拉散；
/// 在其他尺寸下则优先占满可用空间，保持自适应兼容。
class AppShellFrameView extends StatelessWidget {
  const AppShellFrameView({
    super.key,
    required this.child,
  });

  final Widget child;

  static const double _kPreferredMaxWidth = 1680;
  static const double _kPreferredAspectRatio = 16 / 9;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppTheme.backgroundOf(context),
            AppTheme.panelSecondaryOf(context),
          ],
        ),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final EdgeInsets framePadding = _resolveFramePadding(
              constraints.biggest,
            );
            final double preferredMaxWidth = _resolvePreferredMaxWidth(
              constraints.biggest,
            );

            final Widget surface = DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.panelOf(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.borderOf(context),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: child,
              ),
            );

            return Padding(
              padding: framePadding,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: preferredMaxWidth,
                    maxHeight: constraints.maxHeight - framePadding.vertical,
                  ),
                  child: SizedBox.expand(child: surface),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  EdgeInsets _resolveFramePadding(Size viewportSize) {
    final double horizontal = viewportSize.width >= 1440 ? 16 : 8;
    final double vertical = viewportSize.height >= 900 ? 12 : 6;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  double _resolvePreferredMaxWidth(Size viewportSize) {
    final double widthByHeight = viewportSize.height * _kPreferredAspectRatio;
    final double adaptiveWidth = widthByHeight + 120;
    if (viewportSize.width >= 1800) {
      return adaptiveWidth.clamp(1440, _kPreferredMaxWidth).toDouble();
    }

    return viewportSize.width;
  }
}
