class UnitConverter {
  UnitConverter._();

  // Converte a quantidade aplicada (na unidade usada na operação) para a
  // unidade em que o produto está cadastrado no estoque.
  // Ex: 500 ml aplicados de um produto cadastrado em L = 0.5 L
  static double convert(double quantity, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return quantity;

    const factors = <String, double>{
      'ml->L': 1 / 1000,
      'L->ml': 1000,
      'g->kg': 1 / 1000,
      'kg->g': 1000,
      'mg->L': 1 / 1000000,
      'mg->kg': 1 / 1000000,
    };

    final factor = factors['$fromUnit->$toUnit'];
    // Unidades sem conversão conhecida são usadas como estão
    return factor == null ? quantity : quantity * factor;
  }
}
