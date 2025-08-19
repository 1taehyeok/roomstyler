import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

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

  Future<void> _pickImage(ImageSource src) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: src, imageQuality: 90);
    if (x != null) setState(() => _image = File(x.path));
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _image != null;
    return Scaffold(
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
          FilledButton.icon(
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('가구 자동 제거 후 계속'),
            onPressed: canContinue ? () {
              // TODO: VEO3 API로 기존 가구 제거/인페인트 → 결과 저장
              context.push('/editor');
            } : null,
          ),
        ],
      ),
    );
  }
}
