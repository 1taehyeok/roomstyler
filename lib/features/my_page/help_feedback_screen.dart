// lib/features/my_page/help_feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> {
  final _feedbackFormKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  
  bool _isSubmitting = false;
  String? _feedbackMessage;
  
  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
  
  Future<void> _submitFeedback() async {
    if (!_feedbackFormKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
      _feedbackMessage = null;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다.');
      
      // Firestore에 피드백 저장
      // 컬렉션 구조: feedback/{auto-generated-id}
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': user.uid,
        'email': user.email, // 사용자 이메일도 저장 (선택사항)
        'feedback': _feedbackController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        setState(() {
          _feedbackMessage = '피드백이 성공적으로 제출되었습니다. 감사합니다!';
          _feedbackController.clear(); // 입력 필드 초기화
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _feedbackMessage = '피드백 제출 중 오류가 발생했습니다: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('도움말 및 피드백'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 도움말 섹션
            const Text(
              '자주 묻는 질문 (FAQ)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              question: '앱을 어떻게 사용하나요?',
              answer: '1. \'내 방 꾸미기 시작\' 버튼을 눌러 방 사진을 업로드합니다.\n'
                  '2. \'가구\' 탭에서 원하는 가구를 선택합니다.\n'
                  '3. 편집기에서 가구를 배치하고 조정합니다.\n'
                  '4. \'결과 미리보기/공유\' 버튼으로 결과를 확인하고 저장합니다.',
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              question: 'AI 자동 배치 기능은 무엇인가요?',
              answer: 'AI 자동 배치 기능은 업로드한 방 사진을 분석하여 '
                  '적절한 위치에 가구를 자동으로 배치해주는 기능입니다. '
                  '툴바의 \'AI 자동 배치\' 버튼을 눌러 사용할 수 있습니다.',
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              question: '찜한 가구는 어디에서 확인할 수 있나요?',
              answer: '마이 페이지의 \'찜 목록\' 섹션에서 확인할 수 있습니다. '
                  '또한 편집기 화면 하단의 \'찜 목록\' 버튼을 눌러서도 확인이 가능합니다.',
            ),
            const SizedBox(height: 32),
            // 피드백 섹션
            const Text(
              '의견 보내기',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '앱 사용 중 불편한 점이나 개선 제안이 있으시면 아래에 작성해주세요. '
              '소중한 의견은 앱 개선에 큰 도움이 됩니다.',
            ),
            const SizedBox(height: 16),
            Form(
              key: _feedbackFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _feedbackController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: '의견을 입력해주세요...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '의견을 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                  if (_feedbackMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _feedbackMessage!,
                      style: TextStyle(
                        color: _feedbackMessage!.contains('성공') 
                            ? Colors.green 
                            : Colors.red,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitFeedback,
                      child: _isSubmitting
                          ? const CircularProgressIndicator()
                          : const Text('의견 제출'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // FAQ 항목을 빌드하는 위젯
  Widget _buildFAQItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer),
        ),
      ],
    );
  }
}