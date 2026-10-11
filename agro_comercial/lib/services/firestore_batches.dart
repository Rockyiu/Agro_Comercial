import 'package:cloud_firestore/cloud_firestore.dart';

// Limite de gravações em um lote (WriteBatch) do Firestore
const int maxBatchWrites = 500;

// Grava as operações em lotes de até 500 (o limite do Firestore). Listas
// grandes (ex: excluir um armazém cheio) passariam do limite em um lote só.
Future<void> commitInBatches(
  FirebaseFirestore firestore,
  Iterable<void Function(WriteBatch batch)> writes,
) async {
  final pending = writes.toList();
  for (var i = 0; i < pending.length; i += maxBatchWrites) {
    final batch = firestore.batch();
    for (final write in pending.skip(i).take(maxBatchWrites)) {
      write(batch);
    }
    await batch.commit();
  }
}
