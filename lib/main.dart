import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'config.dart'; // Config 임포트
import 'state/theme_provider.dart'; // Import theme provider

/// API 키가 설정되지 않았을 때 사용자에게 보여줄 간단한 앱
class ConfigErrorApp extends StatelessWidget {
  final String errorMessage;
  const ConfigErrorApp({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('앱 설정 오류')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('필수 API 키가 설정되지 않았습니다.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('오류 메시지: $errorMessage', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              const Text('빌드 시 --dart-define 플래그를 사용하거나, 개발용으로 코드에 직접 설정해주세요.'),
              const SizedBox(height: 8),
              const Text('예: flutter run --dart-define=GEMINI_API_KEY=your_key_here --dart-define=CLIPDROP_API_KEY=your_key_here'),
            ],
          ),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Config 초기화 확인
  if (!Config.isInitialized()) {
    runApp(const ProviderScope(
        child: ConfigErrorApp(
            errorMessage:
                'API 키가 설정되지 않았습니다. 빌드 시 --dart-define 플래그를 사용하거나, 개발용으로 코드에 직접 설정해주세요.')));
    return; // 앱 종료
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // App Check 활성화
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );
  
  runApp(
    const ProviderScope(
      child: AppLoader(), // AppLoader를 먼저 실행
    ),
  );
}

// 앱 시작 시 SharedPreferences에서 테마 설정을 불러오는 로더 위젯
class AppLoader extends ConsumerWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 앱 시작 시 테마 모드를 로드합니다.
    ref.read(themeProvider.notifier).loadThemeMode();
    
    // 테마 로드가 완료되면 실제 App 위젯을 렌더링합니다.
    return const App();
  }
}
