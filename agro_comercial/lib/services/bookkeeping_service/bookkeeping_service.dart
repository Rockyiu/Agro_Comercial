import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:agro_comercial/common/models/bookkeeping_model.dart';
import 'package:agro_comercial/services/firestore_batches.dart';
import 'package:agro_comercial/services/local_media_service/local_media_service.dart';

// Lançamentos do Livro Caixa: users -> ID do Produtor -> bookkeeping.
// O comprovante (PDF) fica só no aparelho (LocalMediaService), com o id do
// lançamento.
class BookkeepingService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalMediaService _media;

  BookkeepingService(this._media);

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não autenticado.");
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_userId).collection('bookkeeping');

  // Mais recentes primeiro (timestamp gerado no BookkeepingModel)
  Future<List<BookkeepingModel>> getEntries() async {
    final snapshot = await _collection
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => BookkeepingModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Cria ou edita um lançamento. [pdfBytes]: comprovante novo, que substitui
  // o anterior; [removePdf]: tira o comprovante atual.
  Future<void> saveEntry(
    BookkeepingModel entry, {
    Uint8List? pdfBytes,
    bool removePdf = false,
  }) async {
    final id = entry.id;
    final docRef = id != null && id.isNotEmpty
        ? _collection.doc(id)
        : _collection.doc();
    final data = entry.toMap();

    if (docRef.id == id) {
      await docRef.update(data);
    } else {
      await docRef.set(data);
    }

    if (pdfBytes != null) {
      await _media.saveReceipt(docRef.id, pdfBytes);
    } else if (removePdf) {
      await _media.deleteReceipts([docRef.id]);
    }
  }

  Future<void> deleteEntries(List<String> ids) async {
    await commitInBatches(
      _firestore,
      ids.map(
        (id) =>
            (batch) => batch.delete(_collection.doc(id)),
      ),
    );
    await _media.deleteReceipts(ids);
  }
}
