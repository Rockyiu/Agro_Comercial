import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';

import 'package:agro_comercial/common/models/invoice_model.dart';
import 'package:agro_comercial/services/invoice_service/invoice_local_service.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'invoice_state.dart';

// Notas fiscais da fazenda ativa, guardadas no aparelho (SQLite) e separadas
// pelo CAD/PRO. O download das notas (SEFAZ) ainda não foi integrado: quando
// for, as notas baixadas entram por InvoiceLocalService.insertInvoice e
// InvoiceLocalService.getLatestIssueDate indica a partir de quando baixar.
class InvoiceController extends SafeChangeNotifier {
  final InvoiceLocalService _invoiceService;
  final FarmController _farmController;

  InvoiceController(this._invoiceService, this._farmController);

  InvoiceState _state = InvoiceInitialState();
  InvoiceState get state => _state;

  List<InvoiceModel> allInvoices = [];

  Future<void> loadInvoices() async {
    // As notas ficam em um banco SQLite do aparelho, que não existe na web
    if (kIsWeb) {
      _changeState(
        InvoiceErrorState(
          "As notas fiscais estão disponíveis apenas no aplicativo do celular.",
        ),
      );
      return;
    }

    final cadPro = _farmController.selectedFarm?.cadPro.trim() ?? '';
    if (_farmController.selectedFarm == null) {
      _changeState(InvoiceErrorState("Nenhuma fazenda ativa selecionada."));
      return;
    }
    if (cadPro.isEmpty) {
      _changeState(
        InvoiceErrorState("Informe o CAD/PRO da fazenda para ver as notas."),
      );
      return;
    }

    _changeState(InvoiceLoadingState("Buscando notas no aparelho..."));
    try {
      allInvoices = await _invoiceService.getInvoicesByCadPro(cadPro);
      _changeState(InvoiceSuccessState(allInvoices));
    } catch (e) {
      debugPrint("Erro ao carregar as notas: $e");
      _changeState(InvoiceErrorState("Erro ao carregar as notas."));
    }
  }

  // Abre o PDF no leitor do aparelho. Devolve uma mensagem de erro, se não
  // conseguir abrir.
  Future<String?> openPdf(String filePath) async {
    final result = await OpenFilex.open(filePath);
    return switch (result.type) {
      ResultType.done => null,
      ResultType.fileNotFound => "O arquivo da nota não foi encontrado.",
      ResultType.noAppToOpen => "Nenhum leitor de PDF encontrado no aparelho.",
      _ => "Não foi possível abrir a nota.",
    };
  }

  void _changeState(InvoiceState newState) {
    _state = newState;
    notifyListeners();
  }
}
