import 'package:agro_comercial/common/models/bookkeeping_model.dart';
import 'package:agro_comercial/common/utils/safe_change_notifier.dart';

// Ano-calendário selecionado no Livro Caixa. É compartilhado entre
// Escrituração, Consolidação e Relatórios, para as três telas mostrarem
// sempre o mesmo ano.
class CashBookYearController extends SafeChangeNotifier {
  // Quantos anos anteriores ao atual podem ser escolhidos
  static const int _previousYears = 16;

  int _year = DateTime.now().year;
  int get year => _year;

  void changeYear(int year) {
    if (year == _year) return;
    _year = year;
    notifyListeners();
  }

  // Anos exibidos no seletor: do atual até 16 anos atrás, mais qualquer ano
  // que já tenha lançamentos (ex: um lançamento antigo), do mais novo ao mais antigo
  List<int> availableYears([Iterable<BookkeepingModel> entries = const []]) {
    final current = DateTime.now().year;
    return {
      for (int i = 0; i <= _previousYears; i++) current - i,
      for (final entry in entries) entry.ano,
      _year,
    }.toList()..sort((a, b) => b.compareTo(a));
  }
}
