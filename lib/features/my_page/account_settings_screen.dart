// lib/features/my_page/account_settings_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  
  bool _isChanging = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isChanging = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다.');
      
      // Check if the user signed in with Google
      final isGoogleSignIn = user.providerData.any(
        (userInfo) => userInfo.providerId == 'google.com'
      );
      
      if (isGoogleSignIn) {
        throw Exception('구글 계정으로 로그인한 경우 비밀번호를 변경할 수 없습니다.');
      }
      
      // For email/password users, update the password
      await user.updatePassword(_newPasswordController.text);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')),
        );
        context.pop(); // Close the screen
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = '새 비밀번호가 너무 약합니다. 더 복잡한 비밀번호를 사용해주세요.';
      } else {
        message = '비밀번호 변경 중 오류가 발생했습니다: ${e.message}';
      }
      
      if (mounted) {
        setState(() {
          _errorMessage = message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '비밀번호 변경 중 오류가 발생했습니다: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChanging = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGoogleSignIn = user?.providerData.any(
      (userInfo) => userInfo.providerId == 'google.com'
    ) ?? false;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('계정 설정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '계정 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('이메일'),
              subtitle: Text(user?.email ?? '이메일 정보 없음'),
            ),
            const Divider(),
            const Text(
              '보안 설정',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Password change section
            if (!isGoogleSignIn) ...[
              const Text('비밀번호 변경'),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: const InputDecoration(
                        labelText: '새 비밀번호',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '새 비밀번호를 입력해주세요.';
                        }
                        if (value.length < 6) {
                          return '비밀번호는 최소 6자 이상이어야 합니다.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmNewPasswordController,
                      decoration: const InputDecoration(
                        labelText: '새 비밀번호 확인',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '새 비밀번호를 다시 입력해주세요.';
                        }
                        if (value != _newPasswordController.text) {
                          return '새 비밀번호가 일치하지 않습니다.';
                        }
                        return null;
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isChanging ? null : _changePassword,
                        child: _isChanging
                            ? const CircularProgressIndicator()
                            : const Text('비밀번호 변경'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text('비밀번호 변경'),
              const SizedBox(height: 16),
              const Text(
                '구글 계정으로 로그인하셨기 때문에 비밀번호를 변경할 수 없습니다.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 32),
            // Payment methods section (placeholder)
            const Text(
              '결제 수단',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '결제 수단 관리 기능은 추후 업데이트 예정입니다.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}