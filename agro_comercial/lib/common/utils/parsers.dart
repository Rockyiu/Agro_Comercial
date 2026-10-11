class Parsers {
  Parsers._();

  // Aceita tanto "1,5" quanto "1.5" (teclado brasileiro usa vírgula)
  static double? decimal(String text) =>
      _finite(double.tryParse(text.trim().replaceAll(',', '.')));

  // "NaN" e "Infinity" também são aceitos pelo double.tryParse
  static double? _finite(double? value) =>
      value != null && value.isFinite ? value : null;

  // Valor em reais digitado de qualquer jeito comum:
  // "1.500,50", "1500,50", "1500.50", "1.500", "R$ 1.500,50"
  //
  // Com vírgula, o ponto é separador de milhar. Sem vírgula, o ponto só é
  // milhar quando aparece mais de uma vez ou é seguido de exatamente 3
  // dígitos no final ("1.500"); senão é a casa decimal ("1500.50").
  static double? money(String text) {
    var value = text.trim().replaceAll(RegExp(r'[R$\s]'), '');
    if (value.isEmpty) return null;

    if (value.contains(',')) {
      value = value.replaceAll('.', '').replaceAll(',', '.');
    } else if ('.'.allMatches(value).length > 1 ||
        RegExp(r'\.\d{3}$').hasMatch(value)) {
      value = value.replaceAll('.', '');
    }
    return _finite(double.tryParse(value));
  }
}
