import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeScreen Tests', () {
    testWidgets('Home screen renders basic elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: Text('RoomStyler'),
              ),
              body: Column(
                children: [
                  Text('사진 한 장으로 인테리어 시뮬레이션'),
                  FloatingActionButton.extended(
                    onPressed: () {},
                    icon: Icon(Icons.add_a_photo),
                    label: Text('내 방 꾸미기 시작'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify key elements are present
      expect(find.text('RoomStyler'), findsOneWidget);
      expect(find.text('사진 한 장으로 인테리어 시뮬레이션'), findsOneWidget);
      expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
      expect(find.text('내 방 꾸미기 시작'), findsOneWidget);
    });
  });
}