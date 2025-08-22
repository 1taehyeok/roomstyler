import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/scene.dart';
import 'scene_history_provider.dart'; // SceneHistoryController 임포트

// SceneController를 직접 생성하는 대신, Factory 함수를 사용하여 새로운 인스턴스를 생성하도록 변경
// SceneController에 Ref를 주입하기 위해 Reader를 사용
final currentSceneProvider = StateNotifierProvider<SceneController, Scene>((ref) {
  // 새로운 빈 Scene 객체를 생성하여 SceneController에 전달
  // Scene ID는 'temp'로, roomId는 고유한 임시 ID를 사용하여 새로운 프로젝트임을 명확히 함.
  return SceneController(
    Scene(
      id: 'temp',
      roomId: 'temp_room_${DateTime.now().millisecondsSinceEpoch}', // 고유한 임시 roomId 생성
      layout: [],
    ),
    ref, // Ref 주입
  );
});

class SceneController extends StateNotifier<Scene> {
  final Ref ref; // Riverpod Ref 주입

  SceneController(super.state, this.ref);

  // --- Undo/Redo 작업 단위 제어를 위한 필드 ---
  bool _isOperationActive = false;
  Scene? _pendingOperationState;

  /// 연속된 작업(예: 제스처)의 시작을 알립니다.
  void startOperation() {
    _isOperationActive = true;
    _pendingOperationState = state;
  }

  /// 연속된 작업(예: 제스처)의 종료를 알리고, 히스토리에 저장합니다.
  void endOperation() {
    if (_isOperationActive && _pendingOperationState != null) {
      ref.read(sceneHistoryProvider.notifier).push(_pendingOperationState!);
      _isOperationActive = false;
      _pendingOperationState = null;
    }
  }

  /// 연속된 작업 중 상태를 업데이트합니다. (디바운싱 대상)
  /// 실제 히스토리 저장은 [endOperation]에서 이루어집니다.
  void _updatePendingState(Scene newState) {
    if (_isOperationActive) {
      _pendingOperationState = newState;
    }
  }

  void addItem(SceneLayoutItem item) {
    final newState = Scene(
      id: state.id,
      roomId: state.roomId,
      layout: [...state.layout, item],
      removedFurnitureIds: state.removedFurnitureIds,
      addedFurnitureIds: [...state.addedFurnitureIds, item.furnitureId],
      renderParams: state.renderParams,
      outputUrl: state.outputUrl,
      createdAt: state.createdAt,
    );
    if (_isOperationActive) {
      // 연속 작업 중이라면 pending state 업데이트
      _updatePendingState(newState);
    } else {
      // 일반적인 추가는 바로 히스토리에 저장
      ref.read(sceneHistoryProvider.notifier).push(state);
    }
    state = newState;
  }

  void updateItem(int index, SceneLayoutItem newItem) {
    final list = [...state.layout];
    list[index] = newItem;
    final newState = Scene(
      id: state.id,
      roomId: state.roomId,
      layout: list,
      removedFurnitureIds: state.removedFurnitureIds,
      addedFurnitureIds: state.addedFurnitureIds,
      renderParams: state.renderParams,
      outputUrl: state.outputUrl,
      createdAt: state.createdAt,
    );

    if (_isOperationActive) {
      // 연속 작업 중이라면 pending state 업데이트
      _updatePendingState(newState);
    } else {
      // 일반적인 업데이트는 바로 히스토리에 저장
      ref.read(sceneHistoryProvider.notifier).push(state);
    }
    state = newState;
  }

  void removeItem(int index) {
    final list = [...state.layout]..removeAt(index);
    final newState = Scene(
      id: state.id,
      roomId: state.roomId,
      layout: list,
      removedFurnitureIds: state.removedFurnitureIds,
      addedFurnitureIds: state.addedFurnitureIds,
      renderParams: state.renderParams,
      outputUrl: state.outputUrl,
      createdAt: state.createdAt,
    );
    if (_isOperationActive) {
      // 연속 작업 중이라면 pending state 업데이트
      _updatePendingState(newState);
    } else {
      // 일반적인 삭제는 바로 히스토리에 저장
      ref.read(sceneHistoryProvider.notifier).push(state);
    }
    state = newState;
  }

  void clear() {
    final newState = Scene(id: state.id, roomId: state.roomId, layout: []);
    if (_isOperationActive) {
      // 연속 작업 중이라면 pending state 업데이트
      _updatePendingState(newState);
    } else {
      // 일반적인 클리어는 바로 히스토리에 저장
      ref.read(sceneHistoryProvider.notifier).push(state);
    }
    state = newState;
  }
}