import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/farm_model.dart';

class FarmService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Busca as fazendas do gerente
  Future<List<FarmModel>> getFarmsByOwner(String ownerId) async {
    final snapshot = await _firestore
        .collection('farms')
        .where('ownerId', isEqualTo: ownerId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Garante que o ID do documento seja salvo no modelo
      return FarmModel.fromMap(data);
    }).toList();
  }

  // Busca a fazenda à qual o colaborador foi vinculado (campo 'farmId' em users/{uid})
  Future<FarmModel?> getFarmByCollaborator(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final farmId = userDoc.data()?['farmId'] as String?;
    if (farmId == null || farmId.isEmpty) return null;

    final farmDoc = await _firestore.collection('farms').doc(farmId).get();
    final data = farmDoc.data();
    if (data == null) return null;

    data['id'] = farmDoc.id;
    return FarmModel.fromMap(data);
  }

  // Salva a fazenda no banco
  Future<void> createFarm(FarmModel farm) async {
    await _firestore.collection('farms').add(farm.toMap());
  }

  Future<void> updateFarm(FarmModel farm) async {
    if (farm.id == null) throw Exception("ID da fazenda não pode ser nulo.");
    await _firestore.collection('farms').doc(farm.id).update(farm.toMap());
  }
}
