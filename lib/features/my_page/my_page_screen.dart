// lib/features/my_page/my_page_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomstyler/core/models/scene.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:roomstyler/state/wishlist_provider.dart'; // Import wishlist provider

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이 페이지'),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- User Profile Section ---
          _buildProfileSection(context, user),
          const SizedBox(height: 20),

          // --- Account Settings Section ---
          _buildSectionTitle(context, '계정 설정'),
          _buildSettingsTile(context, Icons.password, '계정 설정', () {
            // Navigate to account settings screen
            context.push('/mypage/account');
          }),
          _buildSettingsTile(context, Icons.notifications, '알림 설정', () {
            // Navigate to notification settings screen
            context.push('/mypage/notifications');
          }),
          _buildSettingsTile(context, Icons.brightness_6, '테마 설정', () {
            // 테마 설정 화면으로 이동
            context.push('/mypage/theme');
          }),
          const SizedBox(height: 20),

          // --- My Projects Section ---
          _buildSectionTitle(context, '내 프로젝트'),
          _buildMyProjectsSection(context, user),
          const SizedBox(height: 20),

          // --- Wishlist Section ---
          _buildSectionTitle(context, '찜 목록'),
          _buildWishlistSection(context),
          const SizedBox(height: 20),

          // --- App Info Section ---
          _buildSectionTitle(context, '앱 정보'),
          _buildSettingsTile(context, Icons.info, '버전 정보', () {
            // TODO: Implement app version info
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('버전: v1.0.0')),
            );
          }),
          _buildSettingsTile(context, Icons.help, '도움말 및 피드백', () {
            // Navigate to help & feedback screen
            context.push('/mypage/help-feedback');
          }),
          const SizedBox(height: 20),

          // --- Logout Button ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text('로그아웃'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Background color
                foregroundColor: Colors.white, // Text color
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the user profile section
  Widget _buildProfileSection(BuildContext context, User? user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('사용자 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                // Placeholder for profile picture
                const CircleAvatar(
                  radius: 30,
                  // backgroundImage: AssetImage('path/to/default/avatar.png'), // Add a default avatar
                  child: Icon(Icons.person, size: 30),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? '닉네임 미설정',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        user?.email ?? '이메일 미연동',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 5),
                      if (user?.metadata.creationTime != null)
                        Text(
                          '가입일: ${DateFormat('yyyy-MM-dd').format(user!.metadata.creationTime!)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Edit Profile Button
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () {
                  // Navigate to edit profile screen
                  context.push('/mypage/edit-profile');
                },
                child: const Text('프로필 수정'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a section title
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Builds a settings tile
  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  /// Builds the "My Projects" section
  Widget _buildMyProjectsSection(BuildContext context, User? user) {
    if (user == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('로그인 후 프로젝트를 확인할 수 있습니다.'),
        ),
      );
    }

    final projectsStream = FirebaseFirestore.instance
        .collection('scenes')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('created_at', descending: true)
        .limit(3) // Show only the latest 3 projects
        .snapshots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: projectsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(child: Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator())));
            }
            if (snapshot.hasError) {
              return Card(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('프로젝트 로드 중 오류 발생: ${snapshot.error}')));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text('프로젝트가 없습니다.')));
            }

            final documents = snapshot.data!.docs;

            return Column(
              children: documents.map((doc) {
                final scene = Scene.fromJson(doc.data() as Map<String, dynamic>, doc.id);
                return _ProjectCard(scene: scene, onTap: () {
                  // TODO: Navigate to editor with this scene
                  // For now, show a snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('프로젝트 클릭됨: ${scene.id.substring(0, 8)}')),
                  );
                });
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        // "더보기" button to navigate to the full projects list
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // Navigate to the full my projects screen
              context.push('/mypage/projects');
            },
            child: const Text('더보기'),
          ),
        ),
      ],
    );
  }

  /// Builds the "Wishlist" section
  Widget _buildWishlistSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('찜한 가구', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            // Wishlist items count and view button
            Consumer(
              builder: (context, ref, child) {
                final wishlist = ref.watch(wishlistProvider);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('총 ${wishlist.length}개의 아이템'),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to the full wishlist screen
                        context.push('/mypage/wishlist');
                      },
                      child: const Text('찜 목록 보기'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Handles logout with confirmation
  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('로그아웃 확인'),
          content: const Text('정말 로그아웃 하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          // Router will automatically redirect to /signin due to redirect logic
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그아웃 되었습니다.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('로그아웃 실패: $e')),
          );
        }
      }
    }
  }
}

/// A simple project card for the "My Projects" section
class _ProjectCard extends StatelessWidget {
  final Scene scene;
  final VoidCallback onTap;

  const _ProjectCard({required this.scene, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(scene.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8.0),
        leading: Container(
          width: 60,
          height: 60,
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: const Center(child: Icon(Icons.image, size: 30)),
        ),
        title: Text(
          scene.id == 'temp' ? '임시 프로젝트' : '프로젝트 #${scene.id.substring(0, 8)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important for proper layout
          children: [
            Text(formattedDate, style: const TextStyle(fontSize: 12)),
            Text('${scene.layout.length} items', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}