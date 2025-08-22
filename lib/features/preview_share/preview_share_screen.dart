import 'dart:io';
import 'dart:ui' as ui; // Picture와 ImageByteFormat을 위해 필요

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // RenderRepaintBoundary를 위해 필요
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:roomstyler/state/scene_providers.dart';

class PreviewShareScreen extends ConsumerStatefulWidget {
  const PreviewShareScreen({super.key});

  @override
  ConsumerState<PreviewShareScreen> createState() => _PreviewShareScreenState();
}

class _PreviewShareScreenState extends ConsumerState<PreviewShareScreen> {
  final GlobalKey _previewContainerKey = GlobalKey(); // 미리보기 영역을 캡처하기 위한 GlobalKey
  bool _isCapturing = false; // 캡처 진행 상태

  // --- 캡처 및 공유 기능 ---
  Future<void> _captureAndShare() async {
    setState(() {
      _isCapturing = true;
    });

    try {
      // 1. GlobalKey를 사용하여 RenderRepaintBoundary를 가져옵니다.
      final boundary = _previewContainerKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception("캡처할 영역을 찾을 수 없습니다.");
      }

      // 2. 위젯을 이미지로 렌더링합니다. (픽셀 밀도 1.0으로 고정)
      final image = await boundary.toImage(pixelRatio: 1.0);
      
      // 3. ui.Image를 PNG 바이트 데이터로 변환합니다.
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception("이미지를 바이트 데이터로 변환할 수 없습니다.");
      }
      
      // 4. Uint8List로 변환합니다.
      final pngBytes = byteData.buffer.asUint8List();

      // 5. 임시 파일로 저장합니다. (공유를 위해 필요)
      final tempDir = Directory.systemTemp;
      final file = await File('${tempDir.path}/roomstyler_preview.png').create();
      await file.writeAsBytes(pngBytes);

      // 6. share_plus를 사용하여 공유합니다.
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '내 인테리어 결과물! 확인해보세요.',
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공유 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 편집 중인 씬 상태 가져오기
    final scene = ref.watch(currentSceneProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('결과물 미리보기/공유'),
        actions: [
          if (_isCapturing)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator())),
            )
          else
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _captureAndShare,
              tooltip: '결과물 공유하기',
            ),
        ],
      ),
      body: RepaintBoundary(
        key: _previewContainerKey, // 캡처할 영역을 지정
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  // Scene의 outputUrl이 있으면 그것을 표시, 없으면 샘플 텍스트
                  // 실제 구현에서는 편집기의 캔버스를 표시하거나, 서버에서 렌더링된 이미지를 표시해야 합니다.
                  // 여기서는 편의상 샘플 텍스트를 표시합니다.
                  child: const Center(
                      child: Text(
                    '편집기 캔버스 또는 렌더링된 이미지가 여기에 표시됩니다.',
                    textAlign: TextAlign.center,
                  )),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // A/B 비교 기능은 간단한 구현 예시입니다.
            // 실제 구현에서는 두 개의 다른 outputUrl을 비교해야 합니다.
            // 여기서는 단순히 토글만 구현합니다.
            _ABComparisonWidget(scene: scene),
            const SizedBox(height: 12),
            // 공유 버튼 (앱바에 중복되어 있지만, 리스트 내부에도 배치할 수 있음)
            /*
            FilledButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('공유하기'),
              onPressed: _captureAndShare,
            ),
            */
          ],
        ),
      ),
    );
  }
}

// 간단한 A/B 비교 위젯 (샘플 구현)
class _ABComparisonWidget extends ConsumerStatefulWidget {
  final dynamic scene; // Scene 타입을 정확히 지정하려면 import 필요

  const _ABComparisonWidget({required this.scene});

  @override
  ConsumerState<_ABComparisonWidget> createState() =>
      _ABComparisonWidgetState();
}

class _ABComparisonWidgetState extends ConsumerState<_ABComparisonWidget> {
  // 간단한 A/B 선택 상태 관리
  Set<int> _selected = const {0};

  @override
  Widget build(BuildContext context) {
    // 실제 A/B 비교를 위해서는 scene 객체에 두 개의 outputUrl이 필요합니다.
    // 여기서는 단순히 UI 토글만 구현합니다.
    // 예: scene.outputUrlA, scene.outputUrlB

    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('A')),
        ButtonSegment(value: 1, label: Text('B')),
      ],
      selected: _selected,
      onSelectionChanged: (Set<int> newSelection) {
        setState(() {
          _selected = newSelection;
        });
        // TODO: newSelection에 따라 표시되는 이미지를 변경하는 로직 추가
        // 예: if (newSelection.contains(0)) { 표시할 이미지 = widget.scene.outputUrlA } else { ... }
      },
    );
  }
}