import 'package:flutter/foundation.dart';
import 'dart:async';

/// 简单日志封装。
class AppLogger {
  const AppLogger._();

  static const int _kMaxEntries = 800;
  static final StreamController<String> _controller =
      StreamController<String>.broadcast();
  static final List<String> _entries = <String>[];

  static List<String> get entries => List<String>.unmodifiable(_entries);

  static Stream<String> watch() => _controller.stream;

  /// 清空当前进程中的日志缓存。
  static void clear() {
    _entries.clear();
  }

  static void info(String message) {
    final String formatted = '[ClawGo] $message';
    debugPrint(formatted);
    _entries.add(formatted);
    if (_entries.length > _kMaxEntries) {
      _entries.removeRange(0, _entries.length - _kMaxEntries);
    }
    if (!_controller.isClosed) {
      _controller.add(formatted);
    }
  }
}
