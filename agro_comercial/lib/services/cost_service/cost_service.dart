import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:agro_comercial/common/models/cost_model.dart';
import 'package:agro_comercial/services/firestore_batches.dart';

class CostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _costs =>
      _firestore.collection('costs');

  Future<void> saveCost(CostModel cost) async {
    await _costs.add(cost.toMap());
  }

  Future<void> updateCost(CostModel cost) async {
    if (cost.id != null) {
      await _costs.doc(cost.id).update(cost.toMap());
    }
  }

  Future<void> deleteCost(String costId) async {
    await _costs.doc(costId).delete();
  }

  // Exclui vários custos em lote (uma ida ao banco, em vez de uma por custo)
  Future<void> deleteCosts(Iterable<String> costIds) => commitInBatches(
    _firestore,
    costIds.map(
      (id) =>
          (batch) => batch.delete(_costs.doc(id)),
    ),
  );

  // Custos da fazenda, do mais recente para o mais antigo.
  //
  // Sem [includeLabor] (colaborador), a consulta já vem sem os custos de mão
  // de obra: as regras do Firestore só liberam a leitura para o colaborador
  // quando a consulta filtra por laborCost == false.
  Future<List<CostModel>> getCostsByFarm(
    String farmId, {
    required bool includeLabor,
  }) async {
    var query = _costs.where('farmId', isEqualTo: farmId);
    if (!includeLabor) query = query.where('laborCost', isEqualTo: false);
    final snapshot = await query
        .orderBy('dateTimestamp', descending: true)
        .get();

    if (includeLabor) await _flagLegacyCosts(snapshot.docs);

    return snapshot.docs
        .map((doc) => CostModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Custos gravados antes do campo laborCost não aparecem na consulta do
  // colaborador. O produtor (único que lê todos) grava o campo neles.
  // Uma falha aqui não impede a lista de carregar: tenta de novo na próxima.
  Future<void> _flagLegacyCosts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final legacy = docs.where((doc) => doc.data()['laborCost'] is! bool);
    if (legacy.isEmpty) return;

    try {
      await commitInBatches(
        _firestore,
        legacy.map(
          (doc) =>
              (batch) => batch.update(doc.reference, {
                'laborCost': CostModel.isLaborCategory(
                  doc.data()['category'] as String? ?? '',
                ),
              }),
        ),
      );
    } catch (e) {
      debugPrint("Erro ao atualizar custos antigos: $e");
    }
  }
}
