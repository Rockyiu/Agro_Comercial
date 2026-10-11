import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:agro_comercial/common/models/machine_cost_data.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/photo_change.dart';
import 'package:agro_comercial/services/firestore_batches.dart';
import 'package:agro_comercial/services/local_media_service/local_media_service.dart';

// Máquinas e implementos. A foto fica só no aparelho (LocalMediaService).
//
// Os dados de custo da hora-máquina ficam em machine_costs/{id da máquina},
// que só o produtor lê: o colaborador lê o documento da máquina (para lançar
// operações) e não pode ver valores de aquisição, mercado, etc.
class MachineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalMediaService _media;

  MachineService(this._media);

  CollectionReference<Map<String, dynamic>> get _machines =>
      _firestore.collection('machines');

  CollectionReference<Map<String, dynamic>> get _costs =>
      _firestore.collection('machine_costs');

  Map<String, dynamic> _costDoc(String farmId, MachineCostData data) => {
    ...data.toMap(),
    'farmId': farmId,
  };

  Future<void> createMachine(MachineModel machine, {PhotoChange? photo}) async {
    final docRef = _machines.doc();
    final costData = machine.costData;

    // copyWith preserva todos os campos (inclusive isMotorized)
    final map = machine.copyWith(id: docRef.id).toMap()
      ..remove('costData')
      ..['createdAt'] = DateTime.now().millisecondsSinceEpoch;

    final batch = _firestore.batch()..set(docRef, map);
    if (costData != null) {
      batch.set(_costs.doc(docRef.id), _costDoc(machine.farmId, costData));
    }
    await batch.commit();

    await _media.applyPhotoChange(MediaKind.machine, docRef.id, photo);
  }

  // Toda consulta filtra pela fazenda: é o que as regras do Firestore usam
  // para liberar a leitura.
  // [withCosts]: junta os dados de custo; só o produtor pode pedir.
  Future<List<MachineModel>> getMachinesByFarm(
    String farmId, {
    bool withCosts = false,
  }) => _query(
    farmId,
    _machines.where('farmId', isEqualTo: farmId),
    withCosts: withCosts,
  );

  Future<List<MachineModel>> getMachinesByWarehouse({
    required String farmId,
    required String warehouseId,
    bool withCosts = false,
  }) => _query(
    farmId,
    _machines
        .where('farmId', isEqualTo: farmId)
        .where('warehouseId', isEqualTo: warehouseId),
    withCosts: withCosts,
  );

  Future<List<MachineModel>> _query(
    String farmId,
    Query<Map<String, dynamic>> query, {
    required bool withCosts,
  }) async {
    if (!withCosts) {
      final snapshot = await query.get();
      return [
        for (final doc in snapshot.docs)
          MachineModel.fromMap({...doc.data(), 'id': doc.id, 'costData': null}),
      ];
    }

    final (snapshot, costs) = await (query.get(), _costsByFarm(farmId)).wait;
    await _moveLegacyCosts(farmId, snapshot.docs, costs);

    return [
      for (final doc in snapshot.docs)
        MachineModel.fromMap({
          ...doc.data(),
          'id': doc.id,
          'costData': costs[doc.id] ?? doc.data()['costData'],
        }),
    ];
  }

  Future<Map<String, Map<String, dynamic>>> _costsByFarm(String farmId) async {
    final snapshot = await _costs.where('farmId', isEqualTo: farmId).get();
    return {for (final doc in snapshot.docs) doc.id: doc.data()};
  }

  // Máquinas gravadas antes da separação ainda têm costData no próprio
  // documento. O produtor move esses dados para machine_costs. Uma falha
  // aqui não impede a lista de carregar: tenta de novo na próxima.
  Future<void> _moveLegacyCosts(
    String farmId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    Map<String, Map<String, dynamic>> costs,
  ) async {
    final legacy = docs.where((doc) => doc.data().containsKey('costData'));
    if (legacy.isEmpty) return;

    try {
      await commitInBatches(_firestore, [
        for (final doc in legacy)
          (batch) {
            final data = doc.data()['costData'];
            // Se já existe em machine_costs, o de lá é o mais recente
            if (!costs.containsKey(doc.id) && data is Map) {
              batch.set(
                _costs.doc(doc.id),
                _costDoc(
                  farmId,
                  MachineCostData.fromMap(Map<String, dynamic>.from(data)),
                ),
              );
            }
            batch.update(doc.reference, {'costData': FieldValue.delete()});
          },
      ]);
    } catch (e) {
      debugPrint("Erro ao mover custos antigos das máquinas: $e");
    }
  }

  // Move os custos antigos de todas as máquinas da fazenda (produtor)
  Future<void> moveLegacyCosts(String farmId) async {
    final (snapshot, costs) = await (
      _machines.where('farmId', isEqualTo: farmId).get(),
      _costsByFarm(farmId),
    ).wait;
    await _moveLegacyCosts(farmId, snapshot.docs, costs);
  }

  // [updateHours]: o horímetro só é gravado se foi alterado no formulário.
  // Ele também sobe pelas operações (incremento), e regravar o valor que
  // estava na tela apagaria as horas lançadas nesse meio-tempo.
  Future<void> updateMachine(
    MachineModel machine, {
    required bool updateHours,
    PhotoChange? photo,
  }) async {
    final costData = machine.costData ?? const MachineCostData();
    await (_firestore.batch()
          ..update(_machines.doc(machine.id), {
            'name': machine.name,
            'model': machine.model,
            'brand': machine.brand,
            'power': machine.power,
            if (updateHours) 'workingHours': machine.workingHours,
            // Remove a cópia antiga, de antes de machine_costs
            'costData': FieldValue.delete(),
          })
          ..set(_costs.doc(machine.id), _costDoc(machine.farmId, costData)))
        .commit();
    await _media.applyPhotoChange(MediaKind.machine, machine.id!, photo);
  }

  Future<void> deleteMachine(String machineId) =>
      deleteMultipleMachines([machineId]);

  Future<void> deleteMultipleMachines(List<String> machineIds) async {
    await commitInBatches(_firestore, [
      for (final id in machineIds) ...[
        (batch) => batch.delete(_costs.doc(id)),
        (batch) => batch.delete(_machines.doc(id)),
      ],
    ]);
    await _media.deleteImages(MediaKind.machine, machineIds);
  }
}
