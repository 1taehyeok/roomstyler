// lib/features/editor/_wishlist_panel.dart
import 'dart:math'; // sqrt를 사용하기 위해 필요
import 'dart:io'; // File을 사용하기 위해 필요
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth 추가
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage 추가
import 'package:image_picker/image_picker.dart'; // ImagePicker 추가
import 'package:path/path.dart' as path; // path 추가
import 'package:roomstyler/core/models/furniture.dart';
import 'package:roomstyler/core/models/scene.dart'; // SceneLayoutItem 임포트 추가
import 'package:roomstyler/services/firebase_storage_service.dart'; // FirebaseStorageService 추가
import 'package:roomstyler/state/scene_providers.dart';
import 'package:roomstyler/state/wishlist_provider.dart';
import '_wishlist_item.dart'; // 찜 목록 아이템 위젯 임포트
import 'editor_constants.dart'; // Import the constants

/// 편집기 화면에 표시되는 찜 목록 슬라이드 패널 위젯입니다.
// --- 변경 1: ConsumerWidget -> ConsumerStatefulWidget ---
class WishlistPanel extends ConsumerStatefulWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onClose; // 패널 내 닫기 버튼용

  const WishlistPanel({
    super.key,
    required this.isOpen,
    required this.onToggle,
    required this.onClose,
  });

  @override
  ConsumerState<WishlistPanel> createState() => _WishlistPanelState();
}
// --- 변경 끝 ---

// --- 변경 2: StatefulWidget의 State 클래스 정의 ---
class _WishlistPanelState extends ConsumerState<WishlistPanel> {
  // --- 변경 3: 휴지통 표시 상태 추가 ---
  bool _isWishlistTrashVisible = false;

  // --- 변경 4: ImagePicker 인스턴스 추가 ---
  final ImagePicker _picker = ImagePicker();

  // --- 변경 5: 드래그 시작/종료 콜백 메소드 정의 ---
  void _onItemDragStarted() {
    setState(() {
      _isWishlistTrashVisible = true;
    });
  }

  void _onItemDragEnded() {
    setState(() {
      _isWishlistTrashVisible = false;
    });
  }
  // --- 변경 끝 ---

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: EditorConstants.wishlistPanelAnimationDuration,
      curve: Curves.easeInOut,
      child: SizedBox(
        height: widget.isOpen ? EditorConstants.wishlistPanelOpenHeight : EditorConstants.wishlistPanelClosedHeight,
        width: double.infinity,
        child: ClipRect(
          child: Container(
            color: Theme.of(context).cardColor,
            child: widget.isOpen
                ? _buildOpenPanel(ref)
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildOpenPanel(WidgetRef ref) {
    return SizedBox(
      height: EditorConstants.wishlistPanelOpenHeight,
      child: Column(
        children: [
          // 패널 헤더
          // --- 변경 6: 헤더에 '+' 버튼 추가 ---
          Container(
            height: 72, // 고정 높이: 패딩(32) + 텍스트/아이콘(40)
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0), // 좌우 패딩 추가
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('찜한 가구', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                // --- 변경 7: 헤더 우측 버튼들 그룹화 ---
                Row(
                  mainAxisSize: MainAxisSize.min, // 버튼 크기에 맞춤
                  children: [
                    // --- 변경 8: '+' 버튼 추가 ---
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _pickAndUploadCustomImage, // 메소드 연결
                      tooltip: '사용자 가구 추가',
                    ),
                    // --- 변경 끝 ---
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClose, // 기존 닫기 버튼
                      tooltip: '찜 목록 닫기',
                    ),
                  ],
                ),
                // --- 변경 끝 ---
              ],
            ),
          ),
          // 패널 내용 (찜한 가구 목록)
          Expanded(
            child: Stack(
              children: [
                // 가구 목록
                // --- 변경: Consumer 내부 로직을 간소화하고 StreamBuilder 제거 ---
                Consumer(
                  builder: (context, ref, child) {
                    final furnitures = ref.watch(wishlistProvider);
                    if (furnitures.isEmpty) {
                      return const Center(child: Text('찜한 가구가 없습니다.'));
                    }

                    // Note: whereIn 제한은 이제 적용되지 않습니다. List<Furniture>을 직접 사용합니다.
                    // furnitures 리스트는 이미 Firestore에서 가져온 최신 데이터입니다.

                    return SizedBox(
                      height: 112, // WishlistItem의 정확한 높이: 이미지(80) + 여백(4) + 텍스트(24) + 패딩(4)
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal, // 가로 스크롤
                        itemCount: furnitures.length,
                        itemBuilder: (context, index) {
                          final furniture = furnitures[index];
                          return WishlistItem(
                            furniture: furniture,
                            onAdd: () {
                              // 씬에 가구 추가
                              // 로컬 이미지일 경우, SceneLayoutItem에 localImagePath도 전달할 수 있습니다.
                              // 여기서는 기존 imageUrl만 전달하지만, 필요하다면 확장 가능합니다.
                              ref.read(currentSceneProvider.notifier).addItem(
                                    SceneLayoutItem(
                                      furnitureId: furniture.id,
                                      name: furniture.name,
                                      imageUrl: furniture.imageUrl, // 또는 furniture.localImagePath
                                      x: 0.5, // 기본 위치 (중앙)
                                      y: 0.5, // 기본 위치 (중앙)
                                      scale: 1.0,
                                      rotation: 0.0,
                                    ),
                                  );
                              // 패널 닫기 콜백 호출 (EditorScreen에서 처리)
                              widget.onToggle();
                              // 사용자 피드백
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${furniture.name}이(가) 배치되었습니다.')),
                              );
                            },
                            // --- 변경 9: WishlistItem에 드래그 콜백 연결 ---
                            onDragStarted: _onItemDragStarted,
                            onDragEnd: _onItemDragEnded,
                            // --- 변경 끝 ---
                          );
                        },
                      ),
                    );
                  },
                ),
                // --- 변경 10: WishlistTrashTarget 위치 및 애니메이션 적용 ---
                // 휴지통 DragTarget 추가
                AnimatedOpacity(
                  opacity: _isWishlistTrashVisible ? 1.0 : 0.0, // 상태에 따라 투명도 조절
                  duration: const Duration(milliseconds: 200), // 애니메이션 지속 시간
                  child: Align(
                    alignment: Alignment.bottomCenter, // 패널 하단 중앙에 배치
                    child: WishlistTrashTarget(
                      wishlistProvider: ref, // ref를 전달
                      sceneProvider: ref, // ref를 전달
                    ),
                  ),
                ),
                // 휴지통 끝
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 변경 11: 사용자 정의 이미지 추가 로직 (Firebase Storage 사용) ---
  Future<void> _pickAndUploadCustomImage() async { // 메소드명은 그대로 사용
    try {
      // 1. 이미지 선택
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery); // 또는 .camera
      if (pickedFile == null) return; // 사용자가 취소한 경우

      // 2. Firebase Storage에 이미지 업로드
      final FirebaseStorageService storageService = FirebaseStorageService();
      final imageFile = File(pickedFile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';
      final downloadUrl = await storageService.uploadImageFile(imageFile, folder: 'wishlist_images');

      // 3. (선택사항) 사용자에게 이름 입력 받기
      String itemName = '사용자 추가 가구';
      // --- 선택사항 시작: 이름 입력 다이얼로그 ---
      final TextEditingController nameController = TextEditingController();
      final String? result = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('가구 이름 입력'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: "가구의 이름을 입력하세요"),
              autofocus: true,
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('취소'),
                onPressed: () => Navigator.of(context).pop(), // 다이얼로그 닫기
              ),
              TextButton(
                child: const Text('확인'),
                onPressed: () => Navigator.of(context).pop(nameController.text), // 입력한 이름 반환
              ),
            ],
          );
        },
      );
      if (result != null && result.trim().isNotEmpty) {
        itemName = result.trim();
      }
      // --- 선택사항 끝 ---

      // 4. Storage URL과 이름을 포함한 데이터 Map 생성 및 Firestore에 추가
      final customFurnitureData = {
        'name': itemName,
        'imageUrl': downloadUrl, // <-- Firebase Storage URL 저장
        'category': 'custom', // (선택사항) 구분을 위한 카테고리
        'isLocalImage': false, // <-- 로컬 이미지가 아님을 표시
        // 나머지 필드는 기본값 또는 null
        'sku': '', // 빈 문자열로 초기화
        'size_width': 0, // 기본값 0
        'size_depth': 0, // 기본값 0
        'size_height': 0, // 기본값 0
        'color': '', // 빈 문자열로 초기화
        'material': '', // 빈 문자열로 초기화
        'price': 0.0, // 기본값 0.0
        'affiliate_url': null, // null로 초기화
        'localImagePath': null, // 로컬 경로는 사용하지 않음
      };

      // wishlistProvider에 addItem 메소드가 있어야 함 (Map 전달)
      await ref.read(wishlistProvider.notifier).addItem(customFurnitureData);

      // 5. 성공 피드백
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자 가구 "$itemName"이(가) 찜 목록에 추가되었습니다.')),
        );
      }

    } catch (e) {
      // 6. 오류 처리 및 피드백
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자 가구 추가 중 오류가 발생했습니다: $e')),
        );
      }
      // 로그 출력
      debugPrint("사용자 가구 추가 오류: $e");
    }
  }
  // --- 변경 끝 ---
}

// WishlistTrashTarget 위젯은 기존과 동일하게 유지됩니다.
// --- WishlistTrashTarget 위젯 정의 ---
// 찜 목록 패널 내부의 휴지통 DragTarget을 관리하는 StatefulWidget
class WishlistTrashTarget extends ConsumerStatefulWidget {
  final WidgetRef wishlistProvider;
  final WidgetRef sceneProvider;

  const WishlistTrashTarget({
    super.key,
    required this.wishlistProvider,
    required this.sceneProvider,
  });

  @override
  ConsumerState<WishlistTrashTarget> createState() => _WishlistTrashTargetState();
}

class _WishlistTrashTargetState extends ConsumerState<WishlistTrashTarget> {
  bool _isTrashHighlighted = false;
  // --- 휴지통 아이콘 위치 및 크기 정의 ---
  // Use constants from EditorConstants
  static const double _iconSize = EditorConstants.wishlistTrashIconSize;
  // _iconRadius는 더 이상 사용하지 않음
  static const double _containerWidth = EditorConstants.wishlistTrashContainerWidth;
  static const double _containerHeight = EditorConstants.wishlistTrashContainerHeight;
  static const double _positionedBottom = EditorConstants.wishlistTrashPositionedBottom;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Furniture>(
      builder: (context, candidateData, rejectedData) {
        // 드래그 중인 아이템이 이 DragTarget 위에 있는지 판단 (렌더된 영역 기준)
        final isDragOverTarget = candidateData.isNotEmpty;
        // --- 변경: 강조 조건을 isDragOverTarget만으로 결정 ---
        final bool shouldBeHighlighted = isDragOverTarget;
        
        return Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _positionedBottom, // 아이콘을 하단에서 약간 띄움
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: _containerWidth, // 휴지통 아이콘의 드래그 영역 너비
                  height: _containerHeight, // 휴지통 아이콘의 드래그 영역 높이
                  alignment: Alignment.center, // 아이콘을 컨테이너 중앙에 배치
                  child: Transform(
                    transform: Matrix4.translationValues(0, shouldBeHighlighted ? -10 : 0, 0),
                    child: Icon(
                      Icons.delete,
                      size: shouldBeHighlighted ? _iconSize : (_iconSize - 10), // 강조 시 크기 변경
                      color: shouldBeHighlighted ? Colors.red : Colors.grey, // 강조 시 색상 변경
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      onAcceptWithDetails: (details) {
        // onAcceptWithDetails가 호출되었다는 것은, 드롭 시점에 포인터가
        // WishlistTrashTarget 위젯의 영역 내에 있었다는 뜻입니다.
        // 따라서 삭제 로직을 바로 실행합니다.
        
        final furniture = details.data;
        // Provider를 사용하여 Firestore에서 가구 삭제
        widget.wishlistProvider.read(wishlistProvider.notifier).removeItem(furniture.id);
        // 사용자 피드백
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${furniture.name}이(가) 찜 목록에서 삭제되었습니다.')),
        );
      },
      onLeave: (data) {
        // 드래그 아이템이 위젯에서 벗어났을 때 강조 상태 해제
        if (mounted && _isTrashHighlighted) {
          setState(() {
            _isTrashHighlighted = false;
          });
        }
      },
      onMove: (details) {
        // --- 변경: Container 영역 내에 있는지 확인 ---
        // 1. 패널의 크기 가져오기 (높이는 상수, 너비는 화면 너비)
        final Size panelSize = MediaQuery.of(context).size;
        final double panelHeight = EditorConstants.wishlistPanelOpenHeight;
        final double panelWidth = panelSize.width;

        // 2. Container의 좌표 계산 (하단 중앙에 Align 되어 있고, AnimatedPositioned으로 위치 조정)
        // Container는 패널의 하단에서 _positionedBottom 만큼 떨어져 있고,
        // left: 0, right: 0 이므로 너비는 패널 전체 너비입니다.
        // 하지만 Container 자체의 너비는 _containerWidth 입니다.
        // Align의 alignment는 Alignment.bottomCenter 이므로, Container는 가로 중앙에 위치합니다.
        final double containerLeft = (panelWidth - _containerWidth) / 2.0;
        final double containerTop = panelHeight - _positionedBottom - _containerHeight;
        final double containerRight = containerLeft + _containerWidth;
        final double containerBottom = containerTop + _containerHeight;

        // 3. 드래그 포인터의 좌표
        final Offset dragOffset = details.offset;

        // 4. 포인터가 Container 영역 내에 있는지 확인
        final bool isPointerInsideContainer =
            dragOffset.dx >= containerLeft &&
            dragOffset.dx <= containerRight &&
            dragOffset.dy >= containerTop &&
            dragOffset.dy <= containerBottom;

        // debugPrint('onMove - Drag Offset: $dragOffset, Container Rect: ($containerLeft, $containerTop, $containerRight, $containerBottom), Inside: $isPointerInsideContainer');

        // 5. 강조 상태 결정 및 업데이트
        if (mounted && _isTrashHighlighted != isPointerInsideContainer) {
          setState(() {
            _isTrashHighlighted = isPointerInsideContainer;
          });
        }
        // --- 변경 끝 ---
      },
    );
  }
}
// --- WishlistTrashTarget 위젯 정의 끝 ---