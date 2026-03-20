import 'package:flutter/material.dart';

/// 热重载监听器。
///
/// 包裹子组件，在热重载时触发 [onHotReload] 回调，并强制重建子树。
/// Flutter 热重载默认会保留已有状态，入口层的初始化逻辑与根级状态容器
/// 往往不会重新创建，因此这里通过 [KeyedSubtree] 切换 key 来重建整棵子树。
///
/// 仅在 Debug 模式下会触发 [reassemble]；Release 构建不会执行这里的逻辑。
class HotReloadWatcher extends StatefulWidget {
  const HotReloadWatcher({
    super.key,
    required this.child,
    this.onHotReload,
  });

  final Widget child;

  /// 热重载时执行的回调，通常用于重新执行入口初始化流程。
  final VoidCallback? onHotReload;

  @override
  State<HotReloadWatcher> createState() => _HotReloadWatcherState();
}

class _HotReloadWatcherState extends State<HotReloadWatcher> {
  /// 热重载次数，同时作为 [KeyedSubtree] 的 key。
  int _rebuildKey = 0;

  @override
  void reassemble() {
    super.reassemble();
    widget.onHotReload?.call();

    setState(() {
      _rebuildKey += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey<int>(_rebuildKey),
      child: widget.child,
    );
  }
}
