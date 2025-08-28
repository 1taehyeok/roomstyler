import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerWidget을 사용하기 위해 필요
import 'package:go_router/go_router.dart';
import 'package:roomstyler/core/models/scene.dart';
import 'package:roomstyler/state/scene_providers.dart';
import 'package:roomstyler/state/scene_history_provider.dart'; // SceneHistoryProvider 임포트
import 'package:roomstyler/services/scene_service.dart'; // SceneService 임포트
import 'package:roomstyler/services/ai_service.dart'; // AiService 임포트
import 'dart:io';
import 'dart:typed_data'; // Uint8List를 위해 필요
import '_editor_canvas.dart'; // EditorCanvas 위젯 임포트
import '_wishlist_panel.dart'; // WishlistPanel 위젯 임포트
import 'editor_constants.dart'; // Import the constants

class EditorScreen extends ConsumerStatefulWidget {
  final String? imagePath; // 초기 배경 이미지 경로 (업로드 후 편집기 진입 시 사용)
  const EditorScreen({super.key, this.imagePath});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  bool _isSaving = false;
  bool _isAutoArranging = false; // AI 자동 배치 진행 상태

  // --- 찜 목록 패널 상태 ---
  bool _isWishlistPanelOpen = false;
  void _toggleWishlistPanel() {
    setState(() {
      _isWishlistPanelOpen = !_isWishlistPanelOpen;
    });
  }

  Future<void> _saveScene() async {
    setState(() => _isSaving = true);
    try {
      final scene = ref.read(currentSceneProvider);
      final sceneService = SceneService();

      final Scene savedScene = await sceneService.saveScene(scene, imagePath: widget.imagePath);

      // Provider 상태 업데이트
      ref.read(currentSceneProvider.notifier).setScene(savedScene);
      // 저장 성공 후 Undo/Redo 히스토리 클리어
      ref.read(sceneHistoryProvider.notifier).clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('성공적으로 저장되었습니다!')),
      );
      // 저장 성공 후 홈 화면으로 이동
      if (mounted) {
        context.go('/'); // go_router를 사용하여 홈으로 이동
      }
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
      // 저장된 프로젝트에서 불러온 경우, widget.imagePath는 null일 수 있으므로 scene.roomId를 사용.
      final String? imagePath = widget.imagePath ?? scene.roomId;
      if (imagePath == null) {
        throw Exception('배경 이미지 경로가 없습니다.');
      }
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('배경 이미지 파일을 찾을 수 없습니다.');
      }
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // 2. AiService 호출
      final arrangedItems = await AiService.autoArrange(imageBytes, scene);

      // 3. 응답 처리
      if (arrangedItems != null) {
        // 씬의 레이아웃을 새롭게 배치된 아이템들로 교체
        ref.read(currentSceneProvider.notifier).updateLayout(arrangedItems);

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

    // 배경 이미지 경로 결정: widget.imagePath(초기 진입 시) 또는 scene.roomId(저장된 프로젝트 로드 시)
    final String? backgroundImage = widget.imagePath ?? scene.roomId;

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
          // 결과 미리보기/공유 버튼
          IconButton(
            icon: const Icon(Icons.preview), // 적절한 아이콘 선택
            onPressed: () => context.push('/preview'), // /preview 경로로 이동
            tooltip: '결과 미리보기/공유',
          ),
          // --- Undo, Redo, 찜 목록 버튼은 하단으로 이동 ---
        ],
      ),
      // --- body를 Stack으로 감싸고, 기존 내용과 패널을 children에 넣습니다 ---
      body: Stack(
        children: [
          // --- 기존 캔버스 내용을 _EditorCanvas 위젯으로 교체 ---
          Positioned.fill(
            child: EditorCanvas(
              backgroundImage: backgroundImage,
              onBackgroundTap: () {}, // EditorCanvas handles its own deselection
            ),
          ),
          // --- 찜 목록 슬라이드 패널 추가 ---
          // Positioned를 사용하여 하단 버튼 위에 패널을 배치
          Positioned(
            left: 0,
            right: 0,
            bottom: EditorConstants.wishlistPanelBottomOffset, // 하단 버튼 행 높이만큼 위에 배치
            child: WishlistPanel(
              isOpen: _isWishlistPanelOpen,
              onToggle: _toggleWishlistPanel,
              onClose: _toggleWishlistPanel, // 닫기 버튼도 토글로 처리
            ),
          ),
          // --- 슬라이드 패널 끝 ---
          // --- 하단 버튼 행 추가 ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: EditorConstants.bottomButtonBarHeight, // 버튼 행 높이
              color: Theme.of(context).cardColor, // 배경색
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 버튼들을 균등 간격으로 배치
                children: [
                  // Undo 버튼
                  Consumer(
                    builder: (context, ref, child) {
                      final canUndo = ref.watch(sceneHistoryProvider.notifier).canUndo;
                      return IconButton(
                        icon: const Icon(Icons.undo),
                        onPressed: canUndo
                            ? () {
                                final previousState = ref.read(sceneHistoryProvider.notifier).undo();
                                if (previousState != null) {
                                  ref.read(currentSceneProvider.notifier).restoreState(previousState);
                                }
                              }
                            : null, // canUndo가 false이면 버튼 비활성화
                        tooltip: '실행 취소',
                      );
                    },
                  ),
                  // Redo 버튼
                  Consumer(
                    builder: (context, ref, child) {
                      final canRedo = ref.watch(sceneHistoryProvider.notifier).canRedo;
                      return IconButton(
                        icon: const Icon(Icons.redo),
                        onPressed: canRedo
                            ? () {
                                final nextState = ref.read(sceneHistoryProvider.notifier).redo();
                                if (nextState != null) {
                                  ref.read(currentSceneProvider.notifier).restoreState(nextState);
                                }
                              }
                            : null, // canRedo가 false이면 버튼 비활성화
                        tooltip: '다시 실행',
                      );
                    },
                  ),
                  // 찜 목록 토글 버튼
                  IconButton(
                    icon: const Icon(Icons.favorite),
                    onPressed: _toggleWishlistPanel,
                    tooltip: '찜 목록',
                  ),
                ],
              ),
            ),
          ),
          // --- 하단 버튼 행 끝 ---
        ],
      ),
      // --- body 끝 ---
    );
  }

  
}

