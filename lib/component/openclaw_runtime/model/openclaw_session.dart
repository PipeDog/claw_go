/// 会话状态。
enum OpenClawSessionStatus {
  idle,
  starting,
  running,
  stopped,
  failed,
}

/// OpenClaw 运行会话。
class OpenClawSession {
  const OpenClawSession({
    required this.id,
    required this.profileId,
    required this.status,
    required this.startedAt,
    required this.commandLabel,
    this.pid,
    this.exitCode,
  });

  final String id;
  final String profileId;
  final OpenClawSessionStatus status;
  final DateTime startedAt;
  final String commandLabel;
  final int? pid;
  final int? exitCode;

  OpenClawSession copyWith({
    String? id,
    String? profileId,
    OpenClawSessionStatus? status,
    DateTime? startedAt,
    String? commandLabel,
    int? pid,
    int? exitCode,
    bool clearExitCode = false,
  }) {
    return OpenClawSession(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      commandLabel: commandLabel ?? this.commandLabel,
      pid: pid ?? this.pid,
      exitCode: clearExitCode ? null : exitCode ?? this.exitCode,
    );
  }
}
