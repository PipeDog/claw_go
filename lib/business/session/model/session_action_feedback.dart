/// Session/Gateway 操作结果。
class SessionActionFeedback {
  const SessionActionFeedback({
    required this.success,
    required this.message,
  });

  const SessionActionFeedback.success(String message)
      : this(success: true, message: message);

  const SessionActionFeedback.failure(String message)
      : this(success: false, message: message);

  final bool success;
  final String message;
}
