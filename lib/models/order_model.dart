class OrderModel {
  final String? id;
  final String customerId;
  final String farmerId;
  final String itemId;
  final double quantity;
  final double totalPrice;
  final String status;
  final String? createdAt;

  // UI එකේ පෙන්වීම සඳහා (Join queries හරහා)
  final String? itemName;
  final String? itemUnit;

  OrderModel({
    this.id,
    required this.customerId,
    required this.farmerId,
    required this.itemId,
    required this.quantity,
    required this.totalPrice,
    this.status = 'Pending',
    this.createdAt,
    this.itemName,
    this.itemUnit,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemInfo = json['master_items'];

    return OrderModel(
      id: json['id'],
      customerId: json['customer_id'] ?? '',
      farmerId: json['farmer_id'] ?? '',
      itemId: json['item_id'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Pending',
      createdAt: json['created_at'],
      itemName: itemInfo != null ? itemInfo['name'] : null,
      itemUnit: itemInfo != null ? itemInfo['unit'] : 'kg',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'farmer_id': farmerId,
      'item_id': itemId,
      'quantity': quantity,
      'total_price': totalPrice,
      'status': status,
    };
  }
}
