// lib/config.dart

/// 앱 설정 및 API 키 관리
class Config {
  // API 키는 빌드 시 --dart-define 플래그를 통해 주입되거나,
  // 개발 편의를 위해 코드에 직접 설정할 수 있습니다. (Git에 절대 올리지 마세요!)
  // 예: flutter run --dart-define=GEMINI_API_KEY=your_key_here --dart-define=CLIPDROP_API_KEY=your_key_here
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String clipdropApiKey = String.fromEnvironment('CLIPDROP_API_KEY', defaultValue: '');

  /// 모든 필수 API 키가 설정되었는지 확인합니다.
  static bool isInitialized() {
    return geminiApiKey.isNotEmpty && clipdropApiKey.isNotEmpty;
  }
}