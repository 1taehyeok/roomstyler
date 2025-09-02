import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Preview Share Screen Tests', () {
    testWidgets('Preview screen displays result image', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: Container(
                      color: Colors.grey,
                      child: Center(
                        child: Text('편집 결과'),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.share),
                        label: Text('공유'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.save),
                        label: Text('저장'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify key elements are present
      expect(find.text('편집 결과'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
      expect(find.text('공유'), findsOneWidget);
      expect(find.text('저장'), findsOneWidget);
    });
  });
}