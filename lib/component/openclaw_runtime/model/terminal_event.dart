/// 终端事件类型。
enum TerminalEventType {
  stdout,
  stderr,
  status,
}

/// 控制台流事件。
class TerminalEvent {
  const TerminalEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  final TerminalEventType type;
  final String data;
  final DateTime timestamp;
}
