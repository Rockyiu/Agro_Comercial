import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
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

  // Cria ou edita um lançamento. Se vier um PDF novo ([pdfBytes]), ele é
  // enviado para a pasta privada do produtor e o anterior é apagado.
  Future<void> saveEntry(BookkeepingModel entry, {Uint8List? pdfBytes}) async {
    String? pdfUrl = entry.pdfUrl;

    if (pdfBytes != null) {
      final path =
          'users/$_userId/notas_fiscais/${DateTime.now().millisecondsSinceEpoch}.pdf';
      final upload = await _storage
          .ref(path)
          .putData(pdfBytes, SettableMetadata(contentType: 'application/pdf'));
      pdfUrl = await upload.ref.getDownloadURL();
      await _deletePdf(entry.pdfUrl);
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

  // [pdfUrls]: comprovantes dos lançamentos, apagados depois deles
  Future<void> deleteEntries(
    List<String> ids, {
    Iterable<String?> pdfUrls = const [],
  }) async {
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.delete(_collection.doc(id));
    }
    await batch.commit();
    await Future.wait(pdfUrls.map(_deletePdf));
  }

  // O arquivo pode já ter sido apagado; nesse caso o erro é ignorado
  Future<void> _deletePdf(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await _storage.refFromURL(url).delete();
    } catch (e) {
      debugPrint("Comprovante não apagado ($url): $e");
    }
  }
}
