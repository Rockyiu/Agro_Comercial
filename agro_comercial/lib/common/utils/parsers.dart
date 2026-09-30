class Parsers {
  Parsers._();

  // Aceita tanto "1,5" quanto "1.5" (teclado brasileiro usa vírgula)
  static double? decimal(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));
}
