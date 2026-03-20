import 'package:flutter/material.dart';

import '../../business/onboarding/page/onboarding_page.dart';
import '../../business/workspace/page/workspace_page.dart';
import '../config/app_theme.dart';

/// Environments 工作区。
class EnvironmentsPage extends StatelessWidget {
  const EnvironmentsPage({super.key});

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
              child: const TabBarView(
                children: <Widget>[
                  OnboardingPage(
                    showPageHeader: false,
                    padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
                  ),
                  WorkspacePage(
                    showPageHeader: false,
                    padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
