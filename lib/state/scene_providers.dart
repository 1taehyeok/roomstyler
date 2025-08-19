import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/scene.dart';

final currentSceneProvider = StateNotifierProvider<SceneController, Scene>((ref) {
  return SceneController(Scene(
    id: 'temp',
    roomId: 'tempRoom',
    layout: [],
  ));
});

class SceneController extends StateNotifier<Scene> {
  SceneController(super.state);

  void addItem(SceneLayoutItem item) {
    state = Scene(
      id: state.id,
      roomId: state.roomId,
      layout: [...state.layout, item],
      removedFurnitureIds: state.removedFurnitureIds,
      addedFurnitureIds: [...state.addedFurnitureIds, item.furnitureId],
      renderParams: state.renderParams,
      outputUrl: state.outputUrl,
      createdAt: state.createdAt,
    );
  }

  void updateItem(int index, SceneLayoutItem newItem) {
    final list = [...state.layout];
    list[index] = newItem;
    state = Scene(
      id: state.id,
      roomId: state.roomId,
      layout: list,
      removedFurnitureIds: state.removedFurnitureIds,
      addedFurnitureIds: state.addedFurnitureIds,
      renderParams: state.renderParams,
      outputUrl: state.outputUrl,
      createdAt: state.createdAt,
    );
  }

  void removeItem(int index) {
    final list = [...state.layout]..removeAt(index);
    state = Scene(
      id: state.id,
      roomId: state.roomId,
      layout: list,
      removedFurnitureIds: state.removedFurnitureIds,
      addedFurnitureIds: state.addedFurnitureIds,
      renderParams: state.renderParams,
      outputUrl: state.outputUrl,
      createdAt: state.createdAt,
    );
  }

  void clear() {
    state = Scene(id: state.id, roomId: state.roomId, layout: []);
  }
}
