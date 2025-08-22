// lib/state/scene_history_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roomstyler/core/models/scene.dart';

/// 씬(Scene)의 히스토리를 관리하여 Undo/Redo 기능을 제공하는 Riverpod Notifier입니다.
class SceneHistoryController extends Notifier<List<Scene>> {
  // Undo용 히스토리 스택
  final List<Scene> _undoStack = [];
  // Redo용 히스토리 스택
  final List<Scene> _redoStack = [];

  @override
  List<Scene> build() {
    // 초기 상태는 빈 리스트
    return [];
  }

  /// 현재 씬 상태를 히스토리에 저장합니다.
  /// 새로운 작업이 발생했을 때 호출되어야 합니다.
  /// 이 메소드는 Undo 스택에 현재 상태를 추가하고, Redo 스택을 비웁니다.
  void push(Scene currentState) {
    // Undo 스택에 현재 상태 추가
    _undoStack.add(currentState);
    // 새로운 작업이 발생했으므로 Redo 스택은 무효화됩니다.
    _redoStack.clear();
    // 상태가 변경되었음을 Provider에 알림 (빌드 재호출)
    state = [..._undoStack]; // state는 단순히 업데이트 여부를 알리기 위한 용도로 사용
  }

  /// 마지막 작업을 되돌립니다 (Undo).
  /// 성공하면 되돌릴 상태를 반환하고, 실패하면 null을 반환합니다.
  Scene? undo() {
    if (_undoStack.isEmpty) {
      return null; // 되돌릴 상태가 없음
    }
    // Undo 스택에서 상태를 꺼냄
    final undoneState = _undoStack.removeLast();
    // 꺼낸 상태를 Redo 스택에 저장
    _redoStack.add(undoneState);
    // 상태가 변경되었음을 Provider에 알림
    state = [..._undoStack];
    return undoneState;
  }

  /// 마지막 Undo 작업을 다시 실행합니다 (Redo).
  /// 성공하면 다시 실행할 상태를 반환하고, 실패하면 null을 반환합니다.
  Scene? redo() {
    if (_redoStack.isEmpty) {
      return null; // 다시 실행할 상태가 없음
    }
    // Redo 스택에서 상태를 꺼냄
    final redoneState = _redoStack.removeLast();
    // 꺼낸 상태를 Undo 스택에 저장
    _undoStack.add(redoneState);
    // 상태가 변경되었음을 Provider에 알림
    state = [..._undoStack];
    return redoneState;
  }

  /// Undo가 가능한지 여부를 반환합니다.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Redo가 가능한지 여부를 반환합니다.
  bool get canRedo => _redoStack.isNotEmpty;

  /// 히스토리를 모두 비웁니다. (예: 새로운 프로젝트 시작 시)
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    state = [];
  }
}

// Riverpod Provider 정의
final sceneHistoryProvider = NotifierProvider<SceneHistoryController, List<Scene>>(() {
  return SceneHistoryController();
});