import 'markdown_block.dart';

/// Markdown 块级解析器。
///
/// 负责把原始字符串拆成段落、标题、列表、引用、代码块等块级结构。
/// 当前按项目使用场景提供轻量能力，不追求完整 Markdown 规范覆盖。
class MarkdownBlockParser {
  MarkdownBlockParser(this.source);

  /// 原始 Markdown 文本。
  final String source;

  /// 执行块级解析。
  List<MarkdownBlock> parse() {
    // 这里采用“逐行扫描 + 缓冲区冲刷”的方式：
    // - 普通段落先暂存到 paragraphBuffer
    // - 代码块内容先暂存到 codeBuffer
    // - 一旦遇到结构边界（空行、标题、列表、引用、代码块边界），
    //   就把缓冲区里的内容落成正式块节点
    //
    // 这样做的目的，是在保持实现简单的同时，
    // 让段落和代码块都能保留原有的多行信息。
    final List<String> lines = source.split('\n');
    final List<MarkdownBlock> blocks = <MarkdownBlock>[];
    final List<String> paragraphBuffer = <String>[];
    final List<String> codeBuffer = <String>[];
    bool inCodeBlock = false;

    void flushParagraph() {
      if (paragraphBuffer.isEmpty) {
        return;
      }
      // 连续的普通文本行会被视为同一个段落，
      // 只有在遇到结构性边界时才会被真正提交。
      blocks.add(
        MarkdownBlock(
          type: MarkdownBlockType.paragraph,
          text: paragraphBuffer.join('\n').trim(),
        ),
      );
      paragraphBuffer.clear();
    }

    void flushCodeBlock() {
      if (codeBuffer.isEmpty) {
        return;
      }
      // 代码块保留行内换行，不做额外压缩，
      // 这样可以尽量贴近用户输入或模型输出的原始结构。
      blocks.add(
        MarkdownBlock(
          type: MarkdownBlockType.code,
          text: codeBuffer.join('\n').trimRight(),
        ),
      );
      codeBuffer.clear();
    }

    for (final String line in lines) {
      final String trimmedRight = line.trimRight();
      final String trimmed = trimmedRight.trim();

      if (trimmedRight.trimLeft().startsWith('```')) {
        // 三引号本身只作为“状态切换符”使用，不进入最终内容。
        // 进入代码块前先提交已有段落；退出代码块时再提交代码内容。
        if (inCodeBlock) {
          flushCodeBlock();
        } else {
          flushParagraph();
        }
        inCodeBlock = !inCodeBlock;
        continue;
      }

      if (inCodeBlock) {
        // 代码块内部不再尝试识别标题、列表等 Markdown 结构，
        // 一律按纯文本收集。
        codeBuffer.add(trimmedRight);
        continue;
      }

      if (trimmed.isEmpty) {
        // 空行意味着当前段落结束。
        flushParagraph();
        continue;
      }

      final RegExpMatch? headingMatch =
          RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(trimmedRight);
      if (headingMatch != null) {
        // 标题是天然的块边界，因此在创建标题块前，
        // 需要先把前面积累的段落提交掉。
        flushParagraph();
        blocks.add(
          MarkdownBlock(
            type: MarkdownBlockType.heading,
            text: headingMatch.group(2)?.trim() ?? '',
            level: headingMatch.group(1)?.length ?? 1,
          ),
        );
        continue;
      }

      final RegExpMatch? quoteMatch =
          RegExp(r'^>\s?(.*)$').firstMatch(trimmedRight);
      if (quoteMatch != null) {
        // 当前实现按“单行引用块”处理，优先满足项目里的展示需求，
        // 不额外引入更复杂的多层引用合并规则。
        flushParagraph();
        blocks.add(
          MarkdownBlock(
            type: MarkdownBlockType.quote,
            text: quoteMatch.group(1)?.trim() ?? '',
          ),
        );
        continue;
      }

      final RegExpMatch? unorderedListMatch =
          RegExp(r'^[-*+]\s+(.*)$').firstMatch(trimmedRight);
      if (unorderedListMatch != null) {
        // 列表项逐行落块，后续渲染层再决定其视觉表现。
        flushParagraph();
        blocks.add(
          MarkdownBlock(
            type: MarkdownBlockType.unorderedList,
            text: unorderedListMatch.group(1)?.trim() ?? '',
          ),
        );
        continue;
      }

      final RegExpMatch? orderedListMatch =
          RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmedRight);
      if (orderedListMatch != null) {
        // 有序列表会额外记录序号，避免渲染层再做重复解析。
        flushParagraph();
        blocks.add(
          MarkdownBlock(
            type: MarkdownBlockType.orderedList,
            text: orderedListMatch.group(2)?.trim() ?? '',
            index: int.tryParse(orderedListMatch.group(1) ?? '') ?? 1,
          ),
        );
        continue;
      }

      // 没有命中任何特殊结构时，归入普通段落缓冲区。
      paragraphBuffer.add(trimmedRight);
    }

    // 文件结束时，最后一个段落 / 代码块仍可能还在缓冲区里，
    // 因此需要做一次兜底冲刷。
    flushParagraph();
    flushCodeBlock();
    return blocks;
  }
}
