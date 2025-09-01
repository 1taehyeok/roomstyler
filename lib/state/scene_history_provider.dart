// lib/state/scene_history_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roomstyler/core/models/scene.dart';

/// 씬(Scene)의 히스토리를 관리하여 Undo/Redo 기능을 제공하는 Riverpod Notifier입니다.
// --- 변경: Notifier의 타입 파라미터를 bool로 변경 ---
class SceneHistoryController extends Notifier<bool> {
  // Undo용 히스토리 스택
  final List<Scene> _undoStack = [];
  // Redo용 히스토리 스택
  final List<Scene> _redoStack = [];

  @override
  // --- 변경: build() 메소드의 반환 타입 및 내용 ---
  bool build() {
    // 초기 상태는 _undoStack이 비어있는지 여부
    return _undoStack.isNotEmpty;
  }

  /// 현재 씬 상태를 히스토리에 저장합니다.
  /// 새로운 작업이 발생했을 때 호출되어야 합니다.
  /// 이 메소드는 Undo 스택에 현재 상태를 추가하고, Redo 스택을 비웁니다.
  void push(Scene currentState) {
    // Undo 스택에 현재 상태 추가
    _undoStack.add(currentState);
    print('DEBUG: SceneHistoryController.push called. _undoStack length: ${_undoStack.length}');
    // 새로운 작업이 발생했으므로 Redo 스택은 무효화됩니다.
    _redoStack.clear();
    // --- 변경: state에 _undoStack이 비어있는지 여부를 할당하여 변경 알림 ---
    state = _undoStack.isNotEmpty;
    print('DEBUG: SceneHistoryController state updated to: $state');
  }

  /// 마지막 작업을 되돌립니다 (Undo).
  /// [current]는 되돌리기 직전의 현재 상태로, Redo 스택에 저장됩니다.
  /// 성공하면 되돌릴 상태를 반환하고, 실패하면 null을 반환합니다.
  Scene? undo(Scene current) {
    if (_undoStack.isEmpty) {
      return null; // 되돌릴 상태가 없음
    }
    // Undo 스택에서 상태를 꺼냄
    final previousState = _undoStack.removeLast();
    // 현재 상태를 Redo 스택에 저장하여 다시 실행 시 복구 가능하게 함
    _redoStack.add(current);
    // --- 변경: state에 _undoStack이 비어있는지 여부를 할당하여 변경 알림 ---
    state = _undoStack.isNotEmpty;
    return previousState;
  }

  /// 마지막 Undo 작업을 다시 실행합니다 (Redo).
  /// [current]는 Redo 직전의 현재 상태로, Undo 스택에 저장됩니다.
  /// 성공하면 다시 실행할 상태를 반환하고, 실패하면 null을 반환합니다.
  Scene? redo(Scene current) {
    if (_redoStack.isEmpty) {
      return null; // 다시 실행할 상태가 없음
    }
    // Redo 스택에서 상태를 꺼냄
    final nextState = _redoStack.removeLast();
    // 현재 상태를 Undo 스택에 저장하여 다시 실행 취소 가능하게 함
    _undoStack.add(current);
    // --- 변경: state에 _undoStack이 비어있는지 여부를 할당하여 변경 알림 ---
    state = _undoStack.isNotEmpty;
    return nextState;
  }

  /// Undo가 가능한지 여부를 반환합니다.
  bool get canUndo {
    final result = _undoStack.isNotEmpty;
    print('DEBUG: SceneHistoryController.canUndo called, returning: $result, _undoStack.length: ${_undoStack.length}');
    return result;
  }

  /// Redo가 가능한지 여부를 반환합니다.
  bool get canRedo => _redoStack.isNotEmpty;

  /// 히스토리를 모두 비웁니다. (예: 새로운 프로젝트 시작 시)
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    // --- 변경: state에 _undoStack이 비어있는지 여부를 할당하여 변경 알림 ---
    state = _undoStack.isNotEmpty;
  }
}

// Riverpod Provider 정의
// --- 변경: Provider의 타입을 bool로 변경 ---
final sceneHistoryProvider = NotifierProvider<SceneHistoryController, bool>(() {
  return SceneHistoryController();
});