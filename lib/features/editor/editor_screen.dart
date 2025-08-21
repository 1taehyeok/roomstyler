import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roomstyler/core/models/scene.dart';
import 'package:roomstyler/state/scene_providers.dart';
import 'package:uuid/uuid.dart';
// import 'package:dio/dio.dart'; // 더 이상 필요하지 않습니다.
import 'dart:io';
import 'dart:typed_data'; // Uint8List를 위해 필요
import 'package:roomstyler/services/gemini_api_service.dart'; // 새로 만든 서비스 임포트

class EditorScreen extends ConsumerStatefulWidget {
  final String? imagePath;
  const EditorScreen({super.key, this.imagePath});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  int? _selectedItemIndex;
  bool _isSaving = false;
  bool _isAutoArranging = false; // AI 자동 배치 진행 상태

  // --- 제스처 상태 저장을 위한 변수 ---
  // 아이템의 초기 상태
  var _itemInitialState = SceneLayoutItem(furnitureId: '', name: '', x: 0, y: 0);
  // 제스처 시작 시 손가락의 절대 위치
  Offset _gestureStartPoint = Offset.zero;

  Future<void> _saveScene() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

      final scene = ref.read(currentSceneProvider);
      final sceneId = scene.id == 'temp' ? const Uuid().v4() : scene.id;

      final sceneToSave = scene.copyWith(
        id: sceneId,
        userId: user.uid,
      );

      await FirebaseFirestore.instance
          .collection('scenes')
          .doc(sceneToSave.id)
          .set(sceneToSave.toJson());

      ref.read(currentSceneProvider.notifier).state = sceneToSave;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('성공적으로 저장되었습니다!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // --- AI 자동 배치 기능 (Gemini API 사용) ---
  Future<void> _autoArrange() async {
    setState(() => _isAutoArranging = true);
    try {
      final scene = ref.read(currentSceneProvider);

      // 1. 배경 이미지 파일을 Uint8List로 읽기
      if (widget.imagePath == null) {
        throw Exception('배경 이미지 경로가 없습니다.');
      }
      final imageFile = File(widget.imagePath!);
      if (!await imageFile.exists()) {
        throw Exception('배경 이미지 파일을 찾을 수 없습니다.');
      }
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // 2. GeminiApiService 호출
      final arrangedItems = await GeminiApiService.getFurniturePlacement(
        imageBytes: imageBytes,
        scene: scene,
      );

      // 3. 응답 처리
      if (arrangedItems != null) {
        // 씬의 레이아웃을 새롭게 배치된 아이템들로 교체
        ref.read(currentSceneProvider.notifier).state = scene.copyWith(layout: arrangedItems);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI 자동 배치가 완료되었습니다!')),
          );
        }
      } else {
        throw Exception('AI로부터 배치 결과를 받지 못했습니다.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI 자동 배치 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAutoArranging = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = ref.watch(currentSceneProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('방 꾸미기'),
        actions: [
          // 저장 버튼
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator())),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveScene,
            ),
          // AI 자동 배치 버튼
          if (_isAutoArranging)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator())),
            )
          else
            IconButton(
              icon: const Icon(Icons.auto_fix_high), // 적절한 아이콘 선택
              onPressed: _autoArrange, // _autoArrange 메소드 연결
              tooltip: 'AI 자동 배치',
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => setState(() => _selectedItemIndex = null),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasWidth = constraints.maxWidth;
            final canvasHeight = constraints.maxHeight;

            return Stack(
              children: [
                widget.imagePath != null
                    ? Image.file(
                        File(widget.imagePath!),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                      )
                    : Container(
                        color: Colors.grey[200],
                        width: double.infinity,
                        height: double.infinity,
                        child: const Center(child: Text('여기에 방 배경이 표시됩니다.')),
                      ),
                ...scene.layout.asMap().entries.map((entry) {
                  int index = entry.key;
                  SceneLayoutItem item = entry.value;
                  bool isSelected = _selectedItemIndex == index;
                  const itemBaseSize = 100.0;

                  return Positioned(
                    left: item.x * canvasWidth - (itemBaseSize * item.scale / 2),
                    top: item.y * canvasHeight - (itemBaseSize * item.scale / 2),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedItemIndex = index),
                      onScaleStart: (details) {
                        _itemInitialState = item; // 아이템의 전체 초기 상태 저장
                        _gestureStartPoint = details.focalPoint; // 제스처 시작점의 절대 좌표 저장
                      },
                      onScaleUpdate: (details) {
                        // 현재 손가락 위치와 시작점의 차이를 계산
                        final gestureDelta = details.focalPoint - _gestureStartPoint;

                        // 이동 거리 계산 (절대->상대 좌표 변환)
                        final newX = _itemInitialState.x + (gestureDelta.dx / canvasWidth);
                        final newY = _itemInitialState.y + (gestureDelta.dy / canvasHeight);

                        // 크기 및 회전 계산
                        final newScale = _itemInitialState.scale * details.scale;
                        final newRotation = _itemInitialState.rotation + details.rotation;

                        _updateItem(index, item.copyWith(
                          x: newX,
                          y: newY,
                          scale: newScale,
                          rotation: newRotation,
                        ));
                      },
                      child: _FurnitureItemView(
                        item: item,
                        isSelected: isSelected,
                        baseSize: itemBaseSize,
                        onDelete: () {
                          ref.read(currentSceneProvider.notifier).removeItem(index);
                          setState(() => _selectedItemIndex = null);
                        },
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  void _updateItem(int index, SceneLayoutItem newItem) {
    ref.read(currentSceneProvider.notifier).updateItem(index, newItem);
  }
}

class _FurnitureItemView extends StatelessWidget {
  final SceneLayoutItem item;
  final bool isSelected;
  final double baseSize;
  final VoidCallback onDelete;

  const _FurnitureItemView({
    required this.item,
    required this.isSelected,
    required this.baseSize,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final itemSize = baseSize * item.scale;

    return Transform.rotate(
      angle: item.rotation,
      child: Stack(
        children: [
          Container(
            width: itemSize,
            height: itemSize,
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                  )
                : null,
            child: CachedNetworkImage(
              imageUrl: item.imageUrl ?? '',
              placeholder: (context, url) => Container(
                color: Colors.blue.withOpacity(0.5),
                child: Center(child: Text(item.name, textAlign: TextAlign.center)),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.red.withOpacity(0.5),
                child: Center(child: Text(item.name, textAlign: TextAlign.center)),
              ),
              fit: BoxFit.contain,
            ),
          ),
          if (isSelected)
            Positioned(
              top: 0,
              left: 0,
              child: GestureDetector(
                onTap: onDelete,
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

