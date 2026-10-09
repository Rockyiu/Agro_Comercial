import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/field_operation_model.dart';

class FieldOperationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('field_operations');

  // Gravações dentro do lote do estoque (StockService.applyUsage), para o
  // lançamento e a baixa de estoque serem salvos juntos ou nenhum deles
  void addCreateToBatch(WriteBatch batch, FieldOperationModel operation) {
    final docRef = _collection.doc();
    batch.set(docRef, operation.copyWith(id: docRef.id).toMap());
  }

  void addUpdateToBatch(WriteBatch batch, FieldOperationModel operation) {
    batch.update(_collection.doc(operation.id), operation.toMap());
  }

  void addDeleteToBatch(WriteBatch batch, Iterable<String> ids) {
    for (final id in ids) {
      batch.delete(_collection.doc(id));
    }
  }

  Future<List<FieldOperationModel>> getFieldOperations(String farmId) async {
    final snapshot = await _collection
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
    final snapshot = await _collection
        .where('farmId', isEqualTo: farmId)
        .where('createdBy', isEqualTo: userId)
        .get();
    final operations = snapshot.docs
        .map((doc) => FieldOperationModel.fromMap(doc.data()))
        .toList();
    operations.sort((a, b) => b.dateTimestamp.compareTo(a.dateTimestamp));
    return operations;
  }
}
