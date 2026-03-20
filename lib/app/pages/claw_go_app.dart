import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../config/router_config.dart';
import '../../business/settings/view_model/settings_view_model.dart';
import '../../foundation/i18n/app_localizations.dart';

/// 应用根组件。
class ClawGoApp extends ConsumerWidget {
  const ClawGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsViewModelProvider).settings;

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: AppTheme.themeModeFromName(settings.themeMode),
      locale: Locale(settings.localeCode),
      supportedLocales: const <Locale>[
        Locale('en'),
        Locale('zh'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
