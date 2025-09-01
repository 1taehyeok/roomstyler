import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roomstyler/core/models/scene.dart';
import 'package:roomstyler/state/scene_providers.dart';
import 'package:roomstyler/state/wishlist_provider.dart'; // 찜 목록 Provider 임포트
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
          // 찜 목록 개수 표시 (테스트용)
          Consumer(
            builder: (context, ref, child) {
              final wishlist = ref.watch(wishlistProvider);
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('찜: ${wishlist.length}'),
              );
            },
          ),
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
          NavigationDestination(icon: Icon(Icons.account_circle_outlined), label: '마이'), // Updated icon and label
        ],
        onDestinationSelected: (i) {
          if (i == 1) context.push('/catalog');
          if (i == 3) context.push('/mypage'); // Updated index for MyPage
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
              // 편집기로 이동 (배경 이미지 경로도 함께 전달)
              context.push('/editor', extra: scene.roomId); // roomId에 원본 이미지 경로가 저장되어 있음
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
            return _ProjectCard(
              scene: scene,
              onTap: () => onProjectSelected(scene),
              onDelete: (docId) => _deleteProject(context, docId, scene.id), // 삭제 콜백 전달 (문서 ID 사용)
              onRename: _renameProject, // 이름 변경 콜백 전달
            );
          }).toList(),
        );
      },
    );
  }

  // 프로젝트 삭제 메소드
  Future<void> _deleteProject(BuildContext context, String docId, String sceneId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('프로젝트 삭제'),
          content: const Text('정말 이 프로젝트를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(false), // 아니오
            ),
            TextButton(
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true), // 예
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Firestore에서 문서 삭제
        await FirebaseFirestore.instance.collection('scenes').doc(docId).delete();
        // 성공 메시지 표시
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('프로젝트가 삭제되었습니다.')),
          );
        }
      } catch (e) {
        // 오류 메시지 표시
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }

  // 프로젝트 이름 변경 메소드
  Future<void> _renameProject(String docId, String newName) async {
    // 이름이 비어있거나 공백만 있는 경우 처리
    if (newName.trim().isEmpty) {
      // 필요시 사용자에게 알림
      return;
    }

    try {
      // Firestore 문서에 'custom_name' 필드 업데이트
      await FirebaseFirestore.instance.collection('scenes').doc(docId).update({
        'custom_name': newName,
      });
    } catch (e) {
      // 오류 처리 (예: SnackBar로 알림)
      // 이 부분은 HomeScreen의 context가 필요하므로, 더 깔끔한 방법은 Provider나 callback을 사용하는 것입니다.
      // 간단한 예시로 여기에 직접 context를 전달받아 사용할 수도 있지만, 구조를 단순하게 유지하기 위해 생략합니다.
      print('이름 변경 중 오류 발생: $e');
    }
  }
}

// Firestore에서 불러온 Scene 데이터를 기반으로 렌더링하는 카드 위젯
class _ProjectCard extends StatelessWidget {
  final Scene scene;
  final VoidCallback onTap;
  final Function(String) onDelete; // 삭제 콜백 수정: 문서 ID 필요
  final Function(String, String) onRename; // 이름 변경 콜백 추가: (문서 ID, 새 이름)

  const _ProjectCard({
    required this.scene,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    // 간단한 날짜 포맷 (예: 2023-10-27)
    final formattedDate = DateFormat('yyyy-MM-dd').format(scene.createdAt);
    // 문서 ID 가져오기 (Firestore 문서 ID)
    final docId = scene.id; // scene.id가 Firestore 문서 ID입니다.

    return SizedBox(
      width: 180,
      child: Card(
        child: GestureDetector(
          onLongPress: () {
            // 롱 프레스 시 하단 시트 표시
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('이름 변경'),
                        onTap: () {
                          Navigator.of(context).pop(); // Bottom sheet 닫기
                          _showRenameDialog(context, docId, scene.id == 'temp' ? '임시 프로젝트' : '프로젝트 #${scene.id.substring(0, 8)}', onRename);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: const Text('삭제', style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.of(context).pop(); // Bottom sheet 닫기
                          onDelete(docId); // onDelete 콜백 호출
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
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
                        _getDisplayName(scene),
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
      ),
    );
  }

  // 이름 변경 다이얼로그를 표시하는 메소드
  Future<void> _showRenameDialog(BuildContext context, String docId, String currentName, Function(String, String) onRename) async {
    final TextEditingController _nameController = TextEditingController(text: currentName);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('프로젝트 이름 변경'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: "새 이름 입력"),
            // autofocus: true, // 필요시 주석 해제
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final newName = _nameController.text.trim();
                if (newName.isNotEmpty) { // 이름 유효성 검사
                  onRename(docId, newName);
                }
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  // Scene 객체에서 표시할 이름을 가져오는 헬퍼 메소드
  String _getDisplayName(Scene scene) {
    // Scene 객체에 customName 필드가 있고, 그 값이 비어 있지 않으면 그것을 사용
    if (scene.customName != null && scene.customName!.isNotEmpty) {
      return scene.customName!;
    }
    // 그렇지 않으면 기존 방식의 이름 사용
    return scene.id == 'temp' ? '임시 프로젝트' : '프로젝트 #${scene.id.substring(0, 8)}';
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