import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/field_operation_model.dart';

class FieldOperationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveFieldOperation(FieldOperationModel operation) async {
    final docRef = _firestore.collection('field_operations').doc();
    final opWithId = FieldOperationModel(
      id: docRef.id,
      type: operation.type,
      plotName: operation.plotName,
      dateTimestamp: operation.dateTimestamp,
      farmId: operation.farmId,
      createdBy: operation.createdBy,
      condition: operation.condition,
      observations: operation.observations,
      productId: operation.productId,
      productName: operation.productName,
      dosage: operation.dosage,
      dosageUnit: operation.dosageUnit,
      machineId: operation.machineId,
      machineName: operation.machineName,
      machineHours: operation.machineHours,
    );
    await docRef.set(opWithId.toMap());
  }

  Future<List<FieldOperationModel>> getFieldOperations(String farmId) async {
    final snapshot = await _firestore
        .collection('field_operations')
        .where('farmId', isEqualTo: farmId)
        .orderBy('dateTimestamp', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => FieldOperationModel.fromMap(doc.data()))
        .toList();
  }

  // Vistorias/aplicações registradas por um usuário específico na fazenda.
  // Só usa filtros de igualdade para não exigir índice composto no Firestore;
  // a ordenação é feita localmente.
  Future<List<FieldOperationModel>> getFieldOperationsByUser(
    String farmId,
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('field_operations')
        .where('farmId', isEqualTo: farmId)
        .where('createdBy', isEqualTo: userId)
        .get();
    final operations = snapshot.docs
        .map((doc) => FieldOperationModel.fromMap(doc.data()))
        .toList();
    operations.sort((a, b) => b.dateTimestamp.compareTo(a.dateTimestamp));
    return operations;
  }

  Future<void> updateFieldOperation(FieldOperationModel operation) async {
    await _firestore
        .collection('field_operations')
        .doc(operation.id)
        .update(operation.toMap());
  }

  Future<void> deleteFieldOperation(String id) async {
    await _firestore.collection('field_operations').doc(id).delete();
  }

  Future<void> deleteMultipleFieldOperations(List<String> ids) async {
    final batch = _firestore.batch();
    for (String id in ids) {
      batch.delete(_firestore.collection('field_operations').doc(id));
    }
    await batch.commit();
  }
}
