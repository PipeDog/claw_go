/// Markdown 块级节点类型。
///
/// 当前只覆盖项目实际需要的基础能力，
/// 保证代码可读、可维护，并避免过度设计。
enum MarkdownBlockType {
  /// 标题。
  heading,

  /// 段落。
  paragraph,

  /// 无序列表。
  unorderedList,

  /// 有序列表。
  orderedList,

  /// 引用。
  quote,

  /// 代码块。
  code,
}

/// Markdown 块级节点。
///
/// 用于承载解析后的结构化结果，再交给渲染层逐块输出。
class MarkdownBlock {
  const MarkdownBlock({
    required this.type,
    required this.text,
    this.level = 0,
    this.index = 0,
  });

  /// 当前块的类型。
  final MarkdownBlockType type;

  /// 块的主文本内容。
  final String text;

  /// 标题层级，仅对 heading 有意义。
  final int level;

  /// 有序列表序号，仅对 orderedList 有意义。
  final int index;
}
