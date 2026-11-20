class MasterItemModel {
  final String? id;
  final String name;
  final String categoryId;
  final String?
  categoryName; // UI එකේ පෙන්වීමට (Join query හරහා ලැබේ)[cite: 12]
  final String unit;
  final String? imageUrl;

  MasterItemModel({
    this.id,
    required this.name,
    required this.categoryId,
    this.categoryName,
    required this.unit,
    this.imageUrl,
  });

  factory MasterItemModel.fromJson(Map<String, dynamic> json) {
    return MasterItemModel(
      id: json['id'],
      name: json['name'] ?? '',
      categoryId: json['category_id'] ?? '',
      // Supabase join query එකකින් 'categories': {'name': 'Vegetable'} ලෙස ලැබෙන විට[cite: 12]
      categoryName: json['categories'] != null
          ? json['categories']['name']
          : null,
      unit: json['unit'] ?? 'kg',
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category_id': categoryId,
      'unit': unit,
      'image_url': imageUrl,
    };
  }
}
