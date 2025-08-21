import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:roomstyler/state/scene_providers.dart';

class PreviewShareScreen extends ConsumerWidget {
  const PreviewShareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 현재 편집 중인 씬 상태 가져오기
    final scene = ref.watch(currentSceneProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('결과물 미리보기/공유')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: AspectRatio(
              aspectRatio: 16/9,
              child: Container(
                color: Theme.of(context).colorScheme.surfaceVariant,
                // Scene의 outputUrl이 있으면 그것을 표시, 없으면 샘플 텍스트
                child: scene.outputUrl != null && scene.outputUrl!.isNotEmpty
                    ? Image.network(scene.outputUrl!, fit: BoxFit.cover)
                    : const Center(child: Text('최종 렌더(샘플 또는 처리 중)')),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // A/B 비교 기능은 간단한 구현 예시입니다.
          // 실제 구현에서는 두 개의 다른 outputUrl을 비교해야 합니다.
          // 여기서는 단순히 토글만 구현합니다.
          _ABComparisonWidget(scene: scene),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('공유하기'),
            // 공유할 때 씬 ID나 URL을 포함할 수 있습니다.
            onPressed: () => Share.share(
                '내 인테리어 결과물! 확인해보세요: https://roomstyler.example.com/scene/${scene.id}'),
          ),
        ],
      ),
    );
  }
}

// 간단한 A/B 비교 위젯 (샘플 구현)
class _ABComparisonWidget extends ConsumerStatefulWidget {
  final dynamic scene; // Scene 타입을 정확히 지정하려면 import 필요

  const _ABComparisonWidget({required this.scene});

  @override
  ConsumerState<_ABComparisonWidget> createState() => _ABComparisonWidgetState();
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
