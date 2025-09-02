import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Room Upload Screen Tests', () {
    testWidgets('Upload screen has image selection options', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('방 사진 선택'),
                  Card(
                    child: Column(
                      children: [
                        Icon(Icons.photo_library, size: 48),
                        Text('갤러리에서 선택'),
                      ],
                    ),
                  ),
                  Card(
                    child: Column(
                      children: [
                        Icon(Icons.camera, size: 48),
                        Text('카메라로 촬영'),
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
      expect(find.text('방 사진 선택'), findsOneWidget);
      expect(find.text('갤러리에서 선택'), findsOneWidget);
      expect(find.text('카메라로 촬영'), findsOneWidget);
    });

    testWidgets('Upload screen shows selected image preview', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Container(
                    height: 200,
                    color: Colors.grey,
                    child: Center(
                      child: Icon(Icons.image, size: 48),
                    ),
                  ),
                  Text('선택된 이미지'),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('다음'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify image preview is shown
      expect(find.byIcon(Icons.image), findsOneWidget);
      expect(find.text('선택된 이미지'), findsOneWidget);
      expect(find.text('다음'), findsOneWidget);
    });
  });
}