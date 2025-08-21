import 'dart:io'; // Platform을 위해 추가

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb을 위해 추가
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart'; // google_sign_in 패키지 임포트

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      // 회원가입 성공 시, 홈 화면으로 이동
      if (mounted) context.go('/');

    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'weak-password' => '비밀번호가 너무 약합니다.',
        'email-already-in-use' => '이미 사용 중인 이메일입니다.',
        _ => '알 수 없는 오류가 발생했습니다: ${e.message}',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Google 로그인 기능 (플랫폼별 구현) ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        // 웹: Firebase의 signInWithPopup 사용
        userCredential = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Android/iOS: google_sign_in 패키지 사용
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          // 사용자가 로그인을 취소함
          return;
        }
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      } else {
        // 데스크탑 또는 기타: 현재 지원되지 않음 또는 다른 방식으로 처리
        // 또는 google_sign_in_dartio를 다시 시도해볼 수 있습니다.
        // 여기서는 간단히 오류 표시
        throw UnimplementedError('이 플랫폼에서는 Google 로그인이 지원되지 않습니다.');
      }

      // 로그인 성공 처리
      final User? user = userCredential.user;
      if (user != null) {
        print("Google 로그인 성공: ${user.displayName}");
        if (mounted) {
          context.go('/'); // 홈 화면으로 이동
        }
      } else {
        throw Exception("Firebase 로그인 후 사용자 정보를 가져올 수 없습니다.");
      }

    } on FirebaseAuthException catch (e) {
      // Firebase Authentication 관련 오류 처리
      String message = 'Google 로그인에 실패했습니다.';
      if (e.code == 'account-exists-with-different-credential') {
        message = '이 이메일은 이미 다른 방법으로 가입되어 있습니다.';
      } else if (e.code == 'invalid-credential') {
        message = '잘못된 인증 정보입니다.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Google 로그인이 활성화되지 않았습니다. Firebase Console에서 확인해주세요.';
      }
      // 다른 FirebaseAuthException 코드에 대한 처리 추가 가능
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      // 기타 예외 처리
      print("Google 로그인 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google 로그인에 실패했습니다: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: '이메일'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v?.isEmpty ?? true) ? '이메일을 입력하세요.' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                validator: (v) => (v?.isEmpty ?? true) ? '비밀번호를 입력하세요.' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordConfirmCtrl,
                decoration: const InputDecoration(labelText: '비밀번호 확인'),
                obscureText: true,
                validator: (v) {
                  if (v?.isEmpty ?? true) return '비밀번호를 다시 입력하세요.';
                  if (v != _passwordCtrl.text) return '비밀번호가 일치하지 않습니다.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                FilledButton(
                  onPressed: _signUp,
                  child: const Text('가입하기'),
                ),
              const SizedBox(height: 16),
              // Google 로그인 버튼 추가
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle, // 로딩 중에는 버튼 비활성화
                icon: const Icon(Icons.login),
                label: const Text('Google로 계속'),
              )
            ],
          ),
        ),
      ),
    );
  }
}