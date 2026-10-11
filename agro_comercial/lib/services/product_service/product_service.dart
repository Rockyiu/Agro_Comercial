import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/photo_change.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/services/firestore_batches.dart';
import 'package:agro_comercial/services/local_media_service/local_media_service.dart';

// Produtos (insumos) do estoque. A foto fica só no aparelho.
class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalMediaService _media;

  ProductService(this._media);

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  Future<void> createProduct(ProductModel product, {PhotoChange? photo}) async {
    final docRef = _products.doc();
    final map = product.copyWith(id: docRef.id).toMap()
      ..['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    await docRef.set(map);

    await _media.applyPhotoChange(MediaKind.product, docRef.id, photo);
  }

  // Toda consulta filtra pela fazenda: é o que as regras do Firestore usam
  // para liberar a leitura
  Future<List<ProductModel>> getProductsByFarm(String farmId) =>
      _query(_products.where('farmId', isEqualTo: farmId));

  Future<List<ProductModel>> getProductsByWarehouse({
    required String farmId,
    required String warehouseId,
  }) => _query(
    _products
        .where('farmId', isEqualTo: farmId)
        .where('warehouseId', isEqualTo: warehouseId),
  );

  Future<List<ProductModel>> _query(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ProductModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // [updateQuantity]: o estoque só é gravado se foi alterado no formulário.
  // Ele também muda pelas operações (incremento), e regravar o valor que
  // estava na tela apagaria as baixas feitas nesse meio-tempo.
  Future<void> updateProduct(
    ProductModel product, {
    required bool updateQuantity,
    PhotoChange? photo,
  }) async {
    await _products.doc(product.id).update({
      'name': product.name,
      'brand': product.brand,
      if (updateQuantity) 'quantity': product.quantity,
      'measure': product.measure,
      'unit': product.unit,
      'category': product.category,
      'attributes': product.attributes,
      'unitPrice': product.unitPrice,
    });
    await _media.applyPhotoChange(MediaKind.product, product.id!, photo);
  }

  Future<void> deleteProduct(String productId) =>
      deleteMultipleProducts([productId]);

  Future<void> deleteMultipleProducts(List<String> productIds) async {
    await commitInBatches(
      _firestore,
      productIds.map(
        (id) =>
            (batch) => batch.delete(_products.doc(id)),
      ),
    );
    await _media.deleteImages(MediaKind.product, productIds);
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
