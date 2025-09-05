// lib/features/editor/_wishlist_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:roomstyler/core/models/furniture.dart';
import 'dart:io'; // File을 사용하기 위해 필요

/// 찜 목록 패널에 표시되는 개별 가구 아이템을 나타내는 위젯입니다.
class WishlistItem extends ConsumerWidget {
  final Furniture furniture;
  final VoidCallback onAdd;
  // --- 변경 1: 드래그 콜백 prop 추가 ---
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;
  // --- 변경 끝 ---

  const WishlistItem({
    super.key,
    required this.furniture,
    required this.onAdd,
    // --- 변경 2: 생성자에 prop 추가 ---
    this.onDragStarted,
    this.onDragEnd,
    // --- 변경 끝 ---
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Draggable<Furniture>(
      data: furniture, // 드래그 시 전달할 데이터
      feedback: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            // --- 수정: feedback 위젯도 로컬/네트워크 이미지 구분 ---
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Firebase Storage URL 또는 로컬 이미지 경로 처리
                if (furniture.imageUrl != null && furniture.imageUrl!.isNotEmpty) {
                  // Firebase Storage URL 이미지 표시
                  return CachedNetworkImage(
                    imageUrl: furniture.imageUrl!,
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
                  );
                } else if (furniture.isLocalImage == true && furniture.localImagePath != null) {
                  // 로컬 이미지 표시
                  return Image.file(
                    File(furniture.localImagePath!),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.red.withOpacity(0.5),
                      child: const Icon(Icons.error),
                    ),
                  );
                } else {
                  // 둘 다 없을 경우 기본 플레이스홀더
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Center(
                      child: Text(
                        furniture.name,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  );
                }
              },
            ),
            // --- 수정 끝 ---
          ),
        ),
      ),
      childWhenDragging: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Center(
          child: Icon(Icons.drag_indicator, color: Colors.grey),
        ),
      ),
      // --- 변경 3: Draggable 콜백 연결 ---
      onDragStarted: onDragStarted, // 드래그 시작 시 콜백 호출
      onDragEnd: (_) => onDragEnd?.call(), // 드래그 종료 시 콜백 호출
      // --- 변경 끝 ---
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
          padding: const EdgeInsets.all(4.0), // 패딩을 줄여서 높이 계산 정확성 향상
          child: Column(
            mainAxisSize: MainAxisSize.min, // 콘텐츠 크기에 맞춤
            children: [
              // 가구 이미지: 로컬 이미지 경로(localImagePath)가 있으면 FileImage, 없으면 CachedNetworkImage 사용
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final furnitureMap = furniture.toJson(); // Furniture 객체를 Map으로 변환
                    // 로컬 이미지 표시 로직
                    // Firebase Storage URL 또는 로컬 이미지 경로 처리
                      if (furnitureMap['imageUrl'] != null) {
                        // Firebase Storage URL 이미지 표시 (CachedNetworkImage 사용)
                        return CachedNetworkImage(
                          imageUrl: furnitureMap['imageUrl'] as String,
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
                        );
                      } else if (furnitureMap['isLocalImage'] == true &&
                          furnitureMap['localImagePath'] != null) {
                        // 로컬 이미지 표시
                        final localPath = furnitureMap['localImagePath'] as String;
                        return Image.file(
                          File(localPath),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.red.withOpacity(0.5),
                            child: const Icon(Icons.error),
                          ),
                        );
                      } else {
                        // 둘 다 없거나 유효하지 않은 경우, 기본 플레이스홀더
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: Center(
                            child: Text(
                              furniture.name,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        );
                      }
                  },
                ),
              ),
              const SizedBox(height: 4),
              // 가구 이름
              Flexible(
                child: Text(
                  furniture.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}