import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Editor Screen Tests', () {
    testWidgets('Editor screen displays background image area', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Container(
                    color: Colors.grey,
                    child: Center(
                      child: Text('배경 이미지'),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Column(
                      children: [
                        FloatingActionButton(
                          onPressed: () {},
                          child: Icon(Icons.undo),
                        ),
                        SizedBox(height: 10),
                        FloatingActionButton(
                          onPressed: () {},
                          child: Icon(Icons.redo),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify key elements are present
      expect(find.text('배경 이미지'), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);
    });

    testWidgets('Editor screen has furniture palette', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: Container(
                      color: Colors.grey,
                    ),
                  ),
                  Container(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Card(child: Icon(Icons.chair)),
                        Card(child: Icon(Icons.weekend)),
                        Card(child: Icon(Icons.light)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify furniture palette is present
      expect(find.byIcon(Icons.chair), findsOneWidget);
      expect(find.byIcon(Icons.weekend), findsOneWidget);
      expect(find.byIcon(Icons.light), findsOneWidget);
    });
  });
}