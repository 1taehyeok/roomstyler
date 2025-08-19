class SceneLayoutItem {
  final String furnitureId;
  final double x; // 0..1 (상대 좌표)
  final double y; // 0..1
  final double scale; // 배율
  final double rotation; // 라디안

  SceneLayoutItem({
    required this.furnitureId,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  factory SceneLayoutItem.fromJson(Map<String, dynamic> j) => SceneLayoutItem(
    furnitureId: j['furniture_id'],
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    scale: (j['scale'] as num?)?.toDouble() ?? 1.0,
    rotation: (j['rotation'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    'furniture_id': furnitureId,
    'x': x, 'y': y,
    'scale': scale,
    'rotation': rotation,
  };
}

class Scene {
  final String id;
  final String roomId;
  final List<SceneLayoutItem> layout;
  final List<String> removedFurnitureIds;
  final List<String> addedFurnitureIds;
  final Map<String, dynamic>? renderParams;
  final String? outputUrl;
  final DateTime createdAt;

  Scene({
    required this.id,
    required this.roomId,
    required this.layout,
    this.removedFurnitureIds = const [],
    this.addedFurnitureIds = const [],
    this.renderParams,
    this.outputUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Scene.fromJson(Map<String, dynamic> json, String id) => Scene(
    id: id,
    roomId: json['room_id'],
    layout: ((json['layout'] ?? []) as List)
      .map((e) => SceneLayoutItem.fromJson(Map<String,dynamic>.from(e))).toList(),
    removedFurnitureIds: (json['removed_furniture_ids'] ?? []).cast<String>(),
    addedFurnitureIds: (json['added_furniture_ids'] ?? []).cast<String>(),
    renderParams: json['render_params'],
    outputUrl: json['output_url'],
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'room_id': roomId,
    'layout': layout.map((e) => e.toJson()).toList(),
    'removed_furniture_ids': removedFurnitureIds,
    'added_furniture_ids': addedFurnitureIds,
    'render_params': renderParams,
    'output_url': outputUrl,
    'created_at': createdAt.toIso8601String(),
  };
}
