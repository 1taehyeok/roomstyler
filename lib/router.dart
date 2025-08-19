import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/home/home_screen.dart';
import 'features/room_upload/room_upload_screen.dart';
import 'features/catalog/catalog_screen.dart';
import 'features/editor/editor_screen.dart';
import 'features/preview_share/preview_share_screen.dart';
import 'features/auth/sign_in_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/upload', builder: (_, __) => const RoomUploadScreen()),
    GoRoute(path: '/catalog', builder: (_, __) => const CatalogScreen()),
    GoRoute(path: '/editor', builder: (_, __) => const EditorScreen()),
    GoRoute(path: '/preview', builder: (_, __) => const PreviewShareScreen()),
    GoRoute(path: '/signin', builder: (_, __) => const SignInScreen()),
  ],
);
