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
  });

  factory Furniture.fromJson(Map<String, dynamic> json, String id) => Furniture(
    id: id,
    sku: json['sku'],
    name: json['name'],
    category: json['category'],
    width: json['size_width'],
    depth: json['size_depth'],
    height: json['size_height'],
    color: json['color'],
    material: json['material'],
    price: (json['price'] as num).toDouble(),
    imageUrl: json['image_url'],
    affiliateUrl: json['affiliate_url'],
  );

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
    'image_url': imageUrl,
    'affiliate_url': affiliateUrl,
  };
}
