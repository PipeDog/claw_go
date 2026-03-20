import 'package:flutter/material.dart';

import 'markdown_block.dart';
import 'markdown_block_parser.dart';
import 'markdown_block_view.dart';
import 'markdown_inline_text_view.dart';

/// Markdown 文本视图。
///
/// 这是对外暴露的统一入口：
/// - 需要完整块级渲染时，自动走块级解析
/// - 需要 maxLines / overflow 时，自动退化为行内渲染
///
/// 这样既能满足聊天气泡的完整展示，也能满足最近会话卡片的紧凑预览。
class MarkdownTextView extends StatelessWidget {
  const MarkdownTextView({
    super.key,
    required this.data,
    required this.style,
    required this.textColor,
    this.selectable = false,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  /// 原始 Markdown 文本。
  final String data;

  /// 基础文本样式。
  final TextStyle? style;

  /// 文本颜色。
  final Color textColor;

  /// 是否允许文本选择。
  final bool selectable;

  /// 最大显示行数。
  ///
  /// 一旦传入该值，会优先使用行内模式，以便保留截断能力。
  final int? maxLines;

  /// 超出后的截断策略。
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final String normalizedText = data.trimRight();
    if (normalizedText.isEmpty) {
      return const SizedBox.shrink();
    }

    if (maxLines != null) {
      // 一旦需要 maxLines / ellipsis，就不能走完整块级渲染，
      // 因为 Column + 多块结构很难做原生文本级截断。
      // 这里有意退化成“单段行内模式”，优先满足列表卡片的紧凑预览需求。
      return MarkdownInlineTextView(
        text: normalizedText.replaceAll('\n', ' '),
        style: style,
        textColor: textColor,
        selectable: selectable,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final List<MarkdownBlock> blocks = MarkdownBlockParser(
      normalizedText,
    ).parse();
    if (blocks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      // 完整展示模式下，每个块之间加入稳定的垂直间距，
      // 既保证结构层次，也避免不同块紧贴在一起影响阅读。
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List<Widget>.generate(blocks.length, (int index) {
        final MarkdownBlock block = blocks[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index == blocks.length - 1 ? 0 : 8),
          child: MarkdownBlockView(
            block: block,
            style: style,
            textColor: textColor,
            selectable: selectable,
          ),
        );
      }),
    );
  }
}
