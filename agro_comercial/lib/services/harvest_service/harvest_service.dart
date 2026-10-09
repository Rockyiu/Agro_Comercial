import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/harvest_model.dart';

class HarvestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createHarvest(HarvestModel harvest) async {
    final docRef = _firestore.collection('harvests').doc();
    await docRef.set(harvest.copyWith(id: docRef.id).toMap());
  }

  // Só usa filtro de igualdade para não exigir índice composto no Firestore;
  // a ordenação (mais recente primeiro) é feita localmente.
  // [createdBy]: só as registradas por esse usuário (colaborador). O filtro
  // vai na consulta, e não na tela, para ele não receber as colheitas (e
  // receitas) dos outros.
  Future<List<HarvestModel>> getHarvests(
    String farmId, {
    String? createdBy,
  }) async {
    var query = _firestore
        .collection('harvests')
        .where('farmId', isEqualTo: farmId);
    if (createdBy != null) {
      query = query.where('createdBy', isEqualTo: createdBy);
    }
    final snapshot = await query.get();
    final harvests = snapshot.docs
        .map((doc) => HarvestModel.fromMap(doc.data()))
        .toList();
    harvests.sort((a, b) => b.dateTimestamp.compareTo(a.dateTimestamp));
    return harvests;
  }

  Future<void> updateHarvest(HarvestModel harvest) async {
    await _firestore
        .collection('harvests')
        .doc(harvest.id)
        .update(harvest.toMap());
  }

  Future<void> deleteHarvest(String id) async {
    await _firestore.collection('harvests').doc(id).delete();
  }
}
