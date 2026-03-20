import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';

/// 控制台输出组件。
class SessionConsoleView extends StatelessWidget {
  const SessionConsoleView({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color terminalBackground =
        dark ? const Color(0xFF05070A) : const Color(0xFF0B1220);
    final Color terminalBorder =
        dark ? const Color(0xFF334155) : const Color(0xFF1E293B);

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
                  l10n.text('console.title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.text('console.description'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 360),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: terminalBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: terminalBorder),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.24 : 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: lines.isEmpty
                  ? SelectableText(
                      l10n.text('console.no_output'),
                      style: const TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    )
                  : SelectableText.rich(
                      TextSpan(
                        children: _buildLineSpans(lines),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildLineSpans(List<String> lines) {
    final List<InlineSpan> spans = <InlineSpan>[];
    for (int index = 0; index < lines.length; index += 1) {
      final String line = lines[index];
      spans.add(
        TextSpan(
          text: line,
          style: _styleForLine(line),
        ),
      );
      if (index != lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    return spans;
  }

  TextStyle _styleForLine(String line) {
    final TextStyle base = const TextStyle(
      color: Color(0xFFE5E7EB),
      fontFamily: 'monospace',
      fontSize: 13.5,
      height: 1.55,
    );

    if (line.startsWith('[stderr]')) {
      return base.copyWith(
        color: const Color(0xFFFF8A80),
        fontWeight: FontWeight.w600,
      );
    }
    if (line.startsWith('[status]') &&
        (line.contains('退出码：0') ||
            line.contains('已完成') ||
            line.contains('已在应用内启动'))) {
      return base.copyWith(
        color: const Color(0xFF86EFAC),
        fontWeight: FontWeight.w600,
      );
    }
    if (line.startsWith('[status]')) {
      return base.copyWith(
        color: const Color(0xFF67E8F9),
        fontWeight: FontWeight.w600,
      );
    }
    if (line.startsWith('> ')) {
      return base.copyWith(
        color: const Color(0xFF93C5FD),
        fontWeight: FontWeight.w500,
      );
    }
    if (line.contains('启动失败') ||
        line.contains('失败') ||
        line.contains('exit') ||
        line.contains('退出码')) {
      return base.copyWith(
        color: const Color(0xFFFBBF24),
        fontWeight: FontWeight.w600,
      );
    }
    return base;
  }
}
