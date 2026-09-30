import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/operation_model.dart';

class OperationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createOperation(OperationModel operation) async {
    final docRef = _firestore.collection('operations').doc();

    await docRef.set(operation.copyWith(id: docRef.id).toMap());
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

  // Operações registradas por um usuário específico (ex: colaborador) na fazenda.
  // Só usa filtros de igualdade para não exigir índice composto no Firestore;
  // a ordenação é feita localmente.
  Future<List<OperationModel>> getOperationsByUser(
    String farmId,
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('operations')
        .where('farmId', isEqualTo: farmId)
        .where('createdBy', isEqualTo: userId)
        .get();
    final operations = snapshot.docs
        .map((doc) => OperationModel.fromMap(doc.data()))
        .toList();
    operations.sort((a, b) => b.dateTimestamp.compareTo(a.dateTimestamp));
    return operations;
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
