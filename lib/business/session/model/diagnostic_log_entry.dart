/// 诊断日志分类。
///
/// 这里不直接依赖 Flutter 颜色，保持 Model 只描述语义，
/// 具体的视觉映射交给 View 层处理。
enum DiagnosticLogCategory {
  error,
  success,
  request,
  gateway,
  normal,
}

/// 诊断日志条目。
///
/// 将原始字符串日志转换成带语义的信息结构，便于：
/// 1. 页面做统计汇总；
/// 2. 列表根据类别做视觉分组；
/// 3. 后续继续扩展筛选、搜索等能力。
class DiagnosticLogEntry {
  const DiagnosticLogEntry({
    required this.sequence,
    required this.message,
    required this.category,
  });

  /// 原始日志在完整日志流中的序号。
  final int sequence;

  /// 原始日志内容。
  final String message;

  /// 该条日志的语义分类。
  final DiagnosticLogCategory category;

  /// 将原始日志行解析成结构化条目。
  ///
  /// 这里采用“关键词命中优先”的策略：
  /// - 先识别异常，因为异常优先级最高；
  /// - 再识别成功态，避免被更宽泛的普通关键词覆盖；
  /// - 最后兜底为普通日志。
  factory DiagnosticLogEntry.fromLine({
    required int sequence,
    required String line,
  }) {
    return DiagnosticLogEntry(
      sequence: sequence,
      message: line,
      category: _resolveCategory(line),
    );
  }

  static DiagnosticLogCategory _resolveCategory(String line) {
    if (line.contains('⇄ res ✗') ||
        line.contains('errorMessage=') ||
        line.toLowerCase().contains('error') ||
        line.toLowerCase().contains('failed')) {
      return DiagnosticLogCategory.error;
    }
    if (line.contains('granted scopes') ||
        line.contains('已连接') ||
        line.toLowerCase().contains('connected') ||
        line.toLowerCase().contains('success')) {
      return DiagnosticLogCategory.success;
    }
    if (line.contains('connect.challenge') || line.contains('⇢ req')) {
      return DiagnosticLogCategory.request;
    }
    if (line.contains('[gateway]') ||
        line.toLowerCase().contains('gateway') ||
        line.toLowerCase().contains('socket')) {
      return DiagnosticLogCategory.gateway;
    }
    return DiagnosticLogCategory.normal;
  }
}
