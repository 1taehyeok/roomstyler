// lib/services/scene_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roomstyler/core/models/scene.dart';
import 'package:roomstyler/services/firebase_storage_service.dart';
import 'package:uuid/uuid.dart';

/// 씬(Scene)과 관련된 비즈니스 로직을 처리하는 서비스 클래스입니다.
class SceneService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorageService _storageService = FirebaseStorageService();

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

    // 이미지 처리
    String? imageUrl;
    if (imagePath != null) {
      // imagePath가 제공되면 Firebase Storage에 업로드
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        imageUrl = await _storageService.uploadImageFile(imageFile);
      }
    }

    // 저장할 씬 데이터 생성
    // imagePath가 있으면 Storage URL을 사용하고, 없으면 기존 scene.roomId를 유지
    final sceneToSave = scene.copyWith(
      id: sceneId,
      userId: user.uid,
      roomId: imageUrl ?? imagePath ?? scene.roomId,
    );

    await _firestore.collection('scenes').doc(sceneToSave.id).set(sceneToSave.toJson());

    return sceneToSave;
  }

  /// Firestore에서 씬을 삭제하고, 관련된 Storage 이미지도 삭제합니다.
  ///
  /// [docId]: 삭제할 씬 문서의 ID
  ///
  /// Throws: Firebase 관련 예외
  Future<void> deleteScene(String docId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 먼저 문서를 가져와서 roomId(이미지 URL)를 확인합니다.
    final docSnapshot = await _firestore.collection('scenes').doc(docId).get();
    
    if (!docSnapshot.exists) {
      throw Exception('삭제할 프로젝트를 찾을 수 없습니다.');
    }

    final sceneData = docSnapshot.data() as Map<String, dynamic>;
    final scene = Scene.fromJson(sceneData, docId);
    
    // Firestore 문서 삭제
    await _firestore.collection('scenes').doc(docId).delete();
    
    // roomId가 URL 형식인지 확인하고, 그렇다면 Storage 이미지 삭제
    if (scene.roomId.startsWith('http://') || scene.roomId.startsWith('https://')) {
      try {
        await _storageService.deleteImage(scene.roomId);
      } catch (e) {
        print('Storage 이미지 삭제 중 오류 발생: $e');
        // Storage 삭제 실패는 Firestore 삭제에는 영향을 주지 않음
      }
    }
  }

  /// 사용자의 모든 씬과 관련된 Storage 이미지를 삭제합니다.
  /// 주의: 이 메소드는 사용자 계정 삭제 시에만 사용되어야 합니다.
  ///
  /// Throws: Firebase 관련 예외
  Future<void> deleteAllScenesForUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 사용자의 모든 씬 문서를 가져옴
    final querySnapshot = await _firestore
        .collection('scenes')
        .where('user_id', isEqualTo: user.uid)
        .get();

    // 각 씬 문서와 관련된 Storage 이미지 삭제
    for (final doc in querySnapshot.docs) {
      final sceneData = doc.data();
      final scene = Scene.fromJson(sceneData, doc.id);
      
      // roomId가 URL 형식인지 확인하고, 그렇다면 Storage 이미지 삭제
      if (scene.roomId.startsWith('http://') || scene.roomId.startsWith('https://')) {
        try {
          await _storageService.deleteImage(scene.roomId);
        } catch (e) {
          print('Storage 이미지 삭제 중 오류 발생 (문서 ID: ${doc.id}): $e');
          // 개별 이미지 삭제 실패는 전체 프로세스를 중단하지 않음
        }
      }
      
      // Firestore 문서 삭제
      await _firestore.collection('scenes').doc(doc.id).delete();
    }
  }
}