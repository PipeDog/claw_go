import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../../../foundation/ui/markdown/markdown.dart';
import '../model/assistant_chat_message.dart';

/// 对话时间线视图。
class TaskChatTimelineView extends StatefulWidget {
  const TaskChatTimelineView({
    super.key,
    required this.messages,
    required this.agentLabel,
    this.revertedFromTaskTitle,
  });

  final List<AssistantChatMessage> messages;
  final String agentLabel;
  final String? revertedFromTaskTitle;

  @override
  State<TaskChatTimelineView> createState() => _TaskChatTimelineViewState();
}

class _TaskChatTimelineViewState extends State<TaskChatTimelineView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(covariant TaskChatTimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool messageCountChanged =
        oldWidget.messages.length != widget.messages.length;
    final bool lastMessageChanged =
        !_sameTail(oldWidget.messages, widget.messages);
    if (messageCountChanged || lastMessageChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
          decoration: BoxDecoration(
            color: AppTheme.panelOf(context).withValues(alpha: 0.72),
            border: Border(
              bottom: BorderSide(color: AppTheme.borderOf(context)),
            ),
          ),
          child: Row(
            children: <Widget>[
              Text(
                widget.agentLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.messages.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (widget.revertedFromTaskTitle != null)
                Flexible(
                  child: Text(
                    widget.revertedFromTaskTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.end,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: widget.messages.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              AppTheme.accent.withValues(alpha: 0.12),
                          child: const Icon(
                            Icons.forum_outlined,
                            color: AppTheme.accent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.text('chat.empty_title'),
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  itemCount: widget.messages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    final AssistantChatMessage message = widget.messages[index];
                    return _ConversationMessageItem(message: message);
                  },
                ),
        ),
      ],
    );
  }

  bool _sameTail(
    List<AssistantChatMessage> left,
    List<AssistantChatMessage> right,
  ) {
    if (left.isEmpty && right.isEmpty) {
      return true;
    }
    if (left.isEmpty || right.isEmpty) {
      return false;
    }
    final AssistantChatMessage l = left.last;
    final AssistantChatMessage r = right.last;
    return l.id == r.id && l.content == r.content && l.state == r.state;
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }
}

class _ConversationMessageItem extends StatelessWidget {
  const _ConversationMessageItem({required this.message});

  final AssistantChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.role == AssistantChatMessageRole.user;
    final ThemeData theme = Theme.of(context);
    final Color bubbleColor = isUser
        ? AppTheme.accent
        : AppTheme.panelOf(context).withValues(alpha: 0.72);
    final Color textColor =
        isUser ? Colors.white : AppTheme.textPrimaryOf(context);
    final String senderName = isUser
        ? AppLocalizations.of(context).text('chat.timeline_user')
        : 'OpenClaw';
    final bool isLoading = message.state == AssistantChatMessageState.loading;
    final bool isPureLoading = isLoading && message.content.trim().isEmpty;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth;
        final double normalBubbleMaxWidth =
            (availableWidth * (isUser ? 0.7 : 0.76))
                .clamp(260.0, 820.0)
                .toDouble();
        final double loadingBubbleMaxWidth = isPureLoading
            ? (availableWidth * 0.24).clamp(160.0, 220.0).toDouble()
            : (availableWidth * 0.5).clamp(240.0, 420.0).toDouble();
        final double bubbleMaxWidth =
            !isUser && isLoading ? loadingBubbleMaxWidth : normalBubbleMaxWidth;

        return Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!isUser) ...<Widget>[
              _MessageAvatar(isUser: false, state: message.state),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (isUser)
                        Text(
                          _formatTime(message.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryOf(context),
                          ),
                        ),
                      if (isUser) const SizedBox(width: 8),
                      Text(
                        senderName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                      if (!isUser) const SizedBox(width: 8),
                      if (!isUser)
                        Text(
                          _formatTime(message.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryOf(context),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(18),
                        border: isUser
                            ? null
                            : Border.all(
                                color: message.state ==
                                        AssistantChatMessageState.failed
                                    ? AppTheme.danger.withValues(alpha: 0.35)
                                    : AppTheme.borderOf(context),
                              ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SizeTransition(
                              sizeFactor: animation,
                              axisAlignment: -1,
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<String>(
                            '${message.id}-${message.state.name}-${message.content}',
                          ),
                          child: _buildMessageBody(context, textColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isUser) ...<Widget>[
              const SizedBox(width: 10),
              const _MessageAvatar(isUser: true),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMessageBody(BuildContext context, Color textColor) {
    if (message.state == AssistantChatMessageState.loading &&
        message.content.trim().isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _StreamingDotsIndicator(),
          const SizedBox(width: 10),
          Text(
            AppLocalizations.of(context).text('common.loading'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryOf(context),
                ),
          ),
        ],
      );
    }

    final Widget messageContent = MarkdownTextView(
      data: message.content,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
      textColor: message.state == AssistantChatMessageState.failed
          ? AppTheme.danger
          : textColor,
      selectable: true,
    );

    if (message.state != AssistantChatMessageState.loading) {
      return messageContent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        messageContent,
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const _StreamingDotsIndicator(compact: true),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).text('chat.processing'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _StreamingDotsIndicator extends StatefulWidget {
  const _StreamingDotsIndicator({
    this.compact = false,
  });

  final bool compact;

  @override
  State<_StreamingDotsIndicator> createState() =>
      _StreamingDotsIndicatorState();
}

class _StreamingDotsIndicatorState extends State<_StreamingDotsIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 960),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double dotSize = widget.compact ? 5 : 6;
    final double gap = widget.compact ? 4 : 5;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (int index) {
            final double opacity = _resolveDotOpacity(index, _controller.value);
            return Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : gap),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double _resolveDotOpacity(int index, double value) {
    final double shifted = (value - index * 0.16) % 1.0;
    if (shifted < 0.2) {
      return 0.35 + shifted / 0.2 * 0.65;
    }
    if (shifted < 0.55) {
      return 1.0 - (shifted - 0.2) / 0.35 * 0.45;
    }
    return 0.35;
  }
}

class _MessageAvatar extends StatelessWidget {
  const _MessageAvatar({
    required this.isUser,
    this.state = AssistantChatMessageState.success,
  });

  final bool isUser;
  final AssistantChatMessageState state;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isUser
        ? AppTheme.accent.withValues(alpha: 0.16)
        : state == AssistantChatMessageState.failed
            ? AppTheme.danger.withValues(alpha: 0.12)
            : AppTheme.panelSecondaryOf(context);
    final Color iconColor = isUser
        ? AppTheme.accent
        : state == AssistantChatMessageState.failed
            ? AppTheme.danger
            : AppTheme.textPrimaryOf(context);

    return CircleAvatar(
      radius: 18,
      backgroundColor: backgroundColor,
      child: Icon(
        isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
        size: 18,
        color: iconColor,
      ),
    );
  }
}

String _formatTime(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}
