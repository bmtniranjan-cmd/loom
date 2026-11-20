class CartItemModel {
  final String id;
  final String customerId;
  final String stockId;
  final String farmerId;
  final String itemId;
  final double quantity;
  final double unitPrice;
  final String? itemName;
  final String? itemUnit;
  final String? imageUrl;

  CartItemModel({
    required this.id,
    required this.customerId,
    required this.stockId,
    required this.farmerId,
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    this.itemName,
    this.itemUnit,
    this.imageUrl,
  });

  double get totalPrice => quantity * unitPrice;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final masterItem = json['master_items'];

    return CartItemModel(
      id: json['id'].toString(),
      customerId: json['customer_id'] ?? '',
      stockId: json['stock_id'] ?? '',
      farmerId: json['farmer_id'] ?? '',
      itemId: json['item_id'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      itemName: masterItem is Map ? masterItem['name'] : null,
      itemUnit: masterItem is Map ? masterItem['unit'] : null,
      imageUrl: masterItem is Map ? masterItem['image_url'] : null,
    );
  }
}
