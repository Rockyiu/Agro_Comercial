import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:flutter/foundation.dart';

import '../../services/bookkeeping_service/bookkeeping_service.dart';

// Modelo exclusivo para as somas da tabela
class ResumoMensal {
  double receitas = 0.0;
  double despesas = 0.0;
  double despesasNaoDedutiveis = 0.0;
  double adiantamentosAnteriores = 0.0;
  double adiantamentosAtuais = 0.0;

  // Cálculo automático do resultado do mês (Entradas - Saídas)
  double get resultadoMes =>
      (receitas + adiantamentosAnteriores + adiantamentosAtuais) -
      (despesas + despesasNaoDedutiveis);

  // Soma o valor na coluna correspondente ao grupo da conta (1xx a 5xx)
  void adicionar(String conta, double valor) {
    switch (conta.isEmpty ? '' : conta[0]) {
      case '1':
        receitas += valor;
      case '2':
        despesas += valor;
      case '3':
        despesasNaoDedutiveis += valor;
      case '4':
        adiantamentosAnteriores += valor;
      case '5':
        adiantamentosAtuais += valor;
    }
  }

  void somar(ResumoMensal outro) {
    receitas += outro.receitas;
    despesas += outro.despesas;
    despesasNaoDedutiveis += outro.despesasNaoDedutiveis;
    adiantamentosAnteriores += outro.adiantamentosAnteriores;
    adiantamentosAtuais += outro.adiantamentosAtuais;
  }
}

class ConsolidationController extends SafeChangeNotifier {
  final BookkeepingService _bookkeepingService;

  ConsolidationController(this._bookkeepingService);

  bool isLoading = false;
  String? errorMessage;

  // Lista com os 12 meses zerados
  List<ResumoMensal> resumoAno = List.generate(12, (_) => ResumoMensal());
  // Variável para a última linha da tabela
  ResumoMensal totalGeral = ResumoMensal();

  Future<void> carregarCalculos() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final lancamentos = await _bookkeepingService.getEntries();

      // Zera tudo antes de recalcular
      final meses = List.generate(12, (_) => ResumoMensal());
      final total = ResumoMensal();

      // Classifica cada lançamento no seu mês e coluna corretos
      for (final item in lancamentos) {
        meses[item.mes].adicionar(item.conta, item.valor);
      }
      // Soma de todas as colunas para a última linha
      for (final mes in meses) {
        total.somar(mes);
      }

      resumoAno = meses;
      totalGeral = total;
    } catch (e) {
      debugPrint("Erro ao calcular a consolidação: $e");
      errorMessage = "Erro ao calcular a consolidação.";
    } finally {
      isLoading = false;
      notifyListeners(); // Avisa a tela que as contas terminaram!
    }
  }
}
