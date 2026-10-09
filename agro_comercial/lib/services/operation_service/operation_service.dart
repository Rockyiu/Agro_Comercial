import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/operation_model.dart';

class OperationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('operations');

  // Gravações dentro do lote do estoque (StockService.applyUsage), para a
  // operação e a baixa de estoque serem salvas juntas ou nenhuma delas
  void addCreateToBatch(WriteBatch batch, OperationModel operation) {
    final docRef = _collection.doc();
    batch.set(docRef, operation.copyWith(id: docRef.id).toMap());
  }

  void addUpdateToBatch(WriteBatch batch, OperationModel operation) {
    batch.update(_collection.doc(operation.id), operation.toMap());
  }

  void addDeleteToBatch(WriteBatch batch, Iterable<String> ids) {
    for (final id in ids) {
      batch.delete(_collection.doc(id));
    }
  }

  Future<List<OperationModel>> getOperations(String farmId) async {
    final snapshot = await _collection
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
    final snapshot = await _collection
        .where('farmId', isEqualTo: farmId)
        .where('createdBy', isEqualTo: userId)
        .get();
    final operations = snapshot.docs
        .map((doc) => OperationModel.fromMap(doc.data()))
        .toList();
    operations.sort((a, b) => b.dateTimestamp.compareTo(a.dateTimestamp));
    return operations;
  }
}
