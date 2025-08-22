import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ConsumerWidget을 사용하기 위해 필요
import 'package:go_router/go_router.dart';
import 'package:roomstyler/core/models/furniture.dart';
import 'package:roomstyler/core/models/scene.dart';
import 'package:roomstyler/state/scene_providers.dart';
import 'package:roomstyler/state/wishlist_provider.dart'; // 찜 목록 Provider 임포트

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
    // Firestore 쿼리 구성
    Query furnitureQuery = FirebaseFirestore.instance.collection('furnitures');

    // 1. 카테고리 필터 적용
    if (_category != '전체') {
      furnitureQuery = furnitureQuery.where('category', isEqualTo: _category);
    }

    // 2. 검색어 필터 적용 (이름에 포함되는지 확인)
    // Firestore에서 부분 문자열 검색은 인덱스가 필요하므로, 여기서는 간단히 시작 문자열 검색을 시도합니다.
    // 더 복잡한 검색은 로컬에서 처리하거나, Algolia 같은 전용 검색 솔루션을 고려해야 합니다.
    final queryText = _queryCtrl.text.trim();
    if (queryText.isNotEmpty) {
      // 'name' 필드가 queryText로 시작하는 문서들을 찾습니다. (대소문자 구분)
      // 주의: 이 방식은 Firestore의 정렬 규칙에 따라 달라질 수 있습니다.
      furnitureQuery = furnitureQuery
          .where('name', isGreaterThanOrEqualTo: queryText)
          .where('name', isLessThan: '$queryText\uf8ff');
    }

    // 3. 쿼리 실행
    final furnitureStream = furnitureQuery.snapshots();

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
                      furniture: furniture,
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

class _FurnitureCard extends ConsumerWidget {
  final Furniture furniture;
  final VoidCallback onAdd;
  const _FurnitureCard({required this.furniture, required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        onTap: () async {
          // 카드를 탭했을 때 확인 팝업 띄우기
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('찜하기'),
                content: Text('${furniture.name}을(를) 찜하시겠습니까?'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('취소'),
                    onPressed: () {
                      Navigator.of(context).pop(false); // 취소
                    },
                  ),
                  TextButton(
                    child: const Text('찜하기'),
                    onPressed: () {
                      Navigator.of(context).pop(true); // 확인
                    },
                  ),
                ],
              );
            },
          );

          // 사용자가 "찜하기"를 선택한 경우
          if (confirm == true) {
            ref.read(wishlistProvider.notifier).toggleItem(furniture.id);
            // 사용자 피드백
            final isNowWishlisted = ref.read(wishlistProvider).contains(furniture.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      isNowWishlisted
                          ? '${furniture.name}이(가) 찜 목록에 추가되었습니다.'
                          : '${furniture.name}이(가) 찜 목록에서 제거되었습니다.')),
            );
          }
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 4/3,
                  child: CachedNetworkImage(imageUrl: furniture.imageUrl ?? 'https://picsum.photos/600/400', fit: BoxFit.cover),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(furniture.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${furniture.price.toInt()}원'),
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
            // --- 찜 버튼 추가 ---
            Consumer(
              builder: (context, ref, child) {
                final wishlist = ref.watch(wishlistProvider);
                final isWishlisted = wishlist.contains(furniture.id);
                return Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(wishlistProvider.notifier).toggleItem(furniture.id);
                    },
                    child: Icon(
                      isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: isWishlisted ? Colors.red : null,
                    ),
                  ),
                );
              },
            ),
            // --- 찜 버튼 끝 ---
          ],
        ),
      ),
    );
  }
}