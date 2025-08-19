import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/scene_providers.dart';
import '../../core/models/scene.dart';
import 'package:go_router/go_router.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  // 편집 캔버스의 크기 측정을 위해 GlobalKey 사용
  final _canvasKey = GlobalKey();

  void _addDummyFurniture() {
    ref.read(currentSceneProvider.notifier).addItem(
      SceneLayoutItem(furnitureId: 'chair_01', x: .5, y: .5, scale: 1),
    );
  }

  void _autoLayout() {
    // TODO: VEO3 자동 배치 호출 → state 업데이트
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI 자동 배치(더미): 중앙 정렬 완료')),
    );
    ref.read(currentSceneProvider.notifier).clear();
    _addDummyFurniture();
  }

  @override
  Widget build(BuildContext context) {
    final scene = ref.watch(currentSceneProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('배치 편집기'),
        actions: [
          IconButton(
            tooltip: '자동 배치',
            icon: const Icon(Icons.auto_awesome),
            onPressed: _autoLayout,
          ),
          IconButton(
            tooltip: '미리보기/공유',
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => context.push('/preview'),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chair), label: '가구 추가'),
          NavigationDestination(icon: Icon(Icons.color_lens), label: '스타일'),
          NavigationDestination(icon: Icon(Icons.light_mode), label: '조명'),
          NavigationDestination(icon: Icon(Icons.layers_clear), label: '가구 제거'),
        ],
        onDestinationSelected: (i) {
          if (i == 0) _addDummyFurniture(); // TODO: 카탈로그에서 선택한 품목 연결
          if (i == 3) { // 제거 도구 더미
            if (scene.layout.isNotEmpty) {
              ref.read(currentSceneProvider.notifier).removeItem(scene.layout.length-1);
            }
          }
        },
        selectedIndex: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: AspectRatio(
              aspectRatio: 16/9,
              child: Container(
                key: _canvasKey,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // TODO: 방 배경 이미지 (Room.imageUrl)
                    Positioned.fill(
                      child: Center(
                        child: Text('방 이미지(더미)', style: Theme.of(context).textTheme.bodyLarge),
                      ),
                    ),
                    // 배치된 가구들
                    ...scene.layout.asMap().entries.map((e) {
                      final i = e.key;
                      final item = e.value;
                      return _DraggableFurniture(
                        key: ValueKey('item_$i'),
                        index: i,
                        item: item,
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDummyFurniture,
        icon: const Icon(Icons.add),
        label: const Text('가구 배치'),
      ),
    );
  }
}

class _DraggableFurniture extends ConsumerStatefulWidget {
  final int index;
  final SceneLayoutItem item;
  const _DraggableFurniture({super.key, required this.index, required this.item});

  @override
  ConsumerState<_DraggableFurniture> createState() => _DraggableFurnitureState();
}

class _DraggableFurnitureState extends ConsumerState<_DraggableFurniture> {
  late double _x;
  late double _y;
  late double _scale;
  late double _rotation;

  @override
  void initState() {
    super.initState();
    _x = widget.item.x;
    _y = widget.item.y;
    _scale = widget.item.scale;
    _rotation = widget.item.rotation;
  }

  void _commit() {
    ref.read(currentSceneProvider.notifier).updateItem(
      widget.index,
      SceneLayoutItem(
        furnitureId: widget.item.furnitureId,
        x: _x, y: _y, scale: _scale, rotation: _rotation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final centerX = _x * w;
      final centerY = _y * h;

      return Positioned(
        left: centerX - 50 * _scale,
        top: centerY - 50 * _scale,
        child: GestureDetector(
          onPanUpdate: (d) {
            setState(() {
              _x = (_x + d.delta.dx / w).clamp(0.0, 1.0);
              _y = (_y + d.delta.dy / h).clamp(0.0, 1.0);
            });
          },
          onPanEnd: (_) => _commit(),
          onScaleUpdate: (d) {
            setState(() {
              _scale = (_scale * d.scale).clamp(.3, 3.0);
              _rotation += d.rotation;
            });
          },
          onScaleEnd: (_) => _commit(),
          child: Transform.rotate(
            angle: _rotation,
            child: Container(
              width: 100 * _scale,
              height: 100 * _scale,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.chair, size: 40),
            ),
          ),
        ),
      );
    });
  }
}
