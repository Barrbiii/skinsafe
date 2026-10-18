class ScanHistory {
  final int? id;
  final int userId;
  final String brand;
  final String productType;
  final String composition;
  final bool isSafe;
  final DateTime createdAt;
  final String? imagePath;

  ScanHistory({
    this.id,
    required this.userId,
    required this.brand,
    required this.productType,
    required this.composition,
    required this.isSafe,
    required this.createdAt,
    this.imagePath,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'brand': brand,
      'product_type': productType,
      'composition': composition,
      'is_safe': isSafe ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'image_path': imagePath,
    };
  }

  factory ScanHistory.fromMap(Map<String, Object?> map) {
    return ScanHistory(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      brand: map['brand'] as String,
      productType: map['product_type'] as String,
      composition: map['composition'] as String,
      isSafe: (map['is_safe'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      imagePath: map['image_path'] as String?,
    );
  }
}