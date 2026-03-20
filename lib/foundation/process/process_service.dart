import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 进程服务 Provider。
final processServiceProvider = Provider<ProcessService>((Ref ref) {
  return ProcessService();
});

/// 底层进程调用封装。
///
/// 统一处理一次性命令执行和长生命周期进程启动，
/// 让 Runtime 层专注在 OpenClaw 命令语义，而不是重复处理 Process API。
class ProcessService {
  Future<CommandResult> run({
    required String executable,
    List<String> arguments = const <String>[],
    String? workingDirectory,
    Map<String, String> environment = const <String, String>{},
  }) async {
    final ProcessResult result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: false,
    );

    return CommandResult(
      exitCode: result.exitCode,
      stdoutText: (result.stdout ?? '').toString(),
      stderrText: (result.stderr ?? '').toString(),
    );
  }

  Future<ManagedProcess> start({
    required String executable,
    List<String> arguments = const <String>[],
    String? workingDirectory,
    Map<String, String> environment = const <String, String>{},
  }) async {
    final Process process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: false,
    );

    return ManagedProcess(
      process: process,
      stdoutLines: const LineSplitter().bind(utf8.decoder.bind(process.stdout)),
      stderrLines: const LineSplitter().bind(utf8.decoder.bind(process.stderr)),
    );
  }
}

/// 一次性命令结果。
class CommandResult {
  const CommandResult({
    required this.exitCode,
    required this.stdoutText,
    required this.stderrText,
  });

  final int exitCode;
  final String stdoutText;
  final String stderrText;

  String get mergedOutput {
    final StringBuffer buffer = StringBuffer();
    if (stdoutText.trim().isNotEmpty) {
      buffer.writeln(stdoutText.trim());
    }
    if (stderrText.trim().isNotEmpty) {
      buffer.writeln(stderrText.trim());
    }
    return buffer.toString().trim();
  }
}

/// 受管控的长生命周期进程。
class ManagedProcess {
  ManagedProcess({
    required this.process,
    required this.stdoutLines,
    required this.stderrLines,
  });

  final Process process;
  final Stream<String> stdoutLines;
  final Stream<String> stderrLines;

  int get pid => process.pid;
  Future<int> get exitCode => process.exitCode;

  Future<void> write(String input) async {
    process.stdin.writeln(input);
    await process.stdin.flush();
  }

  Future<void> dispose() async {
    try {
      await process.stdin.close();
    } catch (_) {
      // 进程结束后重复关闭 stdin 属于可忽略场景。
    }
  }

  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    return process.kill(signal);
  }
}
