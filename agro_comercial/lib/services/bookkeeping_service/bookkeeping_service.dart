import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:agro_comercial/common/models/bookkeeping_model.dart';

// Lançamentos do Livro Caixa: users -> ID do Produtor -> bookkeeping
class BookkeepingService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

  // Cria ou edita um lançamento; se houver PDF novo, envia para o Storage
  Future<void> saveEntry(BookkeepingModel entry, {File? pdfFile}) async {
    String? pdfUrl = entry.pdfUrl;

    if (pdfFile != null) {
      final fileName =
          'notas_fiscais/${_userId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final upload = await _storage.ref(fileName).putFile(pdfFile);
      pdfUrl = await upload.ref.getDownloadURL();
    }

    // O tipo (Entrada/Saída) é recalculado pela conta dentro do model
    final data = BookkeepingModel(
      id: entry.id,
      dia: entry.dia,
      mes: entry.mes,
      ano: entry.ano,
      conta: entry.conta,
      historico: entry.historico,
      valor: entry.valor,
      pdfUrl: pdfUrl,
    ).toMap();

    final id = entry.id;
    if (id != null && id.isNotEmpty) {
      await _collection.doc(id).update(data);
    } else {
      await _collection.add(data);
    }
  }

  Future<void> deleteEntries(List<String> ids) async {
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.delete(_collection.doc(id));
    }
    await batch.commit();
  }
}
