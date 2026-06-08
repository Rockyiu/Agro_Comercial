class ProductModel {
  final String? id;
  final String name;
  final String brand;
  final double quantity;
  final String unit; // kg, L, un, metros, etc.
  final String category;
  final String warehouseId;
  final String farmId;
  final String? imageUrl;
  final Map<String, dynamic>
  attributes; // Guarda os campos dinâmicos de cada categoria

  ProductModel({
    this.id,
    required this.name,
    required this.brand,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.warehouseId,
    required this.farmId,
    this.imageUrl,
    required this.attributes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'warehouseId': warehouseId,
      'farmId': farmId,
      'imageUrl': imageUrl,
      'attributes': attributes,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'un',
      category: map['category'] ?? '',
      warehouseId: map['warehouseId'] ?? '',
      farmId: map['farmId'] ?? '',
      imageUrl: map['imageUrl'],
      attributes: Map<String, dynamic>.from(map['attributes'] ?? {}),
    );
  }
}
