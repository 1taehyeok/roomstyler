import 'package:roomstyler/state/scene_providers.dart';
import 'package:roomstyler/core/models/scene.dart'; // Scene 모델 임포트 추가
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class NewProjectInitializer extends ConsumerWidget {
  final Widget child;
  const NewProjectInitializer({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 위젯 트리가 완전히 빌드된 후 상태를 변경하도록 Future.microtask 사용
    // 이는 Riverpod에서 제공하는 안전한 상태 업데이트 방법입니다.
    Future.microtask(() {
      ref.read(currentSceneProvider.notifier).state = Scene(
        id: 'temp',
        roomId: 'temp_room_${DateTime.now().millisecondsSinceEpoch}',
        layout: [],
      );
    });

    return child;
  }
}