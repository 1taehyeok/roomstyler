import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('Router Tests', () {
    testWidgets('Router can navigate to home screen', (WidgetTester tester) async {
      // Create a simple test app with GoRouter
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Text('Home Screen'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('Router handles unknown routes', (WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Text('Home Screen'),
            ),
          ),
        ],
        errorBuilder: (context, state) => Scaffold(
          body: Text('Error Page'),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Navigate to unknown route
      router.go('/unknown');

      await tester.pumpAndSettle();

      expect(find.text('Error Page'), findsOneWidget);
    });
  });
}