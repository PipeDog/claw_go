import 'package:flutter/material.dart';

import '../../../foundation/i18n/app_localizations.dart';
import '../../../foundation/ui/markdown/markdown.dart';
import '../model/markdown_test_fixture.dart';
import '../view/markdown_test_preview_view.dart';

/// Markdown 测试页面。
///
/// 该页面专门用于验证 Markdown 基础组件在不同 UI 载体中的表现，
/// 并通过固定样例覆盖核心展示 case，方便持续肉眼回归。
class MarkdownTestPage extends StatelessWidget {
  const MarkdownTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.text('markdown_test.title'),
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.text('markdown_test.description'),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          MarkdownTestPreviewView(
            title: l10n.text('markdown_test.full_preview_title'),
            description: l10n.text('markdown_test.full_preview_desc'),
            child: MarkdownTextView(
              data: MarkdownTestFixture.fullDocument,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              textColor: theme.textTheme.bodyLarge?.color ?? Colors.white,
              selectable: true,
            ),
          ),
          const SizedBox(height: 16),
          MarkdownTestPreviewView(
            title: l10n.text('markdown_test.chat_preview_title'),
            description: l10n.text('markdown_test.chat_preview_desc'),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                MarkdownTestChatBubbleView(
                  content: MarkdownTestFixture.userMessage,
                  isUser: true,
                ),
                SizedBox(height: 12),
                MarkdownTestChatBubbleView(
                  content: MarkdownTestFixture.assistantMessage,
                  isUser: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MarkdownTestPreviewView(
            title: l10n.text('markdown_test.session_preview_title'),
            description: l10n.text('markdown_test.session_preview_desc'),
            child: const MarkdownTestSessionCardView(
              title: MarkdownTestFixture.sessionCardTitle,
              preview: MarkdownTestFixture.sessionCardPreview,
            ),
          ),
          const SizedBox(height: 16),
          MarkdownTestPreviewView(
            title: l10n.text('markdown_test.code_preview_title'),
            description: l10n.text('markdown_test.code_preview_desc'),
            child: MarkdownTextView(
              data: MarkdownTestFixture.codeOnlyDocument,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              textColor: theme.textTheme.bodyLarge?.color ?? Colors.white,
              selectable: true,
            ),
          ),
        ],
      ),
    );
  }
}
