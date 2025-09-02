// lib/features/my_page/wishlist_screen.dart
import 'dart:io'; // Import dart:io for File
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:roomstyler/core/models/furniture.dart';
import 'package:roomstyler/state/wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('찜 목록'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // 뒤로가기
        ),
      ),
      body: wishlist.isEmpty
          ? const Center(
              child: Text(
                '찜한 가구가 없습니다.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.75, // 너비 대비 높이 비율 조정
              ),
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                final furniture = wishlist[index];
                return _WishlistItemCard(furniture: furniture);
              },
            ),
    );
  }
}

class _WishlistItemCard extends ConsumerWidget {
  final Furniture furniture;

  const _WishlistItemCard({required this.furniture});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: Stack(
        children: [
          // 가구 이미지 및 정보
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지
              AspectRatio(
                aspectRatio: 4 / 3,
                child: furniture.isLocalImage && furniture.localImagePath != null
                    ? Image.file(
                        File(furniture.localImagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // 로컬 이미지 로드 실패 시 대체 위젯
                          return const Center(
                            child: Icon(Icons.error, color: Colors.red),
                          );
                        },
                      )
                    : CachedNetworkImage(
                        imageUrl: furniture.imageUrl ?? 'https://picsum.photos/600/400',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.error, color: Colors.red),
                        ),
                      ),
              ),
              // 정보
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      furniture.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('${furniture.price.toInt()}원'),
                  ],
                ),
              ),
            ],
          ),
          // 삭제 버튼 (우측 상단)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                // 찜 목록에서 제거
                ref.read(wishlistProvider.notifier).removeItem(furniture.id);
                // 피드백
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${furniture.name}이(가) 찜 목록에서 삭제되었습니다.')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}