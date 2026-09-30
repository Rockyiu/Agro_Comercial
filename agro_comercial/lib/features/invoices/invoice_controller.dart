import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

import 'package:agro_comercial/common/models/invoice_model.dart';
import 'package:agro_comercial/services/invoice_service/invoice_local_service.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'invoice_state.dart';

class InvoiceController extends SafeChangeNotifier {
  final InvoiceLocalService _invoiceService;
  final FarmController _farmController;

  InvoiceController(this._invoiceService, this._farmController);

  InvoiceState _state = InvoiceInitialState();
  InvoiceState get state => _state;

  List<InvoiceModel> allInvoices = [];

  // ==========================================
  // 1. CARREGAR AS NOTAS DO BANCO LOCAL (SQLITE)
  // ==========================================
  Future<void> loadInvoices() async {
    _state = InvoiceLoadingState("Buscando notas no aparelho...");
    notifyListeners();

    try {
      final activeFarm = _farmController.selectedFarm;
      if (activeFarm == null) throw Exception("Nenhuma fazenda ativa.");

      // NOTA: Como não sei se você tem o campo cadPro no FarmModel,
      // estou usando o id da fazenda como se fosse o CAD/PRO para manter a divisão correta!
      final String cadPro = activeFarm.id!;

      allInvoices = await _invoiceService.getInvoicesByCadPro(cadPro);
      _state = InvoiceSuccessState(allInvoices);
    } catch (e) {
      _state = InvoiceErrorState("Erro ao carregar as notas.");
    }
    notifyListeners();
  }

  // ==========================================
  // 2. LÓGICA DE DOWNLOAD INCREMENTAL E ESCOLHA DE PASTA
  // ==========================================
  Future<void> downloadNewInvoices() async {
    final activeFarm = _farmController.selectedFarm;
    if (activeFarm == null) {
      _state = InvoiceErrorState("Nenhuma fazenda ativa.");
      notifyListeners();
      return;
    }

    final String cadPro = activeFarm.id!;

    // Abre a tela nativa do celular para escolher onde salvar as notas
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      return; // Usuário cancelou a escolha da pasta, paramos por aqui
    }

    _state = InvoiceLoadingState("Conectando à SEFAZ...");
    notifyListeners();

    try {
      // Descobre a data da última nota baixada (Download Incremental)
      final lastDateTimestamp = await _invoiceService.getLatestIssueDate(
        cadPro,
      );

      // Simula o tempo de conexão com a API da SEFAZ
      await Future.delayed(const Duration(seconds: 3));

      List<InvoiceModel> downloadedInvoices = [];
      final now = DateTime.now();

      if (lastDateTimestamp == null) {
        // PRIMEIRA VEZ: Cria 3 notas antigas
        for (int i = 1; i <= 3; i++) {
          downloadedInvoices.add(
            _createFakePdfFile(
              cadPro: cadPro,
              directory: selectedDirectory,
              date: now.subtract(
                Duration(days: i * 15),
              ), // 15, 30 e 45 dias atrás
              number: Random().nextInt(1000) + 100,
            ),
          );
        }
      } else {
        // DOWNLOAD INCREMENTAL: Cria apenas 1 nota NOVA de hoje
        downloadedInvoices.add(
          _createFakePdfFile(
            cadPro: cadPro,
            directory: selectedDirectory,
            date: now,
            number: Random().nextInt(1000) + 9000,
          ),
        );
      }

      // Salva os registros das novas notas no SQLite
      for (var invoice in downloadedInvoices) {
        await _invoiceService.insertInvoice(invoice);
      }

      // Recarrega a lista da tela
      await loadInvoices();
    } catch (e) {
      _state = InvoiceErrorState("Erro ao baixar notas: $e");
      notifyListeners();
    }
  }

  // Função interna para criar arquivos de mentira no armazenamento do celular
  InvoiceModel _createFakePdfFile({
    required String cadPro,
    required String directory,
    required DateTime date,
    required int number,
  }) {
    // Gera uma chave de acesso falsa no formato da SEFAZ
    final accessKey =
        "412607${cadPro.padLeft(14, '0')}55001000${number.toString().padLeft(9, '0')}123456789";

    final fileName = "NFe_$accessKey.pdf";
    final filePath = p.join(directory, fileName);

    // Cria o arquivo físico na pasta que o usuário escolheu
    final file = File(filePath);

    // Escrevemos um texto dentro. O Leitor de PDF do celular pode dizer que está
    // corrompido (porque é texto e não código de PDF real), mas a intenção de abrir vai funcionar!
    file.writeAsStringSync(
      "Gestao Rural\nArquivo PDF simulado da Nota Fiscal: $accessKey",
    );

    return InvoiceModel(
      accessKey: accessKey,
      cadPro: cadPro,
      pdfFilePath: filePath,
      issueDate: date.millisecondsSinceEpoch,
    );
  }

  // ==========================================
  // 3. ABRIR COM O LEITOR DE PDF DO CELULAR
  // ==========================================
  Future<void> openPdf(String filePath) async {
    // Isso aqui faz aparecer a tela que você mandou no print!
    final result = await OpenFilex.open(filePath);

    if (result.type != ResultType.done) {
      // Caso o usuário não tenha NENHUM leitor de PDF instalado no celular
      _state = InvoiceErrorState(
        "Nenhum leitor de PDF encontrado no aparelho.",
      );
      notifyListeners();
      await Future.delayed(const Duration(seconds: 3));
      await loadInvoices(); // Volta para a lista
    }
  }
}
