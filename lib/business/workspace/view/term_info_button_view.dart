import 'package:flutter/material.dart';

import '../../../foundation/i18n/app_localizations.dart';
import '../model/environment_glossary_item.dart';

/// 术语说明按钮。
class TermInfoButtonView extends StatelessWidget {
  const TermInfoButtonView({
    super.key,
    required this.item,
  });

  final EnvironmentGlossaryItem item;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return IconButton(
      visualDensity: VisualDensity.compact,
      iconSize: 18,
      splashRadius: 18,
      tooltip: l10n.text('environment.glossary.learn_more'),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(l10n.text(item.termKey)),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _InfoRow(
                    label: l10n.text('environment.glossary.source'),
                    value: l10n.text(_sourceKey(item.sourceType)),
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: l10n.text('environment.glossary.meaning'),
                    value: l10n.text(item.descriptionKey),
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: l10n.text('environment.glossary.mapping'),
                    value: l10n.text(item.mappingKey),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.text('common.close')),
              ),
            ],
          );
        },
      ),
      icon: const Icon(Icons.info_outline_rounded),
    );
  }

  String _sourceKey(EnvironmentGlossarySourceType sourceType) {
    return switch (sourceType) {
      EnvironmentGlossarySourceType.clawGo =>
        'environment.glossary.source_clawgo',
      EnvironmentGlossarySourceType.openClaw =>
        'environment.glossary.source_openclaw',
      EnvironmentGlossarySourceType.mixed =>
        'environment.glossary.source_mixed',
    };
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        SelectableText(value),
      ],
    );
  }
}
