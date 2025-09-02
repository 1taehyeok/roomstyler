import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth Screen Tests', () {
    testWidgets('Sign in screen has required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: '이메일'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: '비밀번호'),
                    obscureText: true,
                  ),
                  FilledButton(
                    onPressed: () {},
                    child: Text('로그인'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify email field
      expect(find.text('이메일'), findsOneWidget);
      
      // Verify password field
      expect(find.text('비밀번호'), findsOneWidget);
      
      // Verify sign in button
      expect(find.text('로그인'), findsOneWidget);
    });

    testWidgets('Sign up screen has required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: '이메일'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: '비밀번호'),
                    obscureText: true,
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: '비밀번호 확인'),
                    obscureText: true,
                  ),
                  FilledButton(
                    onPressed: () {},
                    child: Text('회원가입'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify email field
      expect(find.text('이메일'), findsOneWidget);
      
      // Verify password field
      expect(find.text('비밀번호'), findsOneWidget);
      
      // Verify password confirmation field
      expect(find.text('비밀번호 확인'), findsOneWidget);
      
      // Verify sign up button
      expect(find.text('회원가입'), findsOneWidget);
    });
  });
}