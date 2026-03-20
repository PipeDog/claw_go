import 'dart:async';

import 'package:flutter/material.dart';

/// 顶部通知样式。
enum TopNotificationStyle {
  success,
  error,
  info,
  warning,
}

/// 顶部下落通知。
class TopNotificationOverlay {
  const TopNotificationOverlay._();

  static void show(
    BuildContext context, {
    required String message,
    TopNotificationStyle style = TopNotificationStyle.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final OverlayState overlay = Overlay.of(context, rootOverlay: true);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext context) {
        return _TopNotificationEntry(
          message: message,
          style: style,
          duration: duration,
          onDismissed: () {
            entry.remove();
          },
        );
      },
    );
    overlay.insert(entry);
  }
}

class _TopNotificationEntry extends StatefulWidget {
  const _TopNotificationEntry({
    required this.message,
    required this.style,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final TopNotificationStyle style;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_TopNotificationEntry> createState() => _TopNotificationEntryState();
}

class _TopNotificationEntryState extends State<_TopNotificationEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 180),
  );
  late final Animation<Offset> _offsetAnimation = Tween<Offset>(
    begin: const Offset(0, -0.18),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
  );
  late final Animation<double> _opacityAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );
  Timer? _dismissTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_controller.forward());
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissed) {
      return;
    }
    _dismissed = true;
    _dismissTimer?.cancel();
    await _controller.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _NotificationVisuals visuals = _visualsFor(widget.style);
    final ThemeData theme = Theme.of(context);
    final EdgeInsets padding = MediaQuery.paddingOf(context);

    return IgnorePointer(
      ignoring: false,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, padding.top + 8, 16, 0),
            child: SlideTransition(
              position: _offsetAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _dismiss,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: visuals.backgroundColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: visuals.borderColor,
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 22,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Icon(
                                visuals.icon,
                                color: visuals.foregroundColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.message,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: visuals.foregroundColor,
                                    fontWeight: FontWeight.w600,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: visuals.foregroundColor.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _NotificationVisuals _visualsFor(TopNotificationStyle style) {
    return switch (style) {
      TopNotificationStyle.success => const _NotificationVisuals(
          backgroundColor: Color(0xFF166534),
          borderColor: Color(0xFF22C55E),
          foregroundColor: Colors.white,
          icon: Icons.check_circle_rounded,
        ),
      TopNotificationStyle.error => const _NotificationVisuals(
          backgroundColor: Color(0xFF991B1B),
          borderColor: Color(0xFFF87171),
          foregroundColor: Colors.white,
          icon: Icons.error_rounded,
        ),
      TopNotificationStyle.warning => const _NotificationVisuals(
          backgroundColor: Color(0xFF92400E),
          borderColor: Color(0xFFF59E0B),
          foregroundColor: Colors.white,
          icon: Icons.warning_rounded,
        ),
      TopNotificationStyle.info => const _NotificationVisuals(
          backgroundColor: Color(0xFF1D4ED8),
          borderColor: Color(0xFF60A5FA),
          foregroundColor: Colors.white,
          icon: Icons.info_rounded,
        ),
    };
  }
}

class _NotificationVisuals {
  const _NotificationVisuals({
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final IconData icon;
}
