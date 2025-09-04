import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:roomstyler/features/auth/sign_up_screen.dart';
import 'features/home/home_screen.dart';
import 'features/room_upload/room_upload_screen.dart';
import 'features/catalog/catalog_screen.dart';
import 'features/catalog/furniture_detail_screen.dart'; // Import FurnitureDetailScreen
import 'features/catalog/cart_screen.dart'; // Import CartScreen
import 'features/editor/editor_screen.dart';
import 'features/preview_share/preview_share_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/my_page/my_page_screen.dart'; // Import MyPageScreen
import 'features/my_page/wishlist_screen.dart'; // Import WishlistScreen
import 'features/my_page/theme_settings_screen.dart'; // Import ThemeSettingsScreen
import 'features/my_page/account_settings_screen.dart'; // Import AccountSettingsScreen
import 'features/my_page/edit_profile_screen.dart'; // Import EditProfileScreen
import 'features/my_page/help_feedback_screen.dart'; // Import HelpFeedbackScreen
import 'features/my_page/notification_settings_screen.dart'; // Import NotificationSettingsScreen
import 'features/my_page/my_projects_screen.dart'; // Import MyProjectsScreen

// listenable을 사용해 인증 상태 변경 시 라우터를 자동으로 새로고침
final router = GoRouter(
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/upload', builder: (_, __) => const RoomUploadScreen()),
    GoRoute(path: '/catalog', builder: (_, __) => const CatalogScreen()),
    GoRoute(
      path: '/catalog/:furnitureId',
      builder: (context, state) {
        final furnitureId = state.pathParameters['furnitureId']!;
        return FurnitureDetailScreen(furnitureId: furnitureId);
      },
    ), // Add Furniture Detail route
    GoRoute(path: '/cart', builder: (_, __) => const CartScreen()), // Add Cart route
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
    GoRoute(path: '/mypage', builder: (_, __) => const MyPageScreen()), // Add MyPage route
    GoRoute(path: '/mypage/wishlist', builder: (_, __) => const WishlistScreen()), // Add Wishlist route
    GoRoute(path: '/mypage/theme', builder: (_, __) => const ThemeSettingsScreen()), // Add Theme Settings route
    GoRoute(path: '/mypage/account', builder: (_, __) => const AccountSettingsScreen()), // Add Account Settings route
    GoRoute(path: '/mypage/edit-profile', builder: (_, __) => const EditProfileScreen()), // Add Edit Profile route
    GoRoute(path: '/mypage/help-feedback', builder: (_, __) => const HelpFeedbackScreen()), // Add Help & Feedback route
    GoRoute(path: '/mypage/notifications', builder: (_, __) => const NotificationSettingsScreen()), // Add Notification Settings route
    GoRoute(path: '/mypage/projects', builder: (_, __) => const MyProjectsScreen()), // Add My Projects route
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

