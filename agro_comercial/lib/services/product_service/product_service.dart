import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createProduct(ProductModel product, File? imageFile) async {
    final docRef = _firestore.collection('products').doc();

    // Upload de imagem desativado temporariamente devido ao plano Spark
    final map = product.copyWith(id: docRef.id).toMap()..['imageUrl'] = null;
    map['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    await docRef.set(map);
  }

  // Toda consulta filtra pela fazenda: é o que as regras do Firestore usam
  // para liberar a leitura
  Future<List<ProductModel>> getProductsByFarm(String farmId) => _query(
    _firestore.collection('products').where('farmId', isEqualTo: farmId),
  );

  Future<List<ProductModel>> getProductsByWarehouse({
    required String farmId,
    required String warehouseId,
  }) => _query(
    _firestore
        .collection('products')
        .where('farmId', isEqualTo: farmId)
        .where('warehouseId', isEqualTo: warehouseId),
  );

  Future<List<ProductModel>> _query(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> updateProduct(ProductModel product, File? newImageFile) async {
    await _firestore.collection('products').doc(product.id).update({
      'name': product.name,
      'brand': product.brand,
      'quantity': product.quantity,
      'measure': product.measure,
      'unit': product.unit,
      'category': product.category,
      'attributes': product.attributes,
      'unitPrice': product.unitPrice,
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  Future<void> deleteMultipleProducts(List<String> productIds) async {
    final batch = _firestore.batch();
    for (String id in productIds) {
      batch.delete(_firestore.collection('products').doc(id));
    }
    await batch.commit();
  }

  // Já existe outro produto com o mesmo nome e marca neste armazém?
  // A comparação ignora maiúsculas/minúsculas e espaços nas pontas
  // ("Glifosato" == " glifosato"). [ignoreId]: o próprio produto, na edição.
  Future<bool> checkDuplicateProduct(
    String name,
    String brand, {
    required String farmId,
    required String warehouseId,
    String? ignoreId,
  }) async {
    String normalize(String value) => value.trim().toLowerCase();

    final products = await getProductsByWarehouse(
      farmId: farmId,
      warehouseId: warehouseId,
    );
    return products.any(
      (p) =>
          p.id != ignoreId &&
          normalize(p.name) == normalize(name) &&
          normalize(p.brand) == normalize(brand),
    );
  }
}
