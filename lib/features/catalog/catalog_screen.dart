import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roomstyler/core/models/furniture.dart';
import 'package:roomstyler/core/models/scene.dart';
import 'package:roomstyler/state/scene_providers.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _queryCtrl = TextEditingController();
  String _category = '전체';
  final _categories = const ['전체', '소파', '테이블', '의자', '조명', '수납'];

  @override
  Widget build(BuildContext context) {
    final furnitureStream = FirebaseFirestore.instance
        .collection('furnitures') // 'furnitures' 컬렉션 사용
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('가구 카탈로그'),
        actions: [
          IconButton(
            onPressed: () => context.push('/editor'),
            icon: const Icon(Icons.check),
            tooltip: '편집기로 이동',
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchBar(
              hintText: '가구/스타일 검색',
              leading: const Icon(Icons.search),
              controller: _queryCtrl,
              onSubmitted: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _categories
                  .map((c) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = c),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: furnitureStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('가구가 없습니다.'));
                }

                final documents = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: .8,
                  ),
                  itemCount: documents.length,
                  itemBuilder: (_, i) {
                    final doc = documents[i];
                    final furniture = Furniture.fromJson(
                        doc.data() as Map<String, dynamic>, doc.id);
                    return _FurnitureCard(
                      title: furniture.name,
                      price: furniture.price.toInt(),
                      image: furniture.imageUrl ?? 'https://picsum.photos/600/400', // Placeholder
                      onAdd: () {
                        ref.read(currentSceneProvider.notifier).addItem(
                              SceneLayoutItem(
                                furnitureId: furniture.id,
                                name: furniture.name, // name 추가
                                imageUrl: furniture.imageUrl, // imageUrl 추가
                                x: 0.5, // 기본 위치
                                y: 0.5, // 기본 위치
                              ),
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${furniture.name}이(가) 편집기에 추가되었습니다.'),
                            action: SnackBarAction(
                              label: '보기',
                              onPressed: () => context.push('/editor'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FurnitureCard extends StatelessWidget {
  final String title;
  final int price;
  final String image;
  final VoidCallback onAdd;
  const _FurnitureCard({required this.title, required this.price, required this.image, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onAdd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4/3,
              child: CachedNetworkImage(imageUrl: image, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${price.toString()}원'),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('배치'),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
