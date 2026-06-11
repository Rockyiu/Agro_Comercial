import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/operation_model.dart';

class OperationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createOperation(OperationModel operation) async {
    final docRef = _firestore.collection('operations').doc();

    final operationWithId = OperationModel(
      id: docRef.id,
      title: operation.title,
      description: operation.description,
      farmId: operation.farmId,
      dateTimestamp: operation.dateTimestamp,
      usedMachine: operation.usedMachine,
      machineId: operation.machineId,
      machineName: operation.machineName,
      machineHours: operation.machineHours,
      usedProducts: operation.usedProducts,
      appliedProducts: operation.appliedProducts,
    );

    await docRef.set(operationWithId.toMap());
  }

  Future<List<OperationModel>> getOperations(String farmId) async {
    final snapshot = await _firestore
        .collection('operations')
        .where('farmId', isEqualTo: farmId)
        .orderBy('dateTimestamp', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => OperationModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> updateOperation(OperationModel operation) async {
    await _firestore
        .collection('operations')
        .doc(operation.id)
        .update(operation.toMap());
  }

  Future<void> deleteOperation(String operationId) async {
    await _firestore.collection('operations').doc(operationId).delete();
  }

  Future<void> deleteMultipleOperations(List<String> ids) async {
    final batch = _firestore.batch();
    for (String id in ids) {
      batch.delete(_firestore.collection('operations').doc(id));
    }
    await batch.commit();
  }
}
