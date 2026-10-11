import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';
import 'package:agro_comercial/services/firestore_batches.dart';
import 'package:agro_comercial/services/local_media_service/local_media_service.dart';

class WarehouseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalMediaService _media;

  WarehouseService(this._media);

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

  // Exclui os armazéns junto com as máquinas e produtos de cada um (cascata).
  // Os conteúdos vão primeiro: se algo falhar no meio, o armazém continua lá
  // e a exclusão pode ser repetida.
  Future<void> deleteMultipleWarehouses(
    String farmId,
    List<String> warehouseIds,
  ) async {
    Future<List<DocumentReference<Map<String, dynamic>>>> contents(
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

    final (machines, products) = await (
      Future.wait([for (final id in warehouseIds) contents('machines', id)]),
      Future.wait([for (final id in warehouseIds) contents('products', id)]),
    ).wait;
    final machineRefs = machines.expand((list) => list).toList();
    final productRefs = products.expand((list) => list).toList();

    await commitInBatches(_firestore, [
      for (final ref in [...machineRefs, ...productRefs])
        (batch) => batch.delete(ref),
      // Custo da hora-máquina (machine_costs usa o mesmo id da máquina)
      for (final ref in machineRefs)
        (batch) =>
            batch.delete(_firestore.collection('machine_costs').doc(ref.id)),
      for (final id in warehouseIds)
        (batch) => batch.delete(_firestore.collection('warehouses').doc(id)),
    ]);

    await _media.deleteImages(
      MediaKind.machine,
      machineRefs.map((ref) => ref.id),
    );
    await _media.deleteImages(
      MediaKind.product,
      productRefs.map((ref) => ref.id),
    );
  }
}
