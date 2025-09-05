// lib/services/firebase_storage_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

/// Firebase Storage와 관련된 작업을 처리하는 서비스 클래스입니다.
class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 파일 경로를 기반으로 이미지를 Firebase Storage에 업로드합니다.
  /// 
  /// [imageFile] 업로드할 이미지 파일
  /// [folder] Storage 내에 저장할 폴더 이름 (기본값: 'room_images')
  /// 
  /// Returns: 업로드된 이미지의 다운로드 URL
  /// 
  /// Throws: Firebase Storage 관련 예외
  Future<String> uploadImageFile(File imageFile, {String folder = 'room_images'}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    try {
      // 파일 이름 생성 (중복 방지를 위해 timestamp 추가)
      final fileName = path.basename(imageFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = _storage.ref().child('$folder/${user.uid}/$timestamp-$fileName');

      // 파일 업로드
      await storageRef.putFile(imageFile);
      
      // 다운로드 URL 가져오기
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase Storage 업로드 오류: $e');
      throw Exception('이미지 업로드에 실패했습니다: ${e.message}');
    }
  }

  /// 바이트 데이터를 기반으로 이미지를 Firebase Storage에 업로드합니다.
  /// 
  /// [imageBytes] 업로드할 이미지의 바이트 데이터
  /// [fileName] 저장할 파일 이름
  /// [folder] Storage 내에 저장할 폴더 이름 (기본값: 'room_images')
  /// 
  /// Returns: 업로드된 이미지의 다운로드 URL
  /// 
  /// Throws: Firebase Storage 관련 예외
  Future<String> uploadImageBytes(Uint8List imageBytes, String fileName, {String folder = 'room_images'}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    try {
      // 파일 이름 생성 (중복 방지를 위해 timestamp 추가)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = _storage.ref().child('$folder/${user.uid}/$timestamp-$fileName');

      // 바이트 데이터 업로드
      await storageRef.putData(imageBytes);
      
      // 다운로드 URL 가져오기
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase Storage 업로드 오류: $e');
      throw Exception('이미지 업로드에 실패했습니다: ${e.message}');
    }
  }

  /// Storage에서 이미지를 삭제합니다.
  /// 
  /// [imageUrl] 삭제할 이미지의 URL
  /// 
  /// Throws: Firebase Storage 관련 예외
  Future<void> deleteImage(String imageUrl) async {
    try {
      // URL에서 참조 생성
      final imageRef = _storage.refFromURL(imageUrl);
      // 이미지 삭제
      await imageRef.delete();
    } on FirebaseException catch (e) {
      print('Firebase Storage 삭제 오류: $e');
      throw Exception('이미지 삭제에 실패했습니다: ${e.message}');
    }
  }
}