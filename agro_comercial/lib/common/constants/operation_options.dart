// Opções usadas nos formulários de Operações e de Vistorias/Aplicações

class OperationOptions {
  OperationOptions._();

  static const List<String> operationTypes = [
    'Pulverização - dessecação',
    'Pulverização - pós emergente',
    'Pulverização - pré emergente',
    'Pulverização - pragas e doenças',
    'Pulverização - herbicidas',
    'Pulverização - biológicos',
    'Pulverização - bioestimulantes',
    'Adubação - manual',
    'Adubação - tratorizada',
    'Semeadura - manual',
    'Semeadura - tratorizada',
    'Plantio - manual',
    'Plantio - tratorizado',
    'Poda - manual',
    'Poda - tratorizada',
    'Gradeação - tratorizada',
    'Subsolagem - tratorizada',
    'Escarificação - tratorizada',
    'Desbrota - manual',
    'Irrigação - gotejamento',
    'Irrigação - pivô',
    'Irrigação - aspersão',
    'Capina - manual',
    'Roçadeira - manual',
    'Roçadeira - tratorizada',
    'Trincha - tratorizada',
    'Soprador arruador - tratorizado',
    'Arruação - manual',
    'Colheita - manual',
    'Colheita - mecanizada',
    'Enterrio de mudas - manual',
    'Enterrio de mudas - mecanizada',
    'Serviços diversos - manual',
    'Serviços diversos - tratorizado',
    'Trabalho administrativo - geral',
    'Trabalho administrativo - gerencial',
    'Conserto de máquinas e equipamentos - individual',
    'Manutenção de máquinas e equipamentos - individual',
  ];

  static const List<String> dosageUnits = [
    'L',
    'ml',
    'kg',
    'g',
    'mg',
    'un',
    'm',
    'saco',
    'tambor',
  ];

  // Tipos de lançamento de campo
  static const String inspection = 'Vistoria';
  static const String application = 'Aplicação';

  static const List<String> fieldConditions = [
    'Excelente',
    'Atenção',
    'Crítico',
  ];

  // Máximo de produtos em uma mesma operação
  static const int maxProducts = 10;

  // Unidade sugerida para a dose a partir da unidade do estoque
  // (produto em L -> dose em ml; produto em kg -> dose em g)
  static String defaultDosageUnitFor(String productUnit) {
    if (productUnit == 'L' || productUnit == 'ml') return 'ml';
    if (productUnit == 'kg' || productUnit == 'g') return 'g';
    return productUnit;
  }
}
