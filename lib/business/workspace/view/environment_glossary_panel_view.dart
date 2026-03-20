import 'package:flutter/material.dart';

import '../../../app/config/app_theme.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../model/environment_glossary_catalog.dart';
import '../model/environment_glossary_item.dart';

/// Environment 术语说明面板。
class EnvironmentGlossaryPanelView extends StatelessWidget {
  const EnvironmentGlossaryPanelView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.sectionMutedOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.text('environment.glossary.title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.text('environment.glossary.subtitle'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(l10n.text('environment.glossary.expand')),
              subtitle: Text(l10n.text('environment.glossary.expand_desc')),
              children: EnvironmentGlossaryCatalog.items
                  .map(
                    (EnvironmentGlossaryItem item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _GlossaryTile(item: item),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlossaryTile extends StatelessWidget {
  const _GlossaryTile({required this.item});

  final EnvironmentGlossaryItem item;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String sourceLabel = switch (item.sourceType) {
      EnvironmentGlossarySourceType.clawGo =>
        l10n.text('environment.glossary.source_clawgo'),
      EnvironmentGlossarySourceType.openClaw =>
        l10n.text('environment.glossary.source_openclaw'),
      EnvironmentGlossarySourceType.mixed =>
        l10n.text('environment.glossary.source_mixed'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.text(item.termKey),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          sourceLabel,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Text(l10n.text(item.descriptionKey)),
        const SizedBox(height: 6),
        SelectableText(
          '${l10n.text('environment.glossary.mapping')}: '
          '${l10n.text(item.mappingKey)}',
        ),
      ],
    );
  }
}
