import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RoomStyler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/upload'),
        icon: const Icon(Icons.add_a_photo),
        label: const Text('내 방 꾸미기 시작'),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
          NavigationDestination(icon: Icon(Icons.chair_outlined), label: '가구'),
          NavigationDestination(icon: Icon(Icons.recommend_outlined), label: '추천'),
          NavigationDestination(icon: Icon(Icons.collections_bookmark_outlined), label: '프로젝트'),
        ],
        onDestinationSelected: (i) {
          if (i == 1) context.push('/catalog');
          // 추천, 프로젝트는 후속 구현
        },
        selectedIndex: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // 히어로 섹션
          Card(
            child: InkWell(
              onTap: () => context.push('/upload'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('사진 한 장으로 인테리어 시뮬레이션',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          SizedBox(height: 8),
                          Text('AI 자동 배치 · 실시간 미세 조정 · 결과 공유/구매까지'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.auto_awesome, size: 48),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 최근 프로젝트 (더미)
          const _SectionTitle('내 프로젝트'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: List.generate(4, (i) => _ProjectCard(index: i)),
          ),
          const SizedBox(height: 8),
          const _SectionTitle('스타일별 추천 시작하기'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: const [
              _StyleChip('모던'), _StyleChip('미니멀'), _StyleChip('북유럽'),
              _StyleChip('내추럴'), _StyleChip('빈티지'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final int index;
  const _ProjectCard({required this.index});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: InkWell(
          onTap: () => context.push('/editor'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16/9,
                child: Container(color: Theme.of(context).colorScheme.surfaceVariant),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text('프로젝트 #${index+1}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  final String label;
  const _StyleChip(this.label);
  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: false,
      onSelected: (_) => context.push('/catalog'),
    );
  }
}
