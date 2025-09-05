// lib/state/wishlist_provider.dart
import 'dart:async'; // StreamSubscription을 사용하기 위해 필요
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roomstyler/core/models/furniture.dart'; // Furniture 모델 임포트
import 'package:roomstyler/services/firebase_storage_service.dart'; // FirebaseStorageService 임포트

// 찜 목록 상태를 관리하는 Notifier 클래스
// --- 변경: state 타입을 Set<String>에서 List<Furniture>로 ---
class WishlistNotifier extends Notifier<List<Furniture>> {
  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // 현재 로그인한 사용자
  User? get _user => FirebaseAuth.instance.currentUser;

  // 실시간 리스너를 위한 스트림 구독
  StreamSubscription<QuerySnapshot>? _subscription;

  // Provider의 상태를 초기화하고, 필요한 경우 리스너를 설정합니다.
  @override
  List<Furniture> build() {
    // 초기 상태는 빈 리스트
    // 로그인 상태가 변경될 때마다 build()가 재호출됩니다.
    _setupListener();
    return const [];
  }

  // Firestore 실시간 리스너 설정
  void _setupListener() {
    // 기존 리스너 해제
    _subscription?.cancel();
    _subscription = null;

    // 로그인한 사용자가 없으면 리스너를 설정하지 않음
    if (_user == null) {
      state = const []; // 상태도 초기화
      return;
    }

    // Firestore 컬렉션 참조
    final wishlistRef = _firestore.collection('users').doc(_user!.uid).collection('wishlist');

    // 실시간 리스너 설정
    _subscription = wishlistRef.snapshots().listen(
      (snapshot) async { // async 추가
        try {
          // 1. 먼저, 모든 문서의 ID와 데이터를 분류합니다.
          final List<String> furnitureIdsToFetch = []; // 기존 방식 (ID만 있는 문서)
          final List<Map<String, dynamic>> customFurnitureData = []; // 새로운 방식 (데이터가 있는 문서)
          final List<String> customFurnitureDocIds = []; // 새로운 방식 문서의 ID (나중에 매칭용)

          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data.length == 2 && data.containsKey('furnitureId') && data.containsKey('addedAt')) {
              // 기존 방식: furnitureId와 addedAt만 있는 문서
              furnitureIdsToFetch.add(data['furnitureId'] as String);
            } else {
              // 새로운 방식: name, localImagePath 등이 포함된 문서
              customFurnitureData.add(data);
              customFurnitureDocIds.add(doc.id);
            }
          }

          // 2. 기존 방식 문서들의 상세 정보를 furnitures 컬렉션에서 병렬 조회
          List<Furniture> fetchedFurnitures = [];
          if (furnitureIdsToFetch.isNotEmpty) {
            // Note: whereIn은 최대 10개 제한이 있으므로, 필요한 경우 여러 번 나누어 조회해야 합니다.
            // 간단한 예제이므로 10개 이하를 가정합니다.
            if (furnitureIdsToFetch.length > 10) {
              print('WishlistNotifier: 가져올 가구 ID가 10개를 초과합니다. 일부만 가져옵니다.');
              // 또는, furnitureIdsToFetch를 10개씩 잘라서 여러 번 조회하는 로직을 추가할 수 있습니다.
            }
            
            final furnitureDocs = await _firestore
                .collection('furnitures')
                .where(FieldPath.documentId, whereIn: furnitureIdsToFetch.take(10).toList())
                .get();

            fetchedFurnitures = furnitureDocs.docs.map((doc) {
              return Furniture.fromJson(doc.data() as Map<String, dynamic>, doc.id);
            }).toList();
          }

          // 3. 새로운 방식 문서들을 Furniture 객체로 변환
          final List<Furniture> customFurnitures = [];
          for (int i = 0; i < customFurnitureData.length; i++) {
            final data = customFurnitureData[i];
            final docId = customFurnitureDocIds[i];
            customFurnitures.add(Furniture.fromJson(data, docId));
          }

          // 4. 두 리스트를 합칩니다.
          final allFurnitures = [...fetchedFurnitures, ...customFurnitures];

          // 5. 상태 업데이트
          state = allFurnitures;
        } catch (e) {
          print('WishlistNotifier: Firestore 리스너 데이터 처리 중 오류: $e');
          // 오류 발생 시 빈 리스트로 상태 초기화 또는 기존 상태 유지
          // state = const []; 
        }
      },
      onError: (error) {
        // 오류 처리 (예: 로그 출력, 사용자에게 알림)
        print('WishlistNotifier: Firestore 리스너 오류: $error');
        // 상태는 그대로 유지하거나, 오류 상태를 표시할 수 있습니다.
      },
    );
  }

  // --- 변경 1: addItem 메소드 이름 변경 및 새로운 addItem 메소드 추가 ---
  /// 찜 목록에 가구 ID 추가 (기존 로직 유지 - Firestore에 ID만 저장)
  Future<void> addItemById(String furnitureId) async {
    if (_user == null) {
      print('WishlistNotifier: 로그인하지 않은 사용자는 찜할 수 없습니다.');
      return;
    }
    final wishlistRef = _firestore.collection('users').doc(_user!.uid).collection('wishlist');
    // 문서 ID를 furnitureId로 사용하여 추가
    await wishlistRef.doc(furnitureId).set({
      'furnitureId': furnitureId,
      'addedAt': FieldValue.serverTimestamp(), // 서버 시간 기록
    });
    // 로컬 상태는 Firestore 리스너가 자동으로 업데이트하므로 여기서 직접 변경하지 않아도 됩니다.
    // state = [...state, Furniture 객체 생성해서 추가]; // 이제는 이렇게 하지 않음
  }

  /// 찜 목록에 사용자 정의 가구 데이터 추가 (사용자 정의 이미지용)
  /// [customFurnitureData]는 'name', 'localImagePath' 등의 키를 포함하는 Map입니다.
  Future<void> addItem(Map<String, dynamic> customFurnitureData) async {
    if (_user == null) {
      print('WishlistNotifier: 로그인하지 않은 사용자는 찜할 수 없습니다.');
      return;
    }
    final wishlistRef = _firestore.collection('users').doc(_user!.uid).collection('wishlist');
    // 사용자 정의 가구 데이터를 Firestore에 추가. 문서 ID는 Firestore가 자동 생성.
    await wishlistRef.add({
      ...customFurnitureData, // 전달받은 Map 데이터
      'addedAt': FieldValue.serverTimestamp(), // 서버 시간 기록
      // 'isCustom': true, // 이제 Furniture 모델에 isLocalImage 필드가 있으므로 필요 없음
    });
    // 로컬 상태는 Firestore 리스너가 자동으로 업데이트하므로 여기서 직접 변경하지 않아도 됩니다.
  }
  // --- 변경 끝 ---

  // 찜 목록에서 가구 제거
  Future<void> removeItem(String furnitureId) async {
    if (_user == null) {
      print('WishlistNotifier: 로그인하지 않은 사용자는 찜 목록을 조작할 수 없습니다.');
      return;
    }
    
    final wishlistRef = _firestore.collection('users').doc(_user!.uid).collection('wishlist');
    
    // 먼저 문서를 가져와서 Storage 이미지 URL이 있는지 확인
    final docSnapshot = await wishlistRef.doc(furnitureId).get();
    if (docSnapshot.exists) {
      final furnitureData = docSnapshot.data() as Map<String, dynamic>?;
      
      // Firebase Storage 이미지 삭제 (imageUrl이 있는 경우)
      if (furnitureData != null && furnitureData['imageUrl'] != null) {
        try {
          final storageService = FirebaseStorageService();
          await storageService.deleteImage(furnitureData['imageUrl'] as String);
        } catch (e) {
          print('WishlistNotifier: Firebase Storage 이미지 삭제 중 오류 발생: $e');
        }
      }
    }
    
    // 해당 문서 삭제
    await wishlistRef.doc(furnitureId).delete();
    // 로컬 상태는 Firestore 리스너가 자동으로 업데이트하므로 여기서 직접 변경하지 않아도 됩니다.
    // state = state.where((f) => f.id != furnitureId).toList(); // 이제는 이렇게 하지 않음
  }

  // 찜 목록에 가구 추가/제거 토글 (기존 로직 유지)
  Future<void> toggleItem(String furnitureId) async {
    // 현재 state(List<Furniture>)에서 해당 ID를 가진 아이템이 있는지 확인
    final bool isAlreadyInWishlist = state.any((furniture) => furniture.id == furnitureId);
    
    if (isAlreadyInWishlist) {
      await removeItem(furnitureId);
    } else {
      await addItemById(furnitureId); // 이름 변경된 메소드 호출
    }
  }
}

// Riverpod Provider 정의
// --- 변경: Provider의 타입도 List<Furniture>로 ---
final wishlistProvider = NotifierProvider<WishlistNotifier, List<Furniture>>(() {
  return WishlistNotifier();
});