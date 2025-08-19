import 'package:flutter/material.dart';

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorSchemeSeed: const Color(0xFF3E6AE1), // 브랜드 색 (시드)
  );
  return base.copyWith(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    navigationBarTheme: const NavigationBarThemeData(
      height: 70,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    cardTheme: const CardThemeData(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: EdgeInsets.all(8),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      showDragHandle: true,
      elevation: 0,
      backgroundColor: base.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: base.colorScheme.surface,
      foregroundColor: base.colorScheme.onSurface,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[800],
      contentTextStyle: const TextStyle(color: Colors.white),
    ),
  );
}
