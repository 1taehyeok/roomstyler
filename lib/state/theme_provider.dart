// lib/state/theme_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 테마 모드를 정의하는 enum
enum AppThemeMode {
  light,
  dark,
  system,
}

// 테마 상태를 관리하는 Notifier 클래스
class ThemeNotifier extends Notifier<AppThemeMode> {
  static const String _prefsKey = 'theme_mode';
  
  @override
  AppThemeMode build() {
    // 초기 상태는 시스템 설정을 따름
    return AppThemeMode.system;
  }

  // 테마 모드를 변경하고 SharedPreferences에 저장
  Future<void> setThemeMode(AppThemeMode themeMode) async {
    state = themeMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, themeMode.name);
  }

  // SharedPreferences에서 저장된 테마 모드를 불러옴
  Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_prefsKey);
    
    if (themeModeString != null) {
      state = AppThemeMode.values.firstWhere(
        (e) => e.name == themeModeString,
        orElse: () => AppThemeMode.system,
      );
    } else {
      state = AppThemeMode.system;
    }
  }
}

// Riverpod Provider 정의
final themeProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(() {
  return ThemeNotifier();
});