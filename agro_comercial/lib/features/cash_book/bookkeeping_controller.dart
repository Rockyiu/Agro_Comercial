import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../common/models/bookkeeping_model.dart';
import 'bookkeeping_state.dart';

class BookkeepingController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  BookkeepingState _state = BookkeepingInitialState();
  BookkeepingState get state => _state;

  void _changeState(BookkeepingState newState) {
    _state = newState;
    notifyListeners();
  }

  // Define o caminho do banco de dados: users -> ID do Produtor -> bookkeeping
  CollectionReference get _colecaoLivroCaixa {
    final userId = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(userId).collection('bookkeeping');
  }

  // --- 1. LER LANÇAMENTOS (READ) ---
  Future<void> carregarLancamentos() async {
    _changeState(BookkeepingLoadingState());
    try {
      // Ordena pelos mais recentes usando o timestamp criado no model
      final snapshot = await _colecaoLivroCaixa
          .orderBy('timestamp', descending: true)
          .get();

      final lancamentos = snapshot.docs.map((doc) {
        return BookkeepingModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      _changeState(BookkeepingSuccessState(lancamentos));
    } catch (e) {
      _changeState(
        BookkeepingErrorState("Erro ao carregar os dados do Livro Caixa: $e"),
      );
    }
  }

  // --- 2. ADICIONAR OU EDITAR LANÇAMENTO (CREATE/UPDATE) ---
  Future<bool> salvarLancamento(
    BookkeepingModel lancamento, {
    File? arquivoPdf,
  }) async {
    _changeState(BookkeepingLoadingState());
    try {
      String? urlPdf = lancamento.pdfUrl;

      // Se o usuário selecionou um novo PDF, fazemos o upload para o Firebase Storage
      if (arquivoPdf != null) {
        final userId = _auth.currentUser!.uid;
        final nomeArquivo =
            'notas_fiscais/${userId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final uploadTask = await _storage.ref(nomeArquivo).putFile(arquivoPdf);
        urlPdf = await uploadTask.ref.getDownloadURL();
      }

      // Prepara o modelo com o link do PDF (se houver)
      final dadosParaSalvar = BookkeepingModel(
        id: lancamento.id,
        dia: lancamento.dia,
        mes: lancamento.mes,
        ano: lancamento.ano,
        conta: lancamento.conta,
        historico: lancamento.historico,
        valor: lancamento.valor,
        pdfUrl: urlPdf ?? lancamento.pdfUrl,
      ).toMap();

      if (lancamento.id != null && lancamento.id!.isNotEmpty) {
        // EDIÇÃO
        await _colecaoLivroCaixa.doc(lancamento.id).update(dadosParaSalvar);
      } else {
        // NOVO CADASTRO
        await _colecaoLivroCaixa.add(dadosParaSalvar);
      }

      // Recarrega a lista após salvar
      await carregarLancamentos();
      return true;
    } catch (e) {
      _changeState(BookkeepingErrorState("Erro ao salvar lançamento: $e"));
      return false;
    }
  }

  // --- 3. EXCLUIR MÚLTIPLOS LANÇAMENTOS (DELETE) ---
  Future<void> excluirLancamentos(List<String> idsSelecionados) async {
    _changeState(BookkeepingLoadingState());
    try {
      final batch = _firestore.batch();

      // CORREÇÃO: Usando "in" em vez de "em"
      for (String id in idsSelecionados) {
        final docRef = _colecaoLivroCaixa.doc(id);
        batch.delete(docRef);
      }

      await batch.commit(); // Executa todas as exclusões de uma vez!
      await carregarLancamentos(); // Atualiza a tela
    } catch (e) {
      _changeState(
        BookkeepingErrorState("Erro ao excluir os lançamentos selecionados."),
      );
    }
  }
}
