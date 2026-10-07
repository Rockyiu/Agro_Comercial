class ProductModel {
  final String? id;
  final String name;
  final String brand;
  final double quantity;
  final double measure; // ADICIONADO: Tamanho da embalagem (Ex: 1 ou 1000)
  final String unit; // kg, L, un, ml, mg
  final String category;
  final String warehouseId;
  final String farmId;
  final String? imageUrl;
  final Map<String, dynamic> attributes;
  final double? unitPrice; // Preço por unidade do estoque (ex: R$ por L)

  ProductModel({
    this.id,
    required this.name,
    required this.brand,
    required this.quantity,
    required this.measure,
    required this.unit,
    required this.category,
    required this.warehouseId,
    required this.farmId,
    this.imageUrl,
    required this.attributes,
    this.unitPrice,
  });

  // Estoque total na unidade do produto (ex: 3 embalagens de 20 L = 60 L)
  double get totalStock => quantity * measure;

  // Princípio ativo / composição informado no cadastro (defensivos e adubos)
  String get formulation => attributes['campo_extra_1']?.toString() ?? '';

  ProductModel copyWith({
    String? id,
    String? name,
    String? brand,
    double? quantity,
    double? measure,
    String? unit,
    String? category,
    String? warehouseId,
    String? farmId,
    String? imageUrl,
    Map<String, dynamic>? attributes,
    double? unitPrice,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      quantity: quantity ?? this.quantity,
      measure: measure ?? this.measure,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      warehouseId: warehouseId ?? this.warehouseId,
      farmId: farmId ?? this.farmId,
      imageUrl: imageUrl ?? this.imageUrl,
      attributes: attributes ?? this.attributes,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'measure': measure,
      'unit': unit,
      'category': category,
      'warehouseId': warehouseId,
      'farmId': farmId,
      'imageUrl': imageUrl,
      'attributes': attributes,
      'unitPrice': unitPrice,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      measure: (map['measure'] ?? 1.0).toDouble(),
      unit: map['unit'] ?? 'un',
      category: map['category'] ?? '',
      warehouseId: map['warehouseId'] ?? '',
      farmId: map['farmId'] ?? '',
      imageUrl: map['imageUrl'],
      attributes: Map<String, dynamic>.from(map['attributes'] ?? {}),
      unitPrice: (map['unitPrice'] as num?)?.toDouble(),
    );
  }
}
