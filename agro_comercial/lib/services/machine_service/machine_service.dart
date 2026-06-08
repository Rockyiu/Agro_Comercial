import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:agro_comercial/common/models/machine_model.dart';

class MachineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> _uploadImage(String machineId, File file) async {
    try {
      final ref = _storage.ref().child('machines').child('$machineId.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> createMachine(MachineModel machine, File? imageFile) async {
    final docRef = _firestore.collection('machines').doc();
    String? imageUrl;

    if (imageFile != null) {
      imageUrl = await _uploadImage(docRef.id, imageFile);
    }

    final machineWithId = MachineModel(
      id: docRef.id,
      name: machine.name,
      model: machine.model,
      brand: machine.brand,
      power: machine.power,
      workingHours: machine.workingHours,
      imageUrl: imageUrl,
      warehouseId: machine.warehouseId,
      farmId: machine.farmId,
    );

    final map = machineWithId.toMap();
    map['createdAt'] = DateTime.now().millisecondsSinceEpoch;

    await docRef.set(map);
  }

  Future<List<MachineModel>> getMachinesByWarehouse(String warehouseId) async {
    final snapshot = await _firestore
        .collection('machines')
        .where('warehouseId', isEqualTo: warehouseId)
        .get();

    return snapshot.docs
        .map((doc) => MachineModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> updateMachine(MachineModel machine, File? newImageFile) async {
    String? imageUrl = machine.imageUrl;

    if (newImageFile != null) {
      imageUrl = await _uploadImage(machine.id!, newImageFile);
    }

    await _firestore.collection('machines').doc(machine.id).update({
      'name': machine.name,
      'model': machine.model,
      'brand': machine.brand,
      'power': machine.power,
      'workingHours': machine.workingHours,
      'imageUrl': imageUrl,
    });
  }

  Future<void> deleteMachine(String machineId) async {
    await _firestore.collection('machines').doc(machineId).delete();
    try {
      await _storage.ref().child('machines').child('$machineId.jpg').delete();
    } catch (_) {}
  }

  Future<void> deleteMultipleMachines(List<String> machineIds) async {
    final batch = _firestore.batch();

    for (String id in machineIds) {
      final docRef = _firestore.collection('machines').doc(id);
      batch.delete(docRef);

      try {
        await _storage.ref().child('machines').child('$id.jpg').delete();
      } catch (_) {}
    }

    await batch.commit();
  }
}
