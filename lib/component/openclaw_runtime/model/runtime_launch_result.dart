import 'openclaw_session.dart';
import 'terminal_event.dart';

typedef SessionInputWriter = Future<void> Function(String input);

/// 启动会话后的返回对象。
class RuntimeLaunchResult {
  const RuntimeLaunchResult({
    required this.session,
    required this.events,
    required this.sendInput,
  });

  final OpenClawSession session;
  final Stream<TerminalEvent> events;
  final SessionInputWriter sendInput;
}
