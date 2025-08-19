class Room {
  final String id;
  final String userId;
  final String? imageUrl;
  final int? width;
  final int? length;
  final int? height;
  final Map<String, dynamic>? cameraIntrinsics;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.userId,
    this.imageUrl,
    this.width,
    this.length,
    this.height,
    this.cameraIntrinsics,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Room.fromJson(Map<String, dynamic> json, String id) => Room(
    id: id,
    userId: json['user_id'],
    imageUrl: json['image_url'],
    width: json['width'],
    length: json['length'],
    height: json['height'],
    cameraIntrinsics: json['camera_intrinsics'],
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'image_url': imageUrl,
    'width': width,
    'length': length,
    'height': height,
    'camera_intrinsics': cameraIntrinsics,
    'created_at': createdAt.toIso8601String(),
  };
}
