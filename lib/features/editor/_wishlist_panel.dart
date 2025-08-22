// lib/features/editor/_wishlist_panel.dart
import 'dart:math'; // sqrt를 사용하기 위해 필요
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomstyler/core/models/furniture.dart';
import 'package:roomstyler/core/models/scene.dart'; // SceneLayoutItem 임포트 추가
import 'package:roomstyler/state/scene_providers.dart';
import 'package:roomstyler/state/wishlist_provider.dart';
import '_wishlist_item.dart'; // 찜 목록 아이템 위젯 임포트

/// 편집기 화면에 표시되는 찜 목록 슬라이드 패널 위젯입니다.
class WishlistPanel extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // --- 휴지통 아이콘 위치 및 크기 정의 ---
    const double iconSize = 40.0; // 휴지통 아이콘 크기
    const double iconRadius = iconSize / 2; // 휴지통 아이콘 반지름
    // --- DragTarget 수정 ---
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), // 애니메이션 시간
      curve: Curves.easeInOut, // 애니메이션 커브
      height: isOpen ? 200 : 0, // 패널 높이 (열려있을 때 200, 닫혀있을 때 0)
      width: double.infinity, // 너비는 화면 전체
      child: Container(
        color: Theme.of(context).cardColor, // 패널 배경색
        child: Stack(
          children: [
            // 패널 내용 (찜한 가구 목록)
            Column(
              children: [
                // 패널 헤더
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('찜한 가구', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onClose, // 닫기 버튼
                      ),
                    ],
                  ),
                ),
                // 패널 내용 (찜한 가구 목록)
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final wishlistIds = ref.watch(wishlistProvider);
                      if (wishlistIds.isEmpty) {
                        return const Center(child: Text('찜한 가구가 없습니다.'));
                      }

                      // Firestore에서 찜한 가구들의 상세 정보를 가져옵니다.
                      // Note: whereIn은 최대 10개의 항목만 허용합니다. 더 많은 경우 처리 로직이 필요할 수 있습니다.
                      // 간단한 예제이므로 10개 이하를 가정합니다.
                      if (wishlistIds.length > 10) {
                        return const Center(child: Text('찜한 가구가 너무 많습니다. 일부만 표시됩니다.'));
                        // 또는, wishlistIds.take(10).toList() 와 같이 상위 10개만 가져오도록 수정할 수 있습니다.
                      }

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('furnitures')
                            .where(FieldPath.documentId, whereIn: wishlistIds.toList())
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('오류: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(child: Text('찜한 가구 정보를 불러올 수 없습니다.'));
                          }

                          final furnitureDocs = snapshot.data!.docs;
                          final furnitures = furnitureDocs.map((doc) {
                            return Furniture.fromJson(doc.data() as Map<String, dynamic>, doc.id);
                          }).toList();

                          return ListView.builder(
                            scrollDirection: Axis.horizontal, // 가로 스크롤
                            itemCount: furnitures.length,
                            itemBuilder: (context, index) {
                              final furniture = furnitures[index];
                              return WishlistItem(
                                furniture: furniture,
                                onAdd: () {
                                  // 씬에 가구 추가
                                  ref.read(currentSceneProvider.notifier).addItem(
                                        SceneLayoutItem(
                                          furnitureId: furniture.id,
                                          name: furniture.name,
                                          imageUrl: furniture.imageUrl,
                                          x: 0.5, // 기본 위치 (중앙)
                                          y: 0.5, // 기본 위치 (중앙)
                                          scale: 1.0,
                                          rotation: 0.0,
                                        ),
                                      );
                                  // 패널 닫기 콜백 호출 (EditorScreen에서 처리)
                                  onToggle();
                                  // 사용자 피드백
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${furniture.name}이(가) 배치되었습니다.')),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            // --- 휴지통 DragTarget 추가 ---
            WishlistTrashTarget(
              wishlistProvider: ref, // ref를 전달
              sceneProvider: ref, // ref를 전달
            ),
            // --- 휴지통 끝 ---
          ],
        ),
      ),
    );
  }
}

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
  // --- 휴지통 아이콘 위치 및 크기 정의 (onMove에서 재사용) ---
  static const double _iconSize = 40.0;
  static const double _iconRadius = _iconSize / 2;
  static const double _containerWidth = 50.0;
  static const double _containerHeight = 50.0;
  static const double _positionedBottom = 10.0;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Furniture>(
      builder: (context, candidateData, rejectedData) {
        // 드래그 중인 아이템이 이 DragTarget 위에 있는지 판단 (렌더링된 영역 기준)
        // 이 값은 아이콘의 *표시* 여부를 결정하는 데 사용되지 않고, 
        // 아이콘의 *스타일* (크기, 색상)을 결정하는 데 사용됩니다.
        // 아이콘의 표시 여부는 AnimatedPositioned의 위치와 Container 크기에 의해 결정됩니다.
        final isDragOverTarget = candidateData.isNotEmpty;
        
        return AnimatedPositioned(
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
                transform: Matrix4.translationValues(0, isDragOverTarget && _isTrashHighlighted ? -10 : 0, 0),
                child: Icon(
                  Icons.delete,
                  size: (isDragOverTarget && _isTrashHighlighted) ? _iconSize : (_iconSize - 10), // 강조 시 크기 변경
                  color: (isDragOverTarget && _isTrashHighlighted) ? Colors.red : Colors.grey, // 강조 시 색상 변경
                ),
              ),
            ),
          ),
        );
      },
      onAcceptWithDetails: (details) {
        // --- 드롭 좌표 검증 로직 ---
        // 1. 드롭된 위치의 Offset 가져오기
        final Offset dropOffset = details.offset;
        
        // 2. 휴지통 아이콘의 중앙 좌표 계산 (대략적으로)
        // 위젯 트리에서 부모 위젯의 크기를 얻는 더 정확한 방법은 LayoutBuilder를 사용하거나
        // GlobalKey를 사용하는 것입니다. 여기서는 간단한 추정을 사용합니다.
        // 이 로직은 패널의 높이, 아이콘 위치, 크기가 변경되면 함께 수정되어야 합니다.
        
        final Size panelSize = MediaQuery.of(context).size;
        final double panelHeight = 200.0; // 패널이 열려있을 때의 높이 (AnimatedContainer.height)
        final double iconCenterX = panelSize.width / 2.0;
        // 패널 하단 기준으로 아이콘 중앙까지의 거리
        final double iconCenterYFromBottom = _positionedBottom + (_containerHeight / 2.0); 
        final double iconCenterY = panelHeight - iconCenterYFromBottom;

        // 3. 드롭 좌표와 아이콘 중앙 좌표 사이의 거리 계산
        // y축 방향이 드래그 포인터 offset과 패널 높이 계산에서 일관되게 처리
        final double dx = dropOffset.dx - iconCenterX;
        final double dy = (panelSize.height - dropOffset.dy) - iconCenterY; 
        final double distance = sqrt(dx * dx + dy * dy);

        // 4. 거리가 허용 반지름 이내인지 확인
        if (distance <= _iconRadius) {
          final furniture = details.data;
          // Provider를 사용하여 Firestore에서 가구 삭제
          widget.wishlistProvider.read(wishlistProvider.notifier).removeItem(furniture.id);
          // 사용자 피드백
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${furniture.name}이(가) 찜 목록에서 삭제되었습니다.')),
          );
        } else {
          // 드롭 위치가 휴지통 아이콘 영역 밖이면 아무것도 하지 않음
        }
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
        // --- 드래그 중 아이콘 강조 로직 ---
        // 1. 드래그 포인터의 현재 Offset 가져오기
        final Offset dragOffset = details.offset;
        
        // 2. 휴지통 아이콘의 중앙 좌표 계산 (위와 동일)
        final Size panelSize = MediaQuery.of(context).size;
        final double panelHeight = 200.0;
        final double iconCenterX = panelSize.width / 2.0;
        final double iconCenterYFromBottom = _positionedBottom + (_containerHeight / 2.0); 
        final double iconCenterY = panelHeight - iconCenterYFromBottom;

        // 3. 드래그 포인터와 아이콘 중앙 좌표 사이의 거리 계산
        final double dx = dragOffset.dx - iconCenterX;
        final double dy = (panelSize.height - dragOffset.dy) - iconCenterY; 
        final double distance = sqrt(dx * dx + dy * dy);

        // 4. 거리에 따라 강조 상태 결정 및 업데이트
        final bool shouldBeHighlighted = distance <= _iconRadius;
        if (mounted && _isTrashHighlighted != shouldBeHighlighted) {
          setState(() {
            _isTrashHighlighted = shouldBeHighlighted;
          });
        }
      },
    );
  }
}
// --- WishlistTrashTarget 위젯 정의 끝 ---