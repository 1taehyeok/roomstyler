// lib/services/scene_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roomstyler/core/models/scene.dart';
import 'package:uuid/uuid.dart';

/// 씬(Scene)과 관련된 비즈니스 로직을 처리하는 서비스 클래스입니다.
class SceneService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 주어진 씬을 Firestore에 저장합니다.
  ///
  /// [scene]: 저장할 씬 객체
  /// [imagePath]: 저장할 배경 이미지 경로 (선택사항)
  ///
  /// Returns: 저장된 씬 객체 (ID가 업데이트된 상태)
  ///
  /// Throws: Firebase 관련 예외
  Future<Scene> saveScene(Scene scene, {String? imagePath}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final sceneId = scene.id == 'temp' ? const Uuid().v4() : scene.id;

    // 저장할 씬 데이터 생성. roomId에는 현재 배경 이미지 경로를 저장.
    // imagePath가 있으면 그것을 사용하고, 없으면 기존 scene.roomId를 유지.
    final sceneToSave = scene.copyWith(
      id: sceneId,
      userId: user.uid,
      roomId: imagePath ?? scene.roomId,
    );

    await _firestore.collection('scenes').doc(sceneToSave.id).set(sceneToSave.toJson());

    return sceneToSave;
  }
}