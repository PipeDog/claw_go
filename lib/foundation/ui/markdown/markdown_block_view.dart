import 'package:flutter/material.dart';

import 'markdown_block.dart';
import 'markdown_inline_text_view.dart';

/// 单个 Markdown 块渲染视图。
///
/// 负责把已经解析好的块级结构转成 Flutter Widget。
class MarkdownBlockView extends StatelessWidget {
  const MarkdownBlockView({
    super.key,
    required this.block,
    required this.style,
    required this.textColor,
    required this.selectable,
  });

  /// 当前块级节点。
  final MarkdownBlock block;

  /// 基础文本样式。
  final TextStyle? style;

  /// 文本颜色。
  final Color textColor;

  /// 是否允许选择文本。
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // 所有块都从同一个基础样式出发，再按块类型做局部增强，
    // 这样能保证整体视觉一致，不会出现每种块各自失控的情况。
    final TextStyle baseStyle =
        (style ?? theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: textColor,
      height: 1.5,
    );

    return switch (block.type) {
      MarkdownBlockType.heading => MarkdownInlineTextView(
          text: block.text,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: _resolveHeadingFontSize(
              baseStyle.fontSize,
              block.level,
            ),
          ),
          textColor: textColor,
          selectable: selectable,
        ),
      MarkdownBlockType.paragraph => MarkdownInlineTextView(
          text: block.text,
          style: baseStyle,
          textColor: textColor,
          selectable: selectable,
        ),
      MarkdownBlockType.unorderedList => Row(
          // 列表项使用“项目符号 + 内容”的两列布局，
          // 这样换行时内容能自然对齐，不会顶到左边界。
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '•',
                style: baseStyle.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MarkdownInlineTextView(
                text: block.text,
                style: baseStyle,
                textColor: textColor,
                selectable: selectable,
              ),
            ),
          ],
        ),
      MarkdownBlockType.orderedList => Row(
          // 有序列表与无序列表结构类似，只是左侧换成解析阶段记录下来的序号。
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${block.index}.',
              style: baseStyle.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MarkdownInlineTextView(
                text: block.text,
                style: baseStyle,
                textColor: textColor,
                selectable: selectable,
              ),
            ),
          ],
        ),
      MarkdownBlockType.quote => Container(
          // 引用块采用“左侧强调线 + 轻背景”的方式，
          // 目的是在不破坏卡片整体风格的前提下突出引用语义。
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: textColor.withValues(alpha: 0.4),
                width: 3,
              ),
            ),
          ),
          child: MarkdownInlineTextView(
            text: block.text,
            style: baseStyle.copyWith(
              color: textColor.withValues(alpha: 0.88),
              fontStyle: FontStyle.italic,
            ),
            textColor: textColor,
            selectable: selectable,
          ),
        ),
      MarkdownBlockType.code => Container(
          // 代码块不复用行内渲染器，
          // 而是直接输出等宽文本，避免额外 Markdown 二次解析。
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF111827)
                : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.7),
            ),
          ),
          child: selectable
              ? SelectableText(
                  _formatCodeBlockText(block.text),
                  style: baseStyle.copyWith(
                    fontFamily: 'monospace',
                    color: textColor,
                  ),
                )
              : Text(
                  _formatCodeBlockText(block.text),
                  style: baseStyle.copyWith(
                    fontFamily: 'monospace',
                    color: textColor,
                  ),
                ),
        ),
    };
  }

  /// 对代码块文本做最小格式修正。
  ///
  /// 这里主要处理两个问题：
  /// 1. 把 Tab 转成固定空格，避免不同平台下 Tab 宽度不一致；
  /// 2. 给每一行补一个统一的左缩进，让代码块在视觉上更像“代码区域”。
  String _formatCodeBlockText(String source) {
    return source
        .split('\n')
        .map((String line) => '  ${line.replaceAll('\t', '    ')}')
        .join('\n');
  }

  double? _resolveHeadingFontSize(double? baseFontSize, int level) {
    // 标题字号按层级递减，保持“越高层级越醒目”的基础阅读秩序。
    final double seed = baseFontSize ?? 14;
    return switch (level) {
      1 => seed + 8,
      2 => seed + 6,
      3 => seed + 4,
      4 => seed + 2,
      _ => seed + 1,
    };
  }
}
