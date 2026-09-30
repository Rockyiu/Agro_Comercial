import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';

class WarehouseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Função para criar um novo armazém
  Future<void> createWarehouse(WarehouseModel warehouse) async {
    final docRef = _firestore.collection('warehouses').doc();

    final map = warehouse.copyWith(id: docRef.id).toMap();
    map['createdAt'] = DateTime.now().millisecondsSinceEpoch;

    await docRef.set(map);
  }

  // Função para buscar e ordenar os armazéns
  Future<List<WarehouseModel>> getWarehouses(String farmId) async {
    final snapshot = await _firestore
        .collection('warehouses')
        .where('farmId', isEqualTo: farmId)
        .get();

    // Ordena localmente, do mais novo para o mais antigo
    final docs = snapshot.docs
      ..sort((a, b) {
        final int timeA = a.data()['createdAt'] ?? 0;
        final int timeB = b.data()['createdAt'] ?? 0;
        return timeB.compareTo(timeA);
      });

    return docs.map((doc) => WarehouseModel.fromMap(doc.data())).toList();
  }

  Future<void> updateWarehouse(WarehouseModel warehouse) async {
    await _firestore.collection('warehouses').doc(warehouse.id).update({
      'name': warehouse.name,
    });
  }

  Future<void> deleteWarehouseAndContents(String warehouseId) =>
      deleteMultipleWarehouses([warehouseId]);

  // Exclui os armazéns junto com as máquinas e produtos de cada um (cascata)
  Future<void> deleteMultipleWarehouses(List<String> warehouseIds) async {
    final batch = _firestore.batch();

    for (final id in warehouseIds) {
      batch.delete(_firestore.collection('warehouses').doc(id));

      final (machines, products) = await (
        _firestore
            .collection('machines')
            .where('warehouseId', isEqualTo: id)
            .get(),
        _firestore
            .collection('products')
            .where('warehouseId', isEqualTo: id)
            .get(),
      ).wait;

      for (final doc in [...machines.docs, ...products.docs]) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }
}
