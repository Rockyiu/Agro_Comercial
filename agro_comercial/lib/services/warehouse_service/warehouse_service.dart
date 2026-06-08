import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';

class WarehouseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Função para criar um novo armazém
  Future<void> createWarehouse(WarehouseModel warehouse) async {
    final docRef = _firestore.collection('warehouses').doc();

    final warehouseWithId = WarehouseModel(
      id: docRef.id,
      name: warehouse.name,
      farmId: warehouse.farmId,
    );

    // MUDANÇA AQUI: Criamos um Map e adicionamos o 'createdAt' com a hora exata
    final map = warehouseWithId.toMap();
    map['createdAt'] = DateTime.now().millisecondsSinceEpoch;

    await docRef.set(map);
  }

  // Função para buscar e ordenar os armazéns
  Future<List<WarehouseModel>> getWarehouses(String farmId) async {
    final snapshot = await _firestore
        .collection('warehouses')
        .where('farmId', isEqualTo: farmId)
        .get();

    final docs = snapshot.docs;

    // MUDANÇA AQUI: Ordena a lista localmente.
    // Compara o tempo de criação de A com B (do menor para o maior)
    docs.sort((a, b) {
      final timeA = a.data()['createdAt'] ?? 0;
      final timeB = b.data()['createdAt'] ?? 0;
      // Invertemos a ordem: b.compareTo(a) em vez de a.compareTo(b)
      return timeB.compareTo(timeA);
    });

    return docs.map((doc) => WarehouseModel.fromMap(doc.data())).toList();
  }

  Future<void> updateWarehouse(WarehouseModel warehouse) async {
    await _firestore.collection('warehouses').doc(warehouse.id).update({
      'name': warehouse.name,
    });
  }

  Future<void> deleteWarehouseAndContents(String warehouseId) async {
    final batch = _firestore.batch();

    // 1. Deleta o Armazém
    batch.delete(_firestore.collection('warehouses').doc(warehouseId));

    // 2. Busca e deleta as Máquinas do armazém
    final machines = await _firestore
        .collection('machines')
        .where('warehouseId', isEqualTo: warehouseId)
        .get();
    for (var doc in machines.docs) {
      batch.delete(doc.reference);
    }

    // 3. NOVO: Busca e deleta os Produtos do armazém
    final products = await _firestore
        .collection('products')
        .where('warehouseId', isEqualTo: warehouseId)
        .get();
    for (var doc in products.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Função nova para excluir vários armazéns de uma vez (Seleção Múltipla)
  Future<void> deleteMultipleWarehouses(List<String> warehouseIds) async {
    final batch = _firestore.batch();

    for (String id in warehouseIds) {
      batch.delete(_firestore.collection('warehouses').doc(id));

      final machines = await _firestore
          .collection('machines')
          .where('warehouseId', isEqualTo: id)
          .get();
      for (var doc in machines.docs) {
        batch.delete(doc.reference);
      }

      // NOVO: Cascata de múltiplos armazéns para produtos
      final products = await _firestore
          .collection('products')
          .where('warehouseId', isEqualTo: id)
          .get();
      for (var doc in products.docs) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }
}
