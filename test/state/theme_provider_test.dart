import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomstyler/state/theme_provider.dart';

void main() {
  group('Theme Provider Tests', () {
    test('Theme provider initializes with system theme', () {
      final container = ProviderContainer();
      final themeMode = container.read(themeProvider);
      
      expect(themeMode, AppThemeMode.system);
    });

    test('Theme provider can change theme mode', () {
      final container = ProviderContainer();
      final notifier = container.read(themeProvider.notifier);
      
      // Change to dark theme
      notifier.state = AppThemeMode.dark;
      expect(container.read(themeProvider), AppThemeMode.dark);
      
      // Change to light theme
      notifier.state = AppThemeMode.light;
      expect(container.read(themeProvider), AppThemeMode.light);
    });
  });
}