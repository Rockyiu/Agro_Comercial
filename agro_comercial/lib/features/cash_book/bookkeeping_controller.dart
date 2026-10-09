import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
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
    Uint8List? arquivoPdf,
  }) async {
    _changeState(BookkeepingLoadingState());
    try {
      await _bookkeepingService.saveEntry(lancamento, pdfBytes: arquivoPdf);
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
    // Comprovantes (PDF) dos lançamentos, para apagar junto
    final current = _state;
    final ids = idsSelecionados.toSet();
    final pdfUrls = current is BookkeepingSuccessState
        ? [
            for (final l in current.lancamentos)
              if (ids.contains(l.id)) l.pdfUrl,
          ]
        : const <String?>[];

    _changeState(BookkeepingLoadingState());
    try {
      await _bookkeepingService.deleteEntries(
        idsSelecionados,
        pdfUrls: pdfUrls,
      );
      await carregarLancamentos(); // Atualiza a tela
    } catch (e) {
      _changeState(
        BookkeepingErrorState("Erro ao excluir os lançamentos selecionados."),
      );
    }
  }
}
