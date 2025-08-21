import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:roomstyler/features/auth/sign_up_screen.dart';
import 'features/home/home_screen.dart';
import 'features/room_upload/room_upload_screen.dart';
import 'features/catalog/catalog_screen.dart';
import 'features/editor/editor_screen.dart';
import 'features/preview_share/preview_share_screen.dart';
import 'features/auth/sign_in_screen.dart';

// listenable을 사용해 인증 상태 변경 시 라우터를 자동으로 새로고침
final router = GoRouter(
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/upload', builder: (_, __) => const RoomUploadScreen()),
    GoRoute(path: '/catalog', builder: (_, __) => const CatalogScreen()),
    GoRoute(
  path: '/editor',
  builder: (context, state) {
    final imagePath = state.extra as String?;
    return EditorScreen(imagePath: imagePath);
  },
),
    GoRoute(path: '/preview', builder: (_, __) => const PreviewShareScreen()),
    GoRoute(path: '/signin', builder: (_, __) => const SignInScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
  ],
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isAuthRoute = state.matchedLocation == '/signin' || state.matchedLocation == '/signup';

    // 로그인하지 않은 상태에서, 로그인/회원가입 페이지가 아니면 -> 로그인 페이지로
    if (user == null) {
      return isAuthRoute ? null : '/signin';
    }
    // 로그인한 상태에서, 로그인/회원가입 페이지에 있으면 -> 홈으로
    if (isAuthRoute) {
      return '/';
    }
    return null; // 그 외에는 그대로 두기
  },
);

// FirebaseAuth의 인증 상태 변경을 GoRouter에 알려주는 스트림
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.asBroadcastStream().listen((_) => notifyListeners());
  }
}

