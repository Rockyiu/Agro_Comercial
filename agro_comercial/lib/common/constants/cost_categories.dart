// Categorias de custo (metodologia OCEPAR) e o grupo de despesa de cada uma
// nos relatórios de custo de produção.

enum ExpenseGroup {
  insumos('Insumos'),
  maquinas('Horas de trator/máquinas'),
  maoDeObra('Mão de obra e diárias'),
  combustivel('Combustível'),
  manutencao('Manutenção'),
  servicosTerceiros('Serviços de terceiros'),
  fretes('Fretes'),
  arrendamento('Arrendamento'),
  seguros('Seguros'),
  analises('Análises e assistência técnica'),
  irrigacao('Irrigação'),
  energia('Energia/água'),
  depreciacao('Depreciação'),
  juros('Juros/financiamentos'),
  colheita('Colheita'),
  secagem('Secagem/armazenagem'),
  comercializacao('Comercialização'),
  impostos('Impostos/taxas'),
  demais('Demais despesas');

  final String label;
  const ExpenseGroup(this.label);
}

class CostCategories {
  CostCategories._();

  static const String variable = 'Variável';
  static const String fixed = 'Fixo';

  static const List<String> types = [variable, fixed];

  static const List<String> variableCategories = [
    'Manutenção de Tratores',
    'Manutenção de Implementos',
    'Combustíveis, lubrificantes e filtros',
    'Aluguel de máquinas',
    'Manutenção de benfeitorias',
    'Mão-de-obra temporária',
    'Serviços contratados',
    'Insumos',
    'Despesas gerais',
    'Assistência técnica',
    'Análises de solo e foliar',
    'Transporte externo',
    'Fretes',
    'Irrigação',
    'Energia elétrica e água',
    'Colheita terceirizada',
    'Recepção, secagem, limpeza',
    'Comercialização',
    'Seguro rural',
    'Juros sobre capital de giro',
    'INSS',
  ];

  static const List<String> fixedCategories = [
    'Depreciação de Máquinas',
    'Depreciação de Benfeitorias',
    'Seguro de Máquinas',
    'Seguro de Benfeitorias',
    'Juros sobre Terras',
    'Juros sobre Máquinas',
    'Juros sobre Benfeitorias',
    'Impostos, taxas e contribuições',
    'Mão-de-obra fixa',
    'Arrendamento',
  ];

  static List<String> byType(String? type) => switch (type) {
    variable => variableCategories,
    fixed => fixedCategories,
    _ => const [],
  };

  // Categorias cuja fórmula resulta em um valor POR HORA de máquina
  // (ex: Depreciação = (Vi - Vs) / Vuh). Elas servem de referência e não
  // entram na soma dos relatórios: o custo das máquinas vem do cadastro de
  // custo de cada máquina multiplicado pelas horas trabalhadas.
  static const Set<String> hourlyRateCategories = {
    'Manutenção de Tratores',
    'Manutenção de Implementos',
    'Depreciação de Máquinas',
    'Seguro de Máquinas',
    'Juros sobre Máquinas',
  };

  static bool isHourlyRate(String category) =>
      hourlyRateCategories.contains(category);

  static const Map<String, ExpenseGroup> _groups = {
    'Combustíveis, lubrificantes e filtros': ExpenseGroup.combustivel,
    'Aluguel de máquinas': ExpenseGroup.servicosTerceiros,
    'Manutenção de benfeitorias': ExpenseGroup.manutencao,
    'Mão-de-obra temporária': ExpenseGroup.maoDeObra,
    'Mão-de-obra fixa': ExpenseGroup.maoDeObra,
    'Serviços contratados': ExpenseGroup.servicosTerceiros,
    'Insumos': ExpenseGroup.insumos,
    'Despesas gerais': ExpenseGroup.demais,
    'Assistência técnica': ExpenseGroup.analises,
    'Análises de solo e foliar': ExpenseGroup.analises,
    'Transporte externo': ExpenseGroup.fretes,
    'Fretes': ExpenseGroup.fretes,
    'Irrigação': ExpenseGroup.irrigacao,
    'Energia elétrica e água': ExpenseGroup.energia,
    'Colheita terceirizada': ExpenseGroup.colheita,
    'Recepção, secagem, limpeza': ExpenseGroup.secagem,
    'Comercialização': ExpenseGroup.comercializacao,
    'Seguro rural': ExpenseGroup.seguros,
    'Seguro de Benfeitorias': ExpenseGroup.seguros,
    'Juros sobre capital de giro': ExpenseGroup.juros,
    'Juros sobre Terras': ExpenseGroup.juros,
    'Juros sobre Benfeitorias': ExpenseGroup.juros,
    'Depreciação de Benfeitorias': ExpenseGroup.depreciacao,
    'Impostos, taxas e contribuições': ExpenseGroup.impostos,
    'INSS': ExpenseGroup.impostos,
    'Arrendamento': ExpenseGroup.arrendamento,
  };

  static ExpenseGroup groupOf(String category) =>
      _groups[category] ?? ExpenseGroup.demais;
}
