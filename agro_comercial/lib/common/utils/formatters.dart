import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  static final _decimal = NumberFormat.decimalPatternDigits(
    locale: 'pt_BR',
    decimalDigits: 2,
  );
  static final _date = DateFormat('dd/MM/yyyy');

  // R$ 1.234,56
  static String currency(double value) => _currency.format(value);

  // 1.234,56 (sem o símbolo da moeda)
  static String decimal(double value) => _decimal.format(value);

  // 31/12/2026
  static String date(int millisecondsSinceEpoch) =>
      _date.format(DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch));

  // 12345678900 -> 123.456.789-00 (o CPF é salvo só com números)
  static String cpf(String cpf) {
    final digits = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 11) return cpf;
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.'
        '${digits.substring(6, 9)}-${digits.substring(9)}';
  }
}
