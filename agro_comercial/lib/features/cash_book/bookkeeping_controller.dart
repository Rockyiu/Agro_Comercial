import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../common/models/bookkeeping_model.dart';
import '../../services/bookkeeping_service/bookkeeping_service.dart';
import 'bookkeeping_state.dart';

class BookkeepingController extends SafeChangeNotifier {
  final BookkeepingService _bookkeepingService;

  BookkeepingController(this._bookkeepingService);

  BookkeepingState _state = BookkeepingInitialState();
  BookkeepingState get state => _state;

  void _changeState(BookkeepingState newState) {
    _state = newState;
    notifyListeners();
  }

  // --- 1. LER LANÇAMENTOS (READ) ---
  Future<void> carregarLancamentos() async {
    _changeState(BookkeepingLoadingState());
    try {
      final lancamentos = await _bookkeepingService.getEntries();
      _changeState(BookkeepingSuccessState(lancamentos));
    } catch (e) {
      debugPrint("Erro ao carregar o Livro Caixa: $e");
      _changeState(
        BookkeepingErrorState("Erro ao carregar os dados do Livro Caixa."),
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
      await _bookkeepingService.saveEntry(lancamento, pdfFile: arquivoPdf);
      // Recarrega a lista após salvar
      await carregarLancamentos();
      return true;
    } catch (e) {
      debugPrint("Erro ao salvar lançamento: $e");
      _changeState(BookkeepingErrorState("Erro ao salvar lançamento."));
      return false;
    }
  }

  // --- 3. EXCLUIR MÚLTIPLOS LANÇAMENTOS (DELETE) ---
  Future<void> excluirLancamentos(List<String> idsSelecionados) async {
    _changeState(BookkeepingLoadingState());
    try {
      await _bookkeepingService.deleteEntries(idsSelecionados);
      await carregarLancamentos(); // Atualiza a tela
    } catch (e) {
      _changeState(
        BookkeepingErrorState("Erro ao excluir os lançamentos selecionados."),
      );
    }
  }
}
