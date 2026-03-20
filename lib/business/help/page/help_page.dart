import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';

/// 帮助中心。
class HelpPage extends StatelessWidget {
  const HelpPage({
    super.key,
    required this.onOpenHome,
    required this.onOpenSettings,
  });

  final VoidCallback onOpenHome;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ColoredBox(
              color: AppTheme.sectionCanvasOf(context),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: <Widget>[
                    const _HelpSection(
                      title: '第一次使用怎么开始？',
                      description:
                          '直接去首页输入你的需求，系统会先尝试自动准备环境。如果无法自动准备，再去设置里的高级工具。',
                    ),
                    const SizedBox(height: 14),
                    const _HelpSection(
                      title: '为什么有些任务没成功？',
                      description:
                          '大多数失败都来自本地环境没有准备好、配置文件有问题，或底层命令返回错误。普通模式下会先给你友好的下一步提示。',
                    ),
                    const SizedBox(height: 14),
                    const _HelpSection(
                      title: '什么是高级工具？',
                      description: '高级工具里包含环境准备、工作配置和详细日志，仅在普通模式处理不了问题时再打开即可。',
                    ),
                    const SizedBox(height: 14),
                    _HelpSection(
                      title: '你现在可以这样做',
                      description: '从这里直接回到聊天或设置，继续当前操作。',
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          FilledButton.icon(
                            onPressed: onOpenHome,
                            icon: const Icon(Icons.home_outlined),
                            label: const Text('回到首页试用'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onOpenSettings,
                            icon: const Icon(Icons.settings_outlined),
                            label: const Text('打开设置'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.title,
    required this.description,
    this.child,
  });

  final String title;
  final String description;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.sectionMutedOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodyMedium),
          if (child != null) ...<Widget>[
            const SizedBox(height: 14),
            child!,
          ],
        ],
      ),
    );
  }
}
