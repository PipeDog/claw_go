import 'package:flutter/material.dart';

import '../../business/session/page/logs_page.dart';
import '../../business/session/page/session_page.dart';
import '../config/app_theme.dart';

/// Connect 工作区。
class ConnectPage extends StatelessWidget {
  const ConnectPage({super.key});

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
              child: TabBarView(
                children: <Widget>[
                  SessionPage(
                    showPageHeader: false,
                    padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
                    showGatewaySection: true,
                    showCommandSection: false,
                  ),
                  SessionPage(
                    showPageHeader: false,
                    padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
                    showGatewaySection: false,
                    showCommandSection: true,
                  ),
                  LogsPage(
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
