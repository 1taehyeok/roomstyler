// lib/features/editor/_furniture_item_view.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:roomstyler/core/models/scene.dart';

/// 편집기 캔버스에 표시되는 개별 가구 아이템을 나타내는 위젯입니다.
class FurnitureItemView extends StatelessWidget {
  final SceneLayoutItem item;
  final bool isSelected;
  final double baseSize;
  final VoidCallback onDelete;

  const FurnitureItemView({
    super.key,
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
      child: Container(
        width: itemSize,
        height: itemSize,
        decoration: BoxDecoration(
          // ✅ 선택 시 배경 추가
          color: isSelected ? Colors.blue.withOpacity(0.2) : null,
          // ✅ 선택 시 테두리 추가
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
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
    );
  }
}