import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _queryCtrl = TextEditingController();
  String _category = '전체';
  final _categories = const ['전체','소파','테이블','의자','조명','수납'];

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(16,8,16,0),
            child: SearchBar(
              hintText: '가구/스타일 검색',
              leading: const Icon(Icons.search),
              controller: _queryCtrl,
              onSubmitted: (_) => setState((){}),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _categories.map((c) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .8,
              ),
              itemCount: 10, // TODO: 실제 데이터 바인딩
              itemBuilder: (_, i) => _FurnitureCard(
                title: '스칸디 의자 ${i+1}',
                price: 89000 + i * 1000,
                image: 'https://picsum.photos/seed/f$i/600/400',
                onAdd: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('편집기에 가구가 추가되었습니다.')),
                  );
                },
              ),
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
