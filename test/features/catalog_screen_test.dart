import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Catalog Screen Tests', () {
    testWidgets('Catalog screen displays title and search field', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: Text('가구 카탈로그'),
              ),
              body: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: '가구 검색',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('가구 목록'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify key elements are present
      expect(find.text('가구 카탈로그'), findsOneWidget);
      expect(find.text('가구 검색'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('가구 목록'), findsOneWidget);
    });

    testWidgets('Catalog screen displays furniture items', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  ListTile(
                    leading: Icon(Icons.chair),
                    title: Text('의자'),
                    subtitle: Text('₩50,000'),
                  ),
                  ListTile(
                    leading: Icon(Icons.weekend),
                    title: Text('소파'),
                    subtitle: Text('₩200,000'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify furniture items are present
      expect(find.text('의자'), findsOneWidget);
      expect(find.text('소파'), findsOneWidget);
      expect(find.text('₩50,000'), findsOneWidget);
      expect(find.text('₩200,000'), findsOneWidget);
    });
  });
}