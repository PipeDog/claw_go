import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../model/chat_runtime_option.dart';

/// 聊天运行配置顶部栏。
///
/// 这里采用更轻量的圆角矩形选择器，减少顶部区域的视觉占用，
/// 让布局更接近 header 的紧凑感。
class ChatRuntimeSelectorCardView extends StatelessWidget {
  const ChatRuntimeSelectorCardView({
    super.key,
    required this.agents,
    required this.models,
    required this.selectedAgentId,
    required this.selectedModelId,
    required this.loading,
    required this.onAgentChanged,
    required this.onModelChanged,
  });

  final List<ChatRuntimeOption> agents;
  final List<ChatRuntimeOption> models;
  final String? selectedAgentId;
  final String? selectedModelId;
  final bool loading;
  final ValueChanged<String?> onAgentChanged;
  final ValueChanged<String?> onModelChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        _SelectorField(
          width: 190,
          labelText: l10n.text('chat.runtime_agent'),
          hintText: l10n.text('common.none'),
          value: selectedAgentId,
          items: agents,
          enabled: !loading && agents.isNotEmpty,
          onChanged: onAgentChanged,
        ),
        _SelectorField(
          width: 210,
          labelText: l10n.text('chat.runtime_model'),
          hintText: l10n.text('common.none'),
          value: selectedModelId,
          items: models,
          enabled: !loading && models.isNotEmpty,
          onChanged: onModelChanged,
        ),
        if (loading) ...<Widget>[
          const SizedBox(width: 10),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ],
    );
  }
}

class _SelectorField extends StatelessWidget {
  const _SelectorField({
    required this.width,
    required this.labelText,
    required this.hintText,
    required this.value,
    required this.items,
    required this.enabled,
    required this.onChanged,
  });

  final double width;
  final String labelText;
  final String hintText;
  final String? value;
  final List<ChatRuntimeOption> items;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle labelStyle =
        theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600) ??
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
    final TextStyle valueStyle = theme.textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

    return SizedBox(
      width: width,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.panelSecondaryOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderOf(context)),
        ),
        child: Row(
          children: <Widget>[
            Text(
              labelText,
              style: labelStyle.copyWith(
                color: AppTheme.textSecondaryOf(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: items.any((ChatRuntimeOption item) => item.id == value)
                      ? value
                      : null,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                  hint: Text(
                    hintText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: valueStyle.copyWith(
                      color: theme.hintColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: valueStyle.copyWith(
                    color: AppTheme.textPrimaryOf(context),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  items: items.map((ChatRuntimeOption item) {
                    return DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: valueStyle.copyWith(
                          color: AppTheme.textPrimaryOf(context),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: enabled ? onChanged : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
