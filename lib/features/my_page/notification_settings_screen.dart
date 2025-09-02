// lib/features/my_page/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Notification preferences
  bool _projectUpdates = true;
  bool _wishlistUpdates = true;
  bool _appUpdates = true;
  bool _promotional = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // Load notification preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _projectUpdates = prefs.getBool('notifications.project_updates') ?? true;
      _wishlistUpdates =
          prefs.getBool('notifications.wishlist_updates') ?? true;
      _appUpdates = prefs.getBool('notifications.app_updates') ?? true;
      _promotional = prefs.getBool('notifications.promotional') ?? false;
    });
  }

  // Save notification preferences to SharedPreferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications.project_updates', _projectUpdates);
    await prefs.setBool('notifications.wishlist_updates', _wishlistUpdates);
    await prefs.setBool('notifications.app_updates', _appUpdates);
    await prefs.setBool('notifications.promotional', _promotional);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '알림 받기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('프로젝트 업데이트'),
              subtitle: const Text('프로젝트 처리 상태 및 결과 알림'),
              value: _projectUpdates,
              onChanged: (value) {
                setState(() {
                  _projectUpdates = value;
                });
                _savePreferences();
              },
            ),
            SwitchListTile(
              title: const Text('찜 목록 업데이트'),
              subtitle: const Text('찜한 가구의 할인 및 재입고 알림'),
              value: _wishlistUpdates,
              onChanged: (value) {
                setState(() {
                  _wishlistUpdates = value;
                });
                _savePreferences();
              },
            ),
            SwitchListTile(
              title: const Text('앱 업데이트'),
              subtitle: const Text('새로운 기능 및 업데이트 알림'),
              value: _appUpdates,
              onChanged: (value) {
                setState(() {
                  _appUpdates = value;
                });
                _savePreferences();
              },
            ),
            SwitchListTile(
              title: const Text('프로모션 및 할인'),
              subtitle: const Text('특별 할인 및 이벤트 알림'),
              value: _promotional,
              onChanged: (value) {
                setState(() {
                  _promotional = value;
                });
                _savePreferences();
              },
            ),
          ],
        ),
      ),
    );
  }
}