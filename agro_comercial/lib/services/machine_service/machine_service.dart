import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/photo_change.dart';
import 'package:agro_comercial/services/firestore_batches.dart';
import 'package:agro_comercial/services/local_media_service/local_media_service.dart';

// Máquinas e implementos. A foto fica só no aparelho (LocalMediaService).
class MachineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalMediaService _media;

  MachineService(this._media);

  CollectionReference<Map<String, dynamic>> get _machines =>
      _firestore.collection('machines');

  Future<void> createMachine(MachineModel machine, {PhotoChange? photo}) async {
    final docRef = _machines.doc();

    // copyWith preserva todos os campos (inclusive isMotorized)
    final map = machine.copyWith(id: docRef.id).toMap()
      ..['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    await docRef.set(map);

    await _media.applyPhotoChange(MediaKind.machine, docRef.id, photo);
  }

  // Toda consulta filtra pela fazenda: é o que as regras do Firestore usam
  // para liberar a leitura
  Future<List<MachineModel>> getMachinesByFarm(String farmId) =>
      _query(_machines.where('farmId', isEqualTo: farmId));

  Future<List<MachineModel>> getMachinesByWarehouse({
    required String farmId,
    required String warehouseId,
  }) => _query(
    _machines
        .where('farmId', isEqualTo: farmId)
        .where('warehouseId', isEqualTo: warehouseId),
  );

  Future<List<MachineModel>> _query(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => MachineModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // [updateHours]: o horímetro só é gravado se foi alterado no formulário.
  // Ele também sobe pelas operações (incremento), e regravar o valor que
  // estava na tela apagaria as horas lançadas nesse meio-tempo.
  Future<void> updateMachine(
    MachineModel machine, {
    required bool updateHours,
    PhotoChange? photo,
  }) async {
    await _machines.doc(machine.id).update({
      'name': machine.name,
      'model': machine.model,
      'brand': machine.brand,
      'power': machine.power,
      if (updateHours) 'workingHours': machine.workingHours,
      'costData': machine.costData?.toMap(),
    });
    await _media.applyPhotoChange(MediaKind.machine, machine.id!, photo);
  }

  Future<void> deleteMachine(String machineId) =>
      deleteMultipleMachines([machineId]);

  Future<void> deleteMultipleMachines(List<String> machineIds) async {
    await commitInBatches(
      _firestore,
      machineIds.map(
        (id) =>
            (batch) => batch.delete(_machines.doc(id)),
      ),
    );
    await _media.deleteImages(MediaKind.machine, machineIds);
  }
}
