import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: '이메일')),
            const SizedBox(height: 8),
            const TextField(decoration: InputDecoration(labelText: '비밀번호'), obscureText: true),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('로그인'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {}, // TODO: Firebase Auth 소셜 로그인
              icon: const Icon(Icons.login),
              label: const Text('Google로 계속'),
            )
          ],
        ),
      ),
    );
  }
}
