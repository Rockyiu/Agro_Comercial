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

  Future<void> deleteWarehouseAndContents(WarehouseModel warehouse) =>
      deleteMultipleWarehouses(warehouse.farmId, [warehouse.id!]);

  // Exclui os armazéns junto com as máquinas e produtos de cada um (cascata),
  // tudo em um único lote
  Future<void> deleteMultipleWarehouses(
    String farmId,
    List<String> warehouseIds,
  ) async {
    Future<List<DocumentReference>> contents(
      String collection,
      String id,
    ) async {
      final snapshot = await _firestore
          .collection(collection)
          .where('farmId', isEqualTo: farmId)
          .where('warehouseId', isEqualTo: id)
          .get();
      return snapshot.docs.map((doc) => doc.reference).toList();
    }

    final refs = await Future.wait([
      for (final id in warehouseIds) ...[
        contents('machines', id),
        contents('products', id),
      ],
    ]);

    final batch = _firestore.batch();
    for (final ref in refs.expand((list) => list)) {
      batch.delete(ref);
    }
    for (final id in warehouseIds) {
      batch.delete(_firestore.collection('warehouses').doc(id));
    }
    await batch.commit();
  }
}
