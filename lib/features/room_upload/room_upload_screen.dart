import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
// import 'package:dio/dio.dart'; // 더 이상 필요하지 않습니다.
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // 더 이상 필요하지 않습니다.
import 'package:http/http.dart' as http; // http 패키지 사용
import 'dart:typed_data'; // Uint8List를 위해 필요
import 'package:roomstyler/config.dart'; // Config 임포트
import 'package:roomstyler/services/gemini_api_service.dart'; // GeminiLiveApiService 임포트
import 'new_project_initializer.dart'; // 새로 추가한 파일 임포트

class RoomUploadScreen extends StatefulWidget {
  const RoomUploadScreen({super.key});

  @override
  State<RoomUploadScreen> createState() => _RoomUploadScreenState();
}

class _RoomUploadScreenState extends State<RoomUploadScreen> {
  File? _image;
  final _widthCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  bool _isProcessing = false;

  Future<void> _pickImage(ImageSource src) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: src, imageQuality: 90);
    if (x != null) setState(() => _image = File(x.path));
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _image != null;
    return NewProjectInitializer( // Wrap the Scaffold with NewProjectInitializer
      child: Scaffold(
        appBar: AppBar(title: const Text('방 업로드')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 16/9,
                    child: _image == null
                      ? Center(child: Text('방 사진을 업로드하세요',
                          style: Theme.of(context).textTheme.bodyLarge))
                      : Image.file(_image!, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('갤러리'),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('카메라'),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('방 치수(선택)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(
                  controller: _widthCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '가로 (cm)'),
                )),
                const SizedBox(width: 8),
                Expanded(child: TextField(
                  controller: _lengthCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '세로 (cm)'),
                )),
                const SizedBox(width: 8),
                Expanded(child: TextField(
                  controller: _heightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '높이 (cm)'),
                )),
              ],
            ),
            const SizedBox(height: 24),
            // 버튼들을 세로로 배치
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // 버튼들을 가로로 꽉 채움
              children: [
                // 1. AI 이미지 변형 버튼
                FilledButton.icon(
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: Text(_isProcessing ? '처리 중...' : '이미지 변형(Reimagine) 후 계속'),
                  onPressed: canContinue && !_isProcessing ? _processImage : null,
                ),
                const SizedBox(height: 12), // 버튼 사이 간격
                // 2. 바로 편집기로 이동하는 버튼
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_forward), // 진행 아이콘
                  label: const Text('계속 (AI 없음)'), // 버튼 텍스트
                  onPressed: canContinue && !_isProcessing // 상태 조건 동일
                      ? () {
                          // 선택된 이미지 경로를 그대로 전달
                          if (mounted && _image != null) {
                            context.push('/editor', extra: _image!.path);
                          }
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    print('DEBUG: _processImage started');
    print('DEBUG: Image path: ${_image!.path}');
    // 파일 존재 여부 확인
    final imageFile = File(_image!.path);
    final exists = await imageFile.exists();
    print('DEBUG: Image file exists: $exists');

    if (!exists) {
      print('DEBUG: Image file does not exist at the specified path.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 파일을 찾을 수 없습니다.')),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // --- 기존 ClipDrop Reimagine API 로직 (주석 처리) ---
      /*
      // 1. ClipDrop Reimagine API 정보
      final String clipDropApiKey = Config.clipdropApiKey;
      // final String clipDropApiUrl = 'https://clipdrop-api.co/inpaint/v1'; // 기존 URL
      final String clipDropApiUrl = 'https://clipdrop-api.co/reimagine/v1/reimagine'; // 새 URL

      if (clipDropApiKey.isEmpty) {
        throw Exception('CLIPDROP_API_KEY가 설정되지 않았습니다.');
      }

      // 2. http.MultipartRequest 생성
      final request = http.MultipartRequest('POST', Uri.parse(clipDropApiUrl));
      request.headers['x-api-key'] = clipDropApiKey;
      
      // 3. 원본 이미지 파일 첨부 (필수 파라미터: image_file)
      final imageBytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image_file', imageBytes, filename: 'upload.jpg'));
      
      // 4. 'prompt' 파라미터 제거: Reimagine API는 prompt를 사용하지 않습니다.
      // String prompt = 'Remove all furniture and objects...';
      // request.fields['prompt'] = prompt;
      
      // 5. API 호출
      print('ClipDrop Reimagine API 호출 시작...');
      final response = await request.send();
      print('ClipDrop API 응답 상태 코드: ${response.statusCode}');

      // 6. 응답 처리
      if (response.statusCode == 200) {
        // 성공 시, 응답 바디에 생성된 이미지(JPEG)가 포함됨
        final imageBytes = await response.stream.toBytes();
        
        // 7. 처리된 이미지를 임시 파일로 저장
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/reimagined_image.jpg');
        await tempFile.writeAsBytes(imageBytes);
        final processedImagePath = tempFile.path;
        print('변형된 이미지가 임시 파일에 저장됨: $processedImagePath');

        // 8. 처리된 이미지 경로를 /editor 화면으로 전달
        if (mounted) {
          context.push('/editor', extra: processedImagePath);
        }
      } else {
        // 9. 에러 처리
        final error = await response.stream.bytesToString();
        print('ClipDrop API 에러: ${response.statusCode}, $error');
        throw Exception('API 에러: ${response.statusCode}, $error');
      }
      */
      // --- 기존 ClipDrop Reimagine API 로직 끝 ---

      // --- 새로운 Google Gemini Live 2.5 Flash Preview API 로직 ---
      // 1. Google Generative AI (Gemini) API 정보 (Config에서 가져오기)
      final String geminiApiKey = Config.geminiApiKey;

      if (geminiApiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY가 설정되지 않았습니다.');
      }

      // 2. 이미지 바이트 읽기
      final imageBytes = await imageFile.readAsBytes();

      // 3. Gemini Live API 호출 (서비스 계층으로 위임)
      final processedImageBytes = await GeminiLiveApiService.removeFurnitureWithGeminiLive(
        imageBytes: imageBytes,
        apiKey: geminiApiKey,
      );

      if (processedImageBytes != null) {
        // 4. 처리된 이미지를 임시 파일로 저장
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/gemini_live_furniture_removed.jpg');
        await tempFile.writeAsBytes(processedImageBytes);
        final processedImagePath = tempFile.path;
        print('Gemini Live (가구 제거된) 이미지가 임시 파일에 저장됨: $processedImagePath');

        // 5. 처리된 이미지 경로를 /editor 화면으로 전달
        if (mounted) {
          context.push('/editor', extra: processedImagePath);
        }
      } else {
        // 6. 처리 실패
        throw Exception('Gemini Live API 호출에 실패했습니다. 처리된 이미지를 받지 못했습니다.');
      }
      // --- 새로운 Google Gemini Live 2.5 Flash Preview API 로직 끝 ---

    } catch (e, s) {
      print('이미지 처리 중 에러: $e');
      print('Stack trace: $s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 처리 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}