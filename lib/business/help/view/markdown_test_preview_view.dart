import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/ui/app_panel.dart';
import '../../../foundation/ui/markdown/markdown.dart';

/// Markdown 测试用的通用预览面板。
///
/// 统一承载一个标题、说明和内容区域，避免测试页面中重复搭建相同结构。
class MarkdownTestPreviewView extends StatelessWidget {
  const MarkdownTestPreviewView({
    super.key,
    required this.title,
    required this.description,
    required this.child,
  });

  /// 面板标题。
  final String title;

  /// 面板说明。
  final String description;

  /// 面板主体内容。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: title,
      subtitle: description,
      child: child,
    );
  }
}

/// Markdown 聊天气泡测试视图。
///
/// 用于模拟聊天页中的实际展示效果，便于直接观察 Markdown 在气泡中的表现。
class MarkdownTestChatBubbleView extends StatelessWidget {
  const MarkdownTestChatBubbleView({
    super.key,
    required this.content,
    required this.isUser,
  });

  /// 聊天气泡内容。
  final String content;

  /// 是否为用户消息。
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color bubbleColor =
        isUser ? AppTheme.accent : AppTheme.panelSecondaryOf(context);
    final Color borderColor =
        isUser ? AppTheme.accent : AppTheme.borderOf(context);
    final Color textColor =
        isUser ? Colors.white : AppTheme.textPrimaryOf(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: MarkdownTextView(
            data: content,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            textColor: textColor,
            selectable: true,
          ),
        ),
      ),
    );
  }
}

/// Markdown 最近会话卡片测试视图。
///
/// 用于模拟“最近会话”中的标题和摘要预览效果，
/// 重点验证 maxLines / ellipsis 与 Markdown 行内渲染的配合情况。
class MarkdownTestSessionCardView extends StatelessWidget {
  const MarkdownTestSessionCardView({
    super.key,
    required this.title,
    required this.preview,
  });

  /// 卡片标题。
  final String title;

  /// 卡片摘要。
  final String preview;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.panelSecondaryOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MarkdownTextView(
            data: title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textColor: AppTheme.textPrimaryOf(context),
          ),
          const SizedBox(height: 8),
          MarkdownTextView(
            data: preview,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
            textColor: AppTheme.textSecondaryOf(context),
          ),
        ],
      ),
    );
  }
}
