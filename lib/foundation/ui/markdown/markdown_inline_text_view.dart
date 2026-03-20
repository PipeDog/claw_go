import 'package:flutter/material.dart';

import 'markdown_inline_parser.dart';

/// Markdown 行内文本视图。
///
/// 适用于：
/// - 单行标题
/// - 列表预览
/// - 需要 maxLines / overflow 控制的场景
class MarkdownInlineTextView extends StatelessWidget {
  const MarkdownInlineTextView({
    super.key,
    required this.text,
    required this.style,
    required this.textColor,
    required this.selectable,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  /// 待渲染的文本。
  final String text;

  /// 基础文本样式。
  final TextStyle? style;

  /// 文本颜色。
  final Color textColor;

  /// 是否允许选择文本。
  final bool selectable;

  /// 最大显示行数。
  final int? maxLines;

  /// 超出后的截断策略。
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final List<InlineSpan> spans = MarkdownInlineParser(
      text: text,
      baseStyle: style,
      textColor: textColor,
    ).parse();

    if (selectable) {
      return SelectableText.rich(
        TextSpan(children: spans, style: style),
        maxLines: maxLines,
      );
    }

    return RichText(
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(children: spans, style: style),
    );
  }
}
