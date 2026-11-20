class FarmerStockModel {
  final String? id;
  final String farmerId;
  final String itemId;
  final double price;
  final double stockQuantity;
  final bool isAvailable;
  final String? itemName;
  final String? itemUnit;
  final String? categoryName;
  final String? imageUrl;

  FarmerStockModel({
    this.id,
    required this.farmerId,
    required this.itemId,
    required this.price,
    required this.stockQuantity,
    this.isAvailable = true,
    this.itemName,
    this.itemUnit,
    this.categoryName,
    this.imageUrl,
  });

  factory FarmerStockModel.fromJson(Map<String, dynamic> json) {
    final masterItem = json['master_items'];
    final category = masterItem is Map ? masterItem['categories'] : null;

    return FarmerStockModel(
      id: json['id'],
      farmerId: json['farmer_id'] ?? '',
      itemId: json['item_id'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (json['stock_quantity'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['is_available'] ?? true,
      itemName: masterItem is Map ? masterItem['name'] : null,
      itemUnit: masterItem is Map ? masterItem['unit'] : null,
      categoryName: category is Map ? category['name'] : null,
      imageUrl: masterItem is Map ? masterItem['image_url'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmer_id': farmerId,
      'item_id': itemId,
      'price': price,
      'stock_quantity': stockQuantity,
      'is_available': isAvailable,
    };
  }
}
