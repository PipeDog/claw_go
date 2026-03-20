import 'package:flutter/material.dart';

/// 应用主题配置。
///
/// 同时提供浅色 / 深色两套桌面主题，并通过语义色方法向页面暴露动态颜色。
class AppTheme {
  const AppTheme._();

  static const Color accent = Color(0xFF5B7CFA);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFEF4444);

  static ThemeData lightTheme() {
    return _buildTheme(
      brightness: Brightness.light,
      background: const Color(0xFFF3F6FB),
      panel: const Color(0xFFFFFFFF),
      panelSecondary: const Color(0xFFF8FAFD),
      border: const Color(0xFFE2E8F0),
      textPrimary: const Color(0xFF0F172A),
      textSecondary: const Color(0xFF64748B),
    );
  }

  static ThemeData darkTheme() {
    return _buildTheme(
      brightness: Brightness.dark,
      background: const Color(0xFF0B1020),
      panel: const Color(0xFF11182B),
      panelSecondary: const Color(0xFF172033),
      border: const Color(0xFF283247),
      textPrimary: const Color(0xFFF8FAFC),
      textSecondary: const Color(0xFF94A3B8),
    );
  }

  static ThemeMode themeModeFromName(String value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color panel,
    required Color panelSecondary,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: accent,
      primary: accent,
      secondary: accent,
      surface: panel,
      error: danger,
    ).copyWith(
      surface: panel,
      onSurface: textPrimary,
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: panel,
      dividerColor: border,
      canvasColor: panel,
      shadowColor: Colors.black.withValues(
        alpha: brightness == Brightness.dark ? 0.28 : 0.08,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 30,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 15,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: textSecondary,
          fontSize: 12,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelSecondary,
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger),
        ),
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: panelSecondary,
        contentTextStyle: TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          minimumSize: const Size(0, 46),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          backgroundColor: panel,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          minimumSize: const Size(0, 46),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          minimumSize: const Size(0, 44),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: panelSecondary,
        selectedColor: accent,
        secondarySelectedColor: accent,
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: textPrimary),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: const StadiumBorder(),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: textPrimary,
        unselectedLabelColor: textSecondary,
        indicatorSize: TabBarIndicatorSize.label,
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        labelPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: accent,
            width: 3,
          ),
        ),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Color backgroundOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0B1020)
        : const Color(0xFFF3F6FB);
  }

  static Color panelOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF11182B)
        : const Color(0xFFFFFFFF);
  }

  static Color panelSecondaryOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF172033)
        : const Color(0xFFF8FAFD);
  }

  /// 轻层背景：用于工具条、输入区、右侧辅助栏等次级分区。
  static Color sectionMutedOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF131C2E)
        : const Color(0xFFF6F8FC);
  }

  /// 内容画布背景：用于聊天主内容区等需要拉开层次的主体区域。
  static Color sectionCanvasOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0E1525)
        : const Color(0xFFF9FBFE);
  }

  static Color borderOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF283247)
        : const Color(0xFFE2E8F0);
  }

  static Color textPrimaryOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);
  }

  static Color textSecondaryOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
  }
}
