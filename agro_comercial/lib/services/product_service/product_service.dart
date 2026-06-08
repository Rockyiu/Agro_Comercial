import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createProduct(ProductModel product, File? imageFile) async {
    final docRef = _firestore.collection('products').doc();

    // NOTA: Upload de imagem desativado temporariamente devido ao plano Spark do Storage
    final productWithId = ProductModel(
      id: docRef.id,
      name: product.name,
      brand: product.brand,
      quantity: product.quantity,
      unit: product.unit,
      category: product.category,
      warehouseId: product.warehouseId,
      farmId: product.farmId,
      imageUrl: null,
      attributes: product.attributes,
    );

    final map = productWithId.toMap();
    map['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    await docRef.set(map);
  }

  Future<List<ProductModel>> getProductsByWarehouse(String warehouseId) async {
    final snapshot = await _firestore
        .collection('products')
        .where('warehouseId', isEqualTo: warehouseId)
        .get();
    return snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> updateProduct(ProductModel product, File? newImageFile) async {
    await _firestore.collection('products').doc(product.id).update({
      'name': product.name,
      'brand': product.brand,
      'quantity': product.quantity,
      'unit': product.unit,
      'category': product.category,
      'attributes': product.attributes,
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

  Future<bool> checkDuplicateProduct(
    String name,
    String brand,
    String warehouseId,
  ) async {
    final snapshot = await _firestore
        .collection('products')
        .where('warehouseId', isEqualTo: warehouseId)
        .where('name', isEqualTo: name)
        .where('brand', isEqualTo: brand)
        .get();

    return snapshot.docs.isNotEmpty; // Retorna true se achar algum igual
  }
}
