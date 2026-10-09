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
  static final _hours = NumberFormat('#,##0.#', 'pt_BR');
  static final _date = DateFormat('dd/MM/yyyy');

  // R$ 1.234,56
  static String currency(double value) => _currency.format(value);

  // 1.234,56 (sem o símbolo da moeda)
  static String decimal(double value) => _decimal.format(value);

  // 1.500,4 h (horímetro, até 1 casa decimal)
  static String hours(double value) => "${_hours.format(value)}h";

  // Valor para preencher um campo de texto editável: sem separador de
  // milhar e com vírgula (1500.0 -> "1500"; 0.125 -> "0,125")
  static String editable(double value) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
    return text.replaceAll('.', ',');
  }

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
