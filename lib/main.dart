import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/pages/claw_go_app.dart';
import 'foundation/ui/hot_reload_watcher.dart';

/// 应用入口。
Future<void> main() async {
  await runAppStartup();
  runApp(_buildRootApp());
}

Widget _buildRootApp() {
  const Widget app = ProviderScope(child: ClawGoApp());
  if (!kDebugMode) {
    return app;
  }

  return HotReloadWatcher(
    onHotReload: () => unawaited(runAppStartup()),
    child: app,
  );
}

/// 执行应用启动流程。
///
/// 当前入口初始化较轻量，主要用于确保 Flutter 绑定完成初始化。
/// 后续如有全局依赖注入、配置加载等任务，也统一放在这里处理，
/// 以便在热重载后重新执行，避免入口状态与界面状态不一致。
Future<void> runAppStartup() async {
  WidgetsFlutterBinding.ensureInitialized();
}
