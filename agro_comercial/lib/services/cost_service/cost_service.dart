import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/cost_model.dart';

class CostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveCost(CostModel cost) async {
    await _firestore.collection('costs').add(cost.toMap());
  }

  Future<void> updateCost(CostModel cost) async {
    if (cost.id != null) {
      await _firestore.collection('costs').doc(cost.id).update(cost.toMap());
    }
  }

  Future<void> deleteCost(String costId) async {
    await _firestore.collection('costs').doc(costId).delete();
  }

  Future<List<CostModel>> getCostsByFarm(String farmId) async {
    final snapshot = await _firestore
        .collection('costs')
        .where('farmId', isEqualTo: farmId)
        .orderBy('dateTimestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CostModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
