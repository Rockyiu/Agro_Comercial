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

  // Salva a fazenda no banco
  Future<void> createFarm(FarmModel farm) async {
    await _firestore.collection('farms').add(farm.toMap());
  }

  Future<void> updateFarm(FarmModel farm) async {
    try {
      if (farm.id == null) throw Exception("ID da fazenda não pode ser nulo.");

      await FirebaseFirestore.instance
          .collection(
            'farms',
          ) // Confirme se o nome da sua coleção no Firebase é 'farms' mesmo
          .doc(farm.id)
          .update(farm.toMap());
    } catch (e) {
      throw Exception("Erro ao atualizar fazenda no Firebase: $e");
    }
  }
}
