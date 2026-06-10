import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/field_operation_model.dart';

class FieldOperationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveFieldOperation(FieldOperationModel operation) async {
    final docRef = _firestore.collection('field_operations').doc();

    final operationWithId = FieldOperationModel(
      id: docRef.id,
      type: operation.type,
      plotName: operation.plotName,
      dateTimestamp: operation.dateTimestamp,
      farmId: operation.farmId,
      condition: operation.condition,
      observations: operation.observations,
      productId: operation.productId,
      productName: operation.productName,
      dosage: operation.dosage,
      dosageUnit: operation.dosageUnit,
      machineId: operation.machineId,
      machineName: operation.machineName,
    );

    await docRef.set(operationWithId.toMap());
  }
}
