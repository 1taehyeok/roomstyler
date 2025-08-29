class Furniture {
  final String id;      // firestore doc id or furniture_id
  final String sku;
  final String name;
  final String category;
  final int width;
  final int depth;
  final int height;
  final String color;
  final String material;
  final double price;
  final String? imageUrl;
  final String? affiliateUrl;
  // --- 로컬 이미지 관련 필드 추가 ---
  final bool isLocalImage;
  final String? localImagePath;
  // --- 끝 ---

  Furniture({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.width,
    required this.depth,
    required this.height,
    required this.color,
    required this.material,
    required this.price,
    this.imageUrl,
    this.affiliateUrl,
    // --- 로컬 이미지 관련 필드 추가 ---
    this.isLocalImage = false,
    this.localImagePath,
    // --- 끝 ---
  });

  factory Furniture.fromJson(Map<String, dynamic> json, String id) {
    // json에서 필드 값을 가져올 때, null일 경우 기본값을 제공
    return Furniture(
      id: id,
      sku: json['sku'] ?? '', // sku가 null이면 빈 문자열
      name: json['name'] ?? '이름 없음', // name이 null이면 '이름 없음'
      category: json['category'] ?? '기타', // category가 null이면 '기타'
      width: json['size_width'] ?? 0, // size_width가 null이면 0
      depth: json['size_depth'] ?? 0, // size_depth가 null이면 0
      height: json['size_height'] ?? 0, // size_height가 null이면 0
      color: json['color'] ?? '', // color가 null이면 빈 문자열
      material: json['material'] ?? '', // material이 null이면 빈 문자열
      price: (json['price'] as num?)?.toDouble() ?? 0.0, // price가 null이면 0.0
      imageUrl: json['imageUrl'], // imageUrl은 null 허용
      affiliateUrl: json['affiliate_url'], // affiliateUrl은 null 허용
      // --- 로컬 이미지 관련 필드 추가 ---
      isLocalImage: json['isLocalImage'] ?? false, // isLocalImage가 null이면 false
      localImagePath: json['localImagePath'], // localImagePath는 null 허용
      // --- 끝 ---
    );
  }

  Map<String, dynamic> toJson() => {
    'sku': sku,
    'name': name,
    'category': category,
    'size_width': width,
    'size_depth': depth,
    'size_height': height,
    'color': color,
    'material': material,
    'price': price,
    'imageUrl': imageUrl, // 필드명을 'imageUrl'로 변경 (Firestore에 저장될 때)
    'affiliate_url': affiliateUrl,
    // --- 로컬 이미지 관련 필드 추가 ---
    'isLocalImage': isLocalImage,
    'localImagePath': localImagePath,
    // --- 끝 ---
  };
}
