import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_theme.dart';
import '../../../component/openclaw_runtime/model/openclaw_profile.dart';
import '../../../foundation/i18n/app_localizations.dart';
import '../../../foundation/utils/id_generator.dart';
import '../../workspace/view_model/workspace_view_model.dart';
import '../view/onboarding_result_view.dart';
import '../view_model/onboarding_view_model.dart';

/// 环境导入页。
class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({
    super.key,
    this.showPageHeader = true,
    this.padding = const EdgeInsets.all(24),
  });

  /// 是否展示页面主标题与描述。
  ///
  /// 独立作为一级页面时保持展示；
  /// 当作为 Environments 页的子 Tab 使用时可关闭，避免重复抬头。
  final bool showPageHeader;

  /// 内容区域内边距。
  ///
  /// 作为独立页面时使用正常页面间距；
  /// 作为页内 Tab 内容时可传入更紧凑的边距。
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(onboardingViewModelProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showPageHeader) ...<Widget>[
            Text(
              l10n.text('setup.title'),
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.text('setup.description'),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
          ],
          Container(
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
                        l10n.text('setup.instructions_title'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.text('setup.instructions_subtitle'),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppTheme.borderOf(context)),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const <Widget>[
                      Chip(label: Text('openclaw --version')),
                      Chip(label: Text('openclaw config file')),
                      Chip(label: Text('openclaw config validate --json')),
                      Chip(label: Text('openclaw gateway status --json')),
                      Chip(
                          label:
                              Text('openclaw agent --session-id main --json')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              FilledButton.icon(
                onPressed: viewModel.loading
                    ? null
                    : () => ref
                        .read(onboardingViewModelProvider)
                        .detectEnvironment(),
                icon: const Icon(Icons.search),
                label: Text(viewModel.loading
                    ? l10n.text('setup.detecting')
                    : l10n.text('setup.detect')),
              ),
              OutlinedButton.icon(
                onPressed: viewModel.detectionResult == null ||
                        !viewModel.detectionResult!.isOpenClawDetected ||
                        !viewModel.detectionResult!.isNodeSatisfied ||
                        !viewModel.detectionResult!.isConfigValid
                    ? null
                    : () async {
                        final detection = viewModel.detectionResult;
                        if (detection == null) {
                          return;
                        }
                        final OpenClawProfile profile =
                            OpenClawProfile.fromDetection(
                          id: IdGenerator.next('profile'),
                          detection: detection,
                        );
                        await ref
                            .read(workspaceViewModelProvider)
                            .saveProfile(profile);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(l10n.text('setup.imported'))),
                          );
                        }
                      },
                icon: const Icon(Icons.download_done_outlined),
                label: Text(l10n.text('setup.import_draft')),
              ),
            ],
          ),
          if (viewModel.errorMessage != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (viewModel.detectionResult != null) ...<Widget>[
            const SizedBox(height: 20),
            OnboardingResultView(result: viewModel.detectionResult!),
          ],
        ],
      ),
    );
  }
}
