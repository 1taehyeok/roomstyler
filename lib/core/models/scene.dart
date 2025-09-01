class SceneLayoutItem {
  final String furnitureId;
  final String name; // Add name
  final String? imageUrl; // Add imageUrl
  final double x; // 0..1 (상대 좌표)
  final double y; // 0..1
  final double scale; // 배율
  final double rotation; // 라디안

  SceneLayoutItem({
    required this.furnitureId,
    required this.name,
    this.imageUrl,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  factory SceneLayoutItem.fromJson(Map<String, dynamic> j) => SceneLayoutItem(
    furnitureId: j['furniture_id'],
    name: j['name'],
    imageUrl: j['image_url'],
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    scale: (j['scale'] as num?)?.toDouble() ?? 1.0,
    rotation: (j['rotation'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    'furniture_id': furnitureId,
    'name': name,
    'image_url': imageUrl,
    'x': x, 'y': y,
    'scale': scale,
    'rotation': rotation,
  };

  // 누락되었던 copyWith 메소드
  SceneLayoutItem copyWith({
    String? furnitureId,
    String? name,
    String? imageUrl,
    double? x,
    double? y,
    double? scale,
    double? rotation,
  }) {
    return SceneLayoutItem(
      furnitureId: furnitureId ?? this.furnitureId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}

class Scene {
  final String id;
  final String? userId;
  final String roomId;
  final List<SceneLayoutItem> layout;
  final List<String> removedFurnitureIds;
  final List<String> addedFurnitureIds;
  final Map<String, dynamic>? renderParams;
  final String? outputUrl;
  final DateTime createdAt;
  final String? customName; // Add customName field

  Scene({
    required this.id,
    this.userId,
    required this.roomId,
    required this.layout,
    this.removedFurnitureIds = const [],
    this.addedFurnitureIds = const [],
    this.renderParams,
    this.outputUrl,
    DateTime? createdAt,
    this.customName, // Add customName to constructor
  }) : createdAt = createdAt ?? DateTime.now();

  factory Scene.fromJson(Map<String, dynamic> json, String id) => Scene(
    id: id,
    userId: json['user_id'],
    roomId: json['room_id'],
    layout: ((json['layout'] ?? []) as List)
      .map((e) => SceneLayoutItem.fromJson(Map<String,dynamic>.from(e))).toList(),
    removedFurnitureIds: (json['removed_furniture_ids'] ?? []).cast<String>(),
    addedFurnitureIds: (json['added_furniture_ids'] ?? []).cast<String>(),
    renderParams: json['render_params'],
    outputUrl: json['output_url'],
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    customName: json['custom_name'], // Add customName to fromJson
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'room_id': roomId,
    'layout': layout.map((e) => e.toJson()).toList(),
    'removed_furniture_ids': removedFurnitureIds,
    'added_furniture_ids': addedFurnitureIds,
    'render_params': renderParams,
    'output_url': outputUrl,
    'created_at': createdAt.toIso8601String(),
    'custom_name': customName, // Add customName to toJson
  };

  Scene copyWith({
    String? id,
    String? userId,
    String? roomId,
    List<SceneLayoutItem>? layout,
    List<String>? removedFurnitureIds,
    List<String>? addedFurnitureIds,
    Map<String, dynamic>? renderParams,
    String? outputUrl,
    DateTime? createdAt,
    String? customName, // Add customName to copyWith
  }) {
    return Scene(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      layout: layout ?? this.layout,
      removedFurnitureIds: removedFurnitureIds ?? this.removedFurnitureIds,
      addedFurnitureIds: addedFurnitureIds ?? this.addedFurnitureIds,
      renderParams: renderParams ?? this.renderParams,
      outputUrl: outputUrl ?? this.outputUrl,
      createdAt: createdAt ?? this.createdAt,
      customName: customName ?? this.customName, // Add customName to copyWith
    );
  }
}
