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
  // 드래그/제스처가 시작되기 직전의 원본 상태를 저장합니다.
  Scene? _operationOriginalState;

  /// 연속된 작업(예: 제스처)의 시작을 알립니다.
  void startOperation() {
    if (_isOperationActive) return;
    _isOperationActive = true;
    // 작업 시작 직전 상태를 저장 (Undo 시 돌아갈 상태)
    _operationOriginalState = state;
    print('DEBUG: SceneController.startOperation called. _isOperationActive: $_isOperationActive');
  }

  /// 연속된 작업(예: 제스처)의 종료를 알리고, 히스토리에 저장합니다.
  void endOperation() {
    print('DEBUG: SceneController.endOperation called. _isOperationActive: $_isOperationActive, _operationOriginalState is null: ${_operationOriginalState == null}');
    if (_isOperationActive && _operationOriginalState != null) {
      // 작업 전 상태를 한 번만 히스토리에 저장하여 Undo 시 정확히 되돌아가도록 함
      ref.read(sceneHistoryProvider.notifier).push(_operationOriginalState!);
    }
    _isOperationActive = false;
    _operationOriginalState = null;
  }

  // 연속 작업 중에는 히스토리를 업데이트하지 않습니다. (endOperation에서 한 번 처리)

  /// 씬 전체를 새로운 씬으로 교체합니다.
  /// 히스토리에는 이전 상태가 저장됩니다.
  void setScene(Scene newScene) {
    ref.read(sceneHistoryProvider.notifier).push(state);
    state = newScene;
  }

  /// 씬의 상태를 이전 상태로 복원합니다. (예: Undo/Redo)
  /// 히스토리에는 현재 상태를 저장하지 않습니다.
  void restoreState(Scene restoredScene) {
    state = restoredScene;
  }

  /// 씬의 레이아웃을 새로운 레이아웃으로 업데이트합니다.
  /// 히스토리에는 이전 상태가 저장됩니다.
  void updateLayout(List<SceneLayoutItem> newLayout) {
    final newState = state.copyWith(layout: newLayout);
    if (!_isOperationActive) {
      // 일반 업데이트는 변경 전 상태를 히스토리에 저장
      ref.read(sceneHistoryProvider.notifier).push(state);
    }
    state = newState;
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
    if (!_isOperationActive) {
      // 일반적인 추가는 바로 히스토리에 저장(변경 전 상태)
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

    if (!_isOperationActive) {
      // 일반적인 업데이트는 변경 전 상태를 히스토리에 저장
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
    if (!_isOperationActive) {
      // 일반적인 삭제는 변경 전 상태를 히스토리에 저장
      ref.read(sceneHistoryProvider.notifier).push(state);
    }
    state = newState;
  }

  void clear() {
    final newState = Scene(id: state.id, roomId: state.roomId, layout: []);
    if (!_isOperationActive) {
      // 일반적인 클리어는 변경 전 상태를 히스토리에 저장
      ref.read(sceneHistoryProvider.notifier).push(state);
    }
    state = newState;
  }
}