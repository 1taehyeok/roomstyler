// lib/features/editor/_wishlist_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:roomstyler/core/models/furniture.dart';

/// 찜 목록 패널에 표시되는 개별 가구 아이템을 나타내는 위젯입니다.
class WishlistItem extends ConsumerWidget {
  final Furniture furniture;
  final VoidCallback onAdd;

  const WishlistItem({super.key, required this.furniture, required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Draggable<Furniture>(
      data: furniture, // 드래그 시 전달할 데이터
      feedback: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: CachedNetworkImage(
            imageUrl: furniture.imageUrl ?? 'https://picsum.photos/600/400',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
      ),
      childWhenDragging: Container(
        width: 100,
        height: 100,
        color: Colors.grey.withOpacity(0.5), // 드래그 중일 때 원래 위치 표시
      ),
      onDragStarted: () {
        // 드래그 시작 시 추가 로직 (예: 진동 등)
      },
      onDragEnd: (details) {
        // 드래그 종료 시 추가 로직 (성공/실패 여부 등)
      },
      child: GestureDetector(
        onTap: onAdd,
        onLongPress: () {
          // 롱프레스 시에도 패널을 닫고 피드백을 줄 수 있습니다.
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('${furniture.name}을(를) 드래그하여 삭제하세요.')),
          // );
        },
        child: Container(
          width: 100, // 아이템 너비
          margin: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // 가구 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CachedNetworkImage(
                  imageUrl: furniture.imageUrl ?? 'https://picsum.photos/600/400',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // 가구 이름
              Text(
                furniture.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}