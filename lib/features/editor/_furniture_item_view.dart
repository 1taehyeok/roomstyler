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
    super.key, // key 추가
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