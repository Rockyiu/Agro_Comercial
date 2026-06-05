import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/machine_model.dart';

class MachineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Função para salvar a máquina no banco de dados
  Future<void> createMachine(MachineModel machine) async {
    final docRef = _firestore.collection('machines').doc();

    final machineWithId = MachineModel(
      id: docRef.id,
      name: machine.name,
      model: machine.model,
      brand: machine.brand,
      power: machine.power,
      workingHours: machine.workingHours,
      imageUrl: machine.imageUrl,
      warehouseId: machine.warehouseId,
      farmId: machine.farmId,
    );

    final map = machineWithId.toMap();
    map['createdAt'] = DateTime.now().millisecondsSinceEpoch;

    await docRef.set(map);
  }

  Future<void> updateMachine(MachineModel machine) async {
    await _firestore.collection('machines').doc(machine.id).update({
      'name': machine.name,
      'model': machine.model,
      'brand': machine.brand,
      'power': machine.power,
      'workingHours': machine.workingHours,
    });
  }

  // Futuramente usaremos esta função para mostrar as máquinas dentro do galpão
  Future<List<MachineModel>> getMachinesByWarehouse(String warehouseId) async {
    final snapshot = await _firestore
        .collection('machines')
        .where('warehouseId', isEqualTo: warehouseId)
        .get();

    return snapshot.docs
        .map((doc) => MachineModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> deleteMachine(String machineId) async {
    await _firestore.collection('machines').doc(machineId).delete();
  }
}
