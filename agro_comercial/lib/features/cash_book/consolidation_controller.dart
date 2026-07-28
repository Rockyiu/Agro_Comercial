import 'package:agro_comercial/common/models/bookkeeping_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
}

class ConsolidationController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      final userId = _auth.currentUser!.uid;
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookkeeping')
          .get();

      // Zera tudo antes de recalcular
      resumoAno = List.generate(12, (_) => ResumoMensal());
      totalGeral = ResumoMensal();

      // LAÇO 1: Classifica cada nota fiscal no seu mês e coluna corretos
      for (var doc in snapshot.docs) {
        final item = BookkeepingModel.fromMap(doc.data(), doc.id);
        int mes = item.mes;

        if (item.conta.startsWith('1'))
          resumoAno[mes].receitas += item.valor;
        else if (item.conta.startsWith('2'))
          resumoAno[mes].despesas += item.valor;
        else if (item.conta.startsWith('3'))
          resumoAno[mes].despesasNaoDedutiveis += item.valor;
        else if (item.conta.startsWith('4'))
          resumoAno[mes].adiantamentosAnteriores += item.valor;
        else if (item.conta.startsWith('5'))
          resumoAno[mes].adiantamentosAtuais += item.valor;
      }

      // LAÇO 2: Calcula a soma total de todas as colunas para a última linha
      for (var mes in resumoAno) {
        totalGeral.receitas += mes.receitas;
        totalGeral.despesas += mes.despesas;
        totalGeral.despesasNaoDedutiveis += mes.despesasNaoDedutiveis;
        totalGeral.adiantamentosAnteriores += mes.adiantamentosAnteriores;
        totalGeral.adiantamentosAtuais += mes.adiantamentosAtuais;
      }
    } catch (e) {
      errorMessage = "Erro ao calcular a consolidação: $e";
    } finally {
      isLoading = false;
      notifyListeners(); // Avisa a tela que as contas terminaram!
    }
  }

  // Função utilitária para formatar a moeda no padrão brasileiro (100.000,00)
  String formatarMoeda(double valor) {
    String s = valor.abs().toStringAsFixed(2);
    List<String> parts = s.split('.');
    String intPart = parts[0];
    String decPart = parts[1];
    String result = "";
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      result = intPart[i] + result;
      count++;
      if (count == 3 && i > 0) {
        result = ".$result";
        count = 0;
      }
    }
    return "${valor < 0 ? '-' : ''}$result,$decPart";
  }
}
