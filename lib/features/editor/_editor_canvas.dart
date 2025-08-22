// lib/features/editor/_editor_canvas.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart'; // CachedNetworkImage 임포트 추가
import 'package:roomstyler/core/models/scene.dart';
import 'package:roomstyler/state/scene_providers.dart';
import 'dart:io';
import 'dart:async'; // Timer를 사용하기 위해 필요
import 'dart:math'; // sqrt를 사용하기 위해 필요
import '_furniture_item_view.dart'; // 가구 아이템 표시 위젯 임포트

/// 편집기의 주요 캔버스를 표시하는 위젯입니다.
/// 배경 이미지와 가구 아이템들을 표시하고, 사용자의 터치 이벤트를 처리합니다.
class EditorCanvas extends ConsumerStatefulWidget {
  final String? backgroundImage; // 배경 이미지 경로
  final VoidCallback onBackgroundTap; // 배경을 탭했을 때 호출되는 콜백

  const EditorCanvas({
    super.key,
    required this.backgroundImage,
    required this.onBackgroundTap,
  });

  @override
  ConsumerState<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends ConsumerState<EditorCanvas> {
  int? _selectedItemIndex;
  // --- 제스처 상태 저장을 위한 변수 ---
  // 아이템의 초기 상태
  var _itemInitialState = SceneLayoutItem(furnitureId: '', name: '', x: 0, y: 0);
  // 제스처 시작 시 손가락의 절대 위치
  Offset _gestureStartPoint = Offset.zero;

  // --- Undo/Redo 디바운싱을 위한 Timer ---
  Timer? _updateDebounceTimer;
  // 디바운스 지연 시간 (밀리초)
  static const int _debounceDurationMs = 500;

  void _updateItem(int index, SceneLayoutItem newItem) {
    ref.read(currentSceneProvider.notifier).updateItem(index, newItem);
  }

  @override
  void dispose() {
    // 위젯이 dispose될 때 Timer도 취소
    _updateDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = ref.watch(currentSceneProvider);

    return GestureDetector(
      onTap: widget.onBackgroundTap, // 배경 탭 시 콜백 호출
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canvasWidth = constraints.maxWidth;
          final canvasHeight = constraints.maxHeight;

          return DragTarget<Map<String, dynamic>>(
            builder: (context, candidateData, rejectedData) {
              // 드래그 중인 아이템이 캔버스 위에 있는지 판단
              final isDragOverCanvas = candidateData.isNotEmpty;
              return Stack(
                children: [
                  // 배경 이미지
                  widget.backgroundImage != null
                      ? Image.file(
                          File(widget.backgroundImage!),
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
                  // 드래그 중일 때 캔버스 상단에 휴지통 아이콘 표시
                  if (isDragOverCanvas)
                    const Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Icon(
                          Icons.delete,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  // 가구 아이템들
                  ...scene.layout.asMap().entries.map((entry) {
                    int index = entry.key;
                    SceneLayoutItem item = entry.value;
                    bool isSelected = _selectedItemIndex == index;
                    const itemBaseSize = 100.0;

                    return Positioned(
                      left: item.x * canvasWidth - (itemBaseSize * item.scale / 2),
                      top: item.y * canvasHeight - (itemBaseSize * item.scale / 2),
                      child: Draggable<Map<String, dynamic>>(
                        data: {'item': item, 'index': index}, // 드래그 데이터 (가구와 인덱스)
                        feedback: Transform.rotate(
                          angle: item.rotation,
                          child: Container(
                            width: itemBaseSize * item.scale * 0.8, // 피드백 크기 축소
                            height: itemBaseSize * item.scale * 0.8,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue, width: 2),
                            ),
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
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5, // 드래그 중 원래 위치는 반투명
                          child: FurnitureItemView(
                            item: item,
                            isSelected: isSelected,
                            baseSize: itemBaseSize,
                            onDelete: () {
                              ref.read(currentSceneProvider.notifier).removeItem(index);
                              setState(() => _selectedItemIndex = null);
                            },
                          ),
                        ),
                        child: FurnitureItemView(
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
            onAcceptWithDetails: (details) {
              // --- 드롭 좌표 검증 로직 ---
              // 1. 드롭된 위치의 Offset 가져오기
              final Offset dropOffset = details.offset;
              
              // 2. 휴지통 아이콘의 중앙 좌표 계산 (대략적으로)
              // 아이콘이 Positioned(top: 20)이고, Align(topCenter)이므로,
              // 아이콘의 중앙 x좌표는 캔버스 너비의 절반.
              // 아이콘의 중앙 y좌표는 top(20) + size(40)/2 = 40.
              final double iconCenterX = constraints.maxWidth / 2.0;
              final double iconCenterY = 20.0 + (40.0 / 2.0); // Positioned.top + Icon.size/2
              const double iconRadius = 40.0 / 2.0; // Icon.size / 2

              // 3. 드롭 좌표와 아이콘 중앙 좌표 사이의 거리 계산
              final double dx = dropOffset.dx - iconCenterX;
              final double dy = dropOffset.dy - iconCenterY;
              final double distance = sqrt(dx * dx + dy * dy);

              // 4. 거리가 허용 반지름 이내인지 확인
              if (distance <= iconRadius) {
                final Map<String, dynamic> data = details.data;
                final int index = data['index'] as int;
                final SceneLayoutItem item = data['item'] as SceneLayoutItem;

                // 씬에서 가구 삭제
                ref.read(currentSceneProvider.notifier).removeItem(index);
                // 선택 해제
                setState(() => _selectedItemIndex = null);
                // 사용자 피드백
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.name}이(가) 삭제되었습니다.')),
                );
              } else {
                // 드롭 위치가 휴지통 아이콘 영역 밖이면 아무것도 하지 않음
                // 필요하다면 사용자에게 알림을 줄 수 있음
              }
            },
          );
        },
      ),
    );
  }
}