// lib/state/wishlist_provider.dart
import 'dart:async'; // StreamSubscription을 사용하기 위해 필요
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 찜 목록 상태를 관리하는 Notifier 클래스
class WishlistNotifier extends Notifier<Set<String>> {
  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // 현재 로그인한 사용자
  User? get _user => FirebaseAuth.instance.currentUser;

  // 실시간 리스너를 위한 스트림 구독
  StreamSubscription<QuerySnapshot>? _subscription;

  // Provider의 상태를 초기화하고, 필요한 경우 리스너를 설정합니다.
  @override
  Set<String> build() {
    // 초기 상태는 빈 Set
    // 로그인 상태가 변경될 때마다 build()가 재호출됩니다.
    _setupListener();
    return const {};
  }

  // Firestore 실시간 리스너 설정
  void _setupListener() {
    // 기존 리스너 해제
    _subscription?.cancel();
    _subscription = null;

    // 로그인한 사용자가 없으면 리스너를 설정하지 않음
    if (_user == null) {
      state = const {}; // 상태도 초기화
      return;
    }

    // Firestore 컬렉션 참조
    final wishlistRef = _firestore.collection('users').doc(_user!.uid).collection('wishlist');

    // 실시간 리스너 설정
    _subscription = wishlistRef.snapshots().listen(
      (snapshot) {
        // Firestore에서 가져온 문서 ID(furnitureId) 목록으로 Set을 생성
        final furnitureIds = <String>{};
        for (final doc in snapshot.docs) {
          furnitureIds.add(doc.id); // 문서 ID가 곧 furnitureId입니다.
        }
        // 상태 업데이트
        state = furnitureIds;
      },
      onError: (error) {
        // 오류 처리 (예: 로그 출력, 사용자에게 알림)
        print('WishlistNotifier: Firestore 리스너 오류: $error');
        // 상태는 그대로 유지하거나, 오류 상태를 표시할 수 있습니다.
      },
    );
  }

  // 찜 목록에 가구 추가
  Future<void> addItem(String furnitureId) async {
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
    // 하지만 네트워크 지연을 고려해 즉각적인 피드백을 주려면 아래 주석을 해제할 수 있습니다.
    // state = {...state, furnitureId};
  }

  // 찜 목록에서 가구 제거
  Future<void> removeItem(String furnitureId) async {
    if (_user == null) {
      print('WishlistNotifier: 로그인하지 않은 사용자는 찜 목록을 조작할 수 없습니다.');
      return;
    }
    final wishlistRef = _firestore.collection('users').doc(_user!.uid).collection('wishlist');
    // 해당 문서 삭제
    await wishlistRef.doc(furnitureId).delete();
    // 로컬 상태는 Firestore 리스너가 자동으로 업데이트하므로 여기서 직접 변경하지 않아도 됩니다.
    // 하지만 네트워크 지연을 고려해 즉각적인 피드백을 주려면 아래 주석을 해제할 수 있습니다.
    // state = Set.from(state)..remove(furnitureId);
  }

  // 찜 목록에 가구 추가/제거 토글
  Future<void> toggleItem(String furnitureId) async {
    if (state.contains(furnitureId)) {
      await removeItem(furnitureId);
    } else {
      await addItem(furnitureId);
    }
  }
}

// Riverpod Provider 정의
final wishlistProvider = NotifierProvider<WishlistNotifier, Set<String>>(() {
  return WishlistNotifier();
});