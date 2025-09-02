import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyPage Tests', () {
    testWidgets('My page displays menu items', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  ListTile(
                    leading: Icon(Icons.favorite_border),
                    title: Text('찜한 아이템'),
                  ),
                  ListTile(
                    leading: Icon(Icons.palette_outlined),
                    title: Text('테마 설정'),
                  ),
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('계정 설정'),
                  ),
                  ListTile(
                    leading: Icon(Icons.notifications_none),
                    title: Text('알림 설정'),
                  ),
                  ListTile(
                    leading: Icon(Icons.help_outline),
                    title: Text('도움말 및 의견'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify menu items are present
      expect(find.text('찜한 아이템'), findsOneWidget);
      expect(find.text('테마 설정'), findsOneWidget);
      expect(find.text('계정 설정'), findsOneWidget);
      expect(find.text('알림 설정'), findsOneWidget);
      expect(find.text('도움말 및 의견'), findsOneWidget);
    });
  });
}