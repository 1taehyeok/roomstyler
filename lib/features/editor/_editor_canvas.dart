// lib/features/editor/_editor_canvas.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roomstyler/core/models/scene.dart';
import 'package:roomstyler/state/scene_providers.dart';
import 'dart:io';
import 'dart:math';
import '_furniture_item_view.dart';

class EditorCanvas extends ConsumerStatefulWidget {
  final String? backgroundImage;
  final VoidCallback onBackgroundTap;
  const EditorCanvas({
    super.key,
    required this.backgroundImage,
    required this.onBackgroundTap,
  });
  @override
  ConsumerState createState() => _EditorCanvasState();
}

class _EditorCanvasState extends ConsumerState<EditorCanvas> {
  int? _selectedItemIndex;
  SceneLayoutItem? _originalItemOnDragStart;
  int? _draggingItemIndex;

  Offset _dragStartOffset = Offset.zero;
  Offset _itemStartOffset = Offset.zero;
  double _startScale = 1.0;
  double _startRotation = 0.0;
  final trashKey = GlobalKey();
  bool _isTrashVisible = false;
  bool _isTrashHighlighted = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          onPointerDown: (_) {
            // 배경 탭 시 선택 해제
            if (_isTrashVisible == false) {
              setState(() {
                _selectedItemIndex = null;
              });
            }
          },
          child: Stack(
            children: [
              // 배경 이미지
              if (widget.backgroundImage != null)
                Image.file(
                  File(widget.backgroundImage!),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                )
              else
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey[200],
                  child: const Center(child: Text('여기에 방 배경이 표시됩니다.')),
                ),
              // 휴지통 아이콘
              IgnorePointer(
                ignoring: !_isTrashVisible,
                child: Opacity(
                  opacity: _isTrashVisible ? 1.0 : 0.0,
                  child: Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.delete,
                        key: trashKey,
                        size: _isTrashHighlighted ? 50 : 40,
                        color: _isTrashHighlighted ? Colors.redAccent : Colors.red,
                      ),
                    ),
                  ),
                ),
              ),

              // 가구 아이템들
              ..._buildFurnitureItems(constraints),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildFurnitureItems(BoxConstraints constraints) {
    final scene = ref.watch(currentSceneProvider);
    final canvasWidth = constraints.maxWidth;
    final canvasHeight = constraints.maxHeight;
    return scene.layout.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isSelectedForEditing = _selectedItemIndex == index && !_isTrashVisible;
      final isSelectedForDeleting = _draggingItemIndex == index && _isTrashVisible;

      const itemBaseSize = 100.0;
      final scale = isSelectedForDeleting ? 0.9 : 1.0;

      return Positioned(
        left: item.x * canvasWidth - (itemBaseSize * item.scale * scale / 2),
        top: item.y * canvasHeight - (itemBaseSize * item.scale * scale / 2),
        child: Transform.scale(
          scale: scale,
          child: _buildFurnitureItem(
            item,
            index,
            isSelectedForEditing,
            itemBaseSize,
            canvasWidth,
            canvasHeight,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildFurnitureItem(
    SceneLayoutItem item,
    int index,
    bool isSelected,
    double baseSize,
    double canvasWidth,
    double canvasHeight,
  ) {
    return GestureDetector(
      onTap: () {
        if (_isTrashVisible) return;
        setState(() {
          _selectedItemIndex = index;
        });
      },

      // 삭제 제스처 (LongPress)
      onLongPressStart: (details) {
        setState(() {
          _selectedItemIndex = null;
          _isTrashVisible = true;
          _draggingItemIndex = index;
          _originalItemOnDragStart = item;
          _dragStartOffset = details.globalPosition;
          _itemStartOffset = Offset(item.x * canvasWidth, item.y * canvasHeight);
        });
      },

      onLongPressMoveUpdate: (details) {
        if (!_isTrashVisible || _draggingItemIndex != index) return;

        final delta = details.globalPosition - _dragStartOffset;
        final newX = (_itemStartOffset.dx + delta.dx) / canvasWidth;
        final newY = (_itemStartOffset.dy + delta.dy) / canvasHeight;

        ref.read(currentSceneProvider.notifier).updateItem(
              _draggingItemIndex!,
              _originalItemOnDragStart!.copyWith(x: newX.clamp(0.0, 1.0), y: newY.clamp(0.0, 1.0)),
            );
        _updateTrashHighlight(details.globalPosition);
      },

      onLongPressUp: () {
        if (!_isTrashVisible || _draggingItemIndex != index) return;

        if (_isTrashHighlighted) {
          // 삭제 처리
          ref.read(currentSceneProvider.notifier).removeItem(_draggingItemIndex!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_originalItemOnDragStart?.name}(이)가 삭제되었습니다.')),
          );
        } else {
          // 삭제되지 않았다면 원위치로 복구
          ref.read(currentSceneProvider.notifier).updateItem(
                _draggingItemIndex!,
                _originalItemOnDragStart!,
              );
        }
        
        // 모든 상태 초기화
        setState(() {
          _isTrashVisible = false;
          _isTrashHighlighted = false;
          _draggingItemIndex = null;
          _originalItemOnDragStart = null;
          _selectedItemIndex = null;
        });
      },

      // 일반 제스처 (Scale)
      onScaleStart: (details) {
        if (_isTrashVisible) return;
        setState(() {
          _selectedItemIndex = index;
          _startScale = item.scale;
          _startRotation = item.rotation;
          _dragStartOffset = details.focalPoint;
          _itemStartOffset = Offset(item.x * canvasWidth, item.y * canvasHeight);
        });
      },
      onScaleUpdate: (details) {
        if (_isTrashVisible || _selectedItemIndex != index) return;

        if (details.pointerCount == 1) {
          final delta = details.focalPoint - _dragStartOffset;
          final newX = (_itemStartOffset.dx + delta.dx) / canvasWidth;
          final newY = (_itemStartOffset.dy + delta.dy) / canvasHeight;
          ref.read(currentSceneProvider.notifier).updateItem(
                index,
                item.copyWith(x: newX.clamp(0.0, 1.0), y: newY.clamp(0.0, 1.0)),
              );
        } else {
          final newScale = (_startScale * details.scale).clamp(0.5, 3.0);
          final newRotation = _startRotation + details.rotation;
          ref.read(currentSceneProvider.notifier).updateItem(
                index,
                item.copyWith(scale: newScale, rotation: newRotation),
              );
        }
      },
      onScaleEnd: (details) {
        if (_isTrashVisible) return;
      },

      child: FurnitureItemView(
        item: item,
        isSelected: isSelected,
        baseSize: baseSize,
        onDelete: () {
          ref.read(currentSceneProvider.notifier).removeItem(index);
          setState(() {
            _selectedItemIndex = null;
          });
        },
      ),
    );
  }

  void _updateTrashHighlight(Offset globalPosition) {
    if (!_isTrashVisible) return;
    final renderBox = trashKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final trashSize = renderBox.size;
    final trashPosition = renderBox.localToGlobal(Offset.zero);
    final iconCenterX = trashPosition.dx + trashSize.width / 2;
    final iconCenterY = trashPosition.dy + trashSize.height / 2;
    final iconRadius = trashSize.width;
    final dx = globalPosition.dx - iconCenterX;
    final dy = globalPosition.dy - iconCenterY;
    final distance = sqrt(dx * dx + dy * dy);
    
    if (_isTrashHighlighted != (distance <= iconRadius)) {
      setState(() {
        _isTrashHighlighted = distance <= iconRadius;
      });
    }
  }
}