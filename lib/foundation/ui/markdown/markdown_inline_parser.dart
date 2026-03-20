import 'package:flutter/material.dart';

/// Markdown 行内解析器。
///
/// 当前支持：
/// - 粗体
/// - 斜体
/// - 删除线
/// - 行内代码
/// - 链接文本样式
///
/// 这里暂时只做视觉渲染，不处理链接点击行为。
class MarkdownInlineParser {
  MarkdownInlineParser({
    required this.text,
    required this.baseStyle,
    required this.textColor,
  });

  /// 原始文本。
  final String text;

  /// 基础文本样式。
  final TextStyle? baseStyle;

  /// 文本主颜色。
  final Color textColor;

  static final RegExp _tokenPattern = RegExp(
    r'(\[([^\]]+)\]\(([^)]+)\))|(~~(.*?)~~)|(`([^`]+)`)|(\*\*(.+?)\*\*)|(__([^_]+)__)|(\*(.+?)\*)|(_([^_]+)_)',
    dotAll: true,
  );

  /// 执行行内解析。
  List<InlineSpan> parse() {
    // 行内解析采用“正则命中 Token，再补齐普通文本”的方式。
    // 这样可以保证：
    // 1. 被 Markdown 包裹的片段走特殊样式
    // 2. 中间没有命中的普通文本仍按原样保留
    final List<InlineSpan> spans = <InlineSpan>[];
    int currentIndex = 0;

    for (final RegExpMatch match in _tokenPattern.allMatches(text)) {
      if (match.start > currentIndex) {
        // 当前命中点之前的内容，没有任何 Markdown 语义，
        // 直接按普通文本补回去，避免文本丢失。
        spans.add(_plainText(text.substring(currentIndex, match.start)));
      }

      // 当前命中的 Markdown 片段，按不同语法映射到不同 TextSpan 样式。
      spans.add(_buildStyledSpan(match));
      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      // 最后一段尾巴文本同样需要补回去。
      spans.add(_plainText(text.substring(currentIndex)));
    }

    return spans;
  }

  InlineSpan _buildStyledSpan(RegExpMatch match) {
    final String rawValue = match.group(0) ?? '';

    if (match.group(1) != null) {
      // 链接当前只做视觉样式处理，不附带点击逻辑。
      return TextSpan(
        text: match.group(2) ?? rawValue,
        style: baseStyle?.copyWith(
          color: Colors.lightBlue.shade300,
          decoration: TextDecoration.underline,
        ),
      );
    }

    if (match.group(4) != null) {
      return TextSpan(
        text: match.group(5) ?? rawValue,
        style: baseStyle?.copyWith(
          decoration: TextDecoration.lineThrough,
        ),
      );
    }

    if (match.group(6) != null) {
      // 行内代码保留 monospace 和淡背景，强化与正文的视觉区分。
      return TextSpan(
        text: match.group(7) ?? rawValue,
        style: baseStyle?.copyWith(
          fontFamily: 'monospace',
          backgroundColor: textColor.withValues(alpha: 0.12),
        ),
      );
    }

    if (match.group(8) != null || match.group(10) != null) {
      // 同时兼容 **bold** 与 __bold__ 两种粗体写法。
      return TextSpan(
        text: match.group(9) ?? match.group(11) ?? rawValue,
        style: baseStyle?.copyWith(fontWeight: FontWeight.w700),
      );
    }

    if (match.group(12) != null || match.group(14) != null) {
      // 同时兼容 *italic* 与 _italic_ 两种斜体写法。
      return TextSpan(
        text: match.group(13) ?? match.group(15) ?? rawValue,
        style: baseStyle?.copyWith(fontStyle: FontStyle.italic),
      );
    }

    return _plainText(rawValue);
  }

  InlineSpan _plainText(String value) {
    return TextSpan(text: value, style: baseStyle);
  }
}
