import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roomstyler/core/models/scene.dart';
import 'package:roomstyler/state/scene_providers.dart';
import 'package:intl/intl.dart'; // 날짜 포맷팅을 위해 추가

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

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
          // 최근 프로젝트 (Firestore에서 불러오기)
          const _SectionTitle('내 프로젝트'),
          if (user != null)
            _UserProjectsList(userId: user.uid, onProjectSelected: (scene) {
              // Riverpod 상태 업데이트
              ref.read(currentSceneProvider.notifier).state = scene;
              // 편집기로 이동
              context.push('/editor');
            })
          else
            const Center(child: Text('로그인이 필요합니다.')),
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

// Firestore에서 사용자 프로젝트 목록을 불러와 표시하는 위젯
class _UserProjectsList extends StatelessWidget {
  final String userId;
  final Function(Scene) onProjectSelected;

  const _UserProjectsList({required this.userId, required this.onProjectSelected});

  @override
  Widget build(BuildContext context) {
    final projectsStream = FirebaseFirestore.instance
        .collection('scenes')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: projectsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('오류 발생: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('저장된 프로젝트가 없습니다.'));
        }

        final documents = snapshot.data!.docs;

        return Wrap(
          spacing: 8, runSpacing: 8,
          children: documents.map((doc) {
            final scene = Scene.fromJson(doc.data() as Map<String, dynamic>, doc.id);
            return _ProjectCard(scene: scene, onTap: () => onProjectSelected(scene));
          }).toList(),
        );
      },
    );
  }
}

// Firestore에서 불러온 Scene 데이터를 기반으로 렌더링하는 카드 위젯
class _ProjectCard extends StatelessWidget {
  final Scene scene;
  final VoidCallback onTap;

  const _ProjectCard({required this.scene, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 간단한 날짜 포맷 (예: 2023-10-27)
    final formattedDate = DateFormat('yyyy-MM-dd').format(scene.createdAt);

    return SizedBox(
      width: 180,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16/9,
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: const Center(child: Icon(Icons.image, size: 32)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.id == 'temp' ? '임시 프로젝트' : '프로젝트 #${scene.id.substring(0, 8)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    // 아이템 개수 표시
                    Text(
                      '${scene.layout.length} items',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
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
