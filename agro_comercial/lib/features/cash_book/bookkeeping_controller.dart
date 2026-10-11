import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:flutter/foundation.dart';

import '../../common/models/bookkeeping_model.dart';
import '../../services/bookkeeping_service/bookkeeping_service.dart';
import '../../services/local_media_service/local_media_service.dart';
import 'bookkeeping_state.dart';

class BookkeepingController extends SafeChangeNotifier {
  final BookkeepingService _bookkeepingService;
  final LocalMediaService _media;

  BookkeepingController(this._bookkeepingService, this._media);

  BookkeepingState _state = BookkeepingInitialState();
  BookkeepingState get state => _state;

  void _changeState(BookkeepingState newState) {
    _state = newState;
    notifyListeners();
  }

  // --- 1. LER LANÇAMENTOS (READ) ---
  // Junto vêm os ids dos lançamentos com comprovante guardado no aparelho
  Future<void> carregarLancamentos() async {
    _changeState(BookkeepingLoadingState());
    try {
      final (lancamentos, comprovantes) = await (
        _bookkeepingService.getEntries(),
        _media.receiptIds(),
      ).wait;
      _changeState(BookkeepingSuccessState(lancamentos, comprovantes));
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
    bool removerPdf = false,
  }) async {
    _changeState(BookkeepingLoadingState());
    try {
      await _bookkeepingService.saveEntry(
        lancamento,
        pdfBytes: arquivoPdf,
        removePdf: removerPdf,
      );
      // Recarrega a lista após salvar
      await carregarLancamentos();
      return true;
    } catch (e) {
      debugPrint("Erro ao salvar lançamento: $e");
      _changeState(BookkeepingErrorState("Erro ao salvar lançamento."));
      return false;
    }
  }

  // --- 3. EXCLUIR LANÇAMENTOS (DELETE) ---
  // Os comprovantes guardados no aparelho são apagados junto. Devolve false
  // se der erro.
  Future<bool> excluirLancamentos(List<String> idsSelecionados) async {
    _changeState(BookkeepingLoadingState());
    try {
      await _bookkeepingService.deleteEntries(idsSelecionados);
      await carregarLancamentos(); // Atualiza a tela
      return true;
    } catch (e) {
      debugPrint("Erro ao excluir lançamentos: $e");
      _changeState(
        BookkeepingErrorState("Erro ao excluir os lançamentos selecionados."),
      );
      return false;
    }
  }
}
