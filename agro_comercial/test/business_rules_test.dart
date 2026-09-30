import 'package:flutter_test/flutter_test.dart';

import 'package:agro_comercial/common/models/bookkeeping_model.dart';
import 'package:agro_comercial/common/models/cost_model.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/utils/unit_converter.dart';
import 'package:agro_comercial/features/cash_book/cash_book_year_controller.dart';
import 'package:agro_comercial/features/cash_book/consolidation_controller.dart';
import 'package:agro_comercial/services/stock_service/stock_service.dart';

ProductModel _product({
  String id = 'p1',
  double quantity = 2,
  double measure = 20,
  String unit = 'L',
}) {
  return ProductModel(
    id: id,
    name: 'Herbicida $id',
    brand: 'Marca',
    quantity: quantity,
    measure: measure,
    unit: unit,
    category: 'Defensivo',
    warehouseId: 'w1',
    farmId: 'f1',
    attributes: const {},
  );
}

MachineModel _machine({
  String id = 'm1',
  int workingHours = 100,
  bool isMotorized = true,
}) {
  return MachineModel(
    id: id,
    name: 'Trator',
    brand: 'Marca',
    model: 'X',
    power: '100cv',
    workingHours: workingHours,
    warehouseId: 'w1',
    farmId: 'f1',
    isMotorized: isMotorized,
  );
}

void main() {
  group('UnitConverter', () {
    test('converte ml para L e g para kg', () {
      expect(UnitConverter.convert(500, 'ml', 'L'), 0.5);
      expect(UnitConverter.convert(250, 'g', 'kg'), 0.25);
      expect(UnitConverter.convert(2, 'L', 'ml'), 2000);
    });

    test('mantém o valor quando a unidade é a mesma ou desconhecida', () {
      expect(UnitConverter.convert(3, 'L', 'L'), 3);
      expect(UnitConverter.convert(3, 'un', 'L'), 3);
    });
  });

  group('StockService.calculateProducts', () {
    test('retira o consumo convertendo para a unidade do produto', () {
      // 2 embalagens de 20 L = 40 L; consome 10.000 ml = 10 L -> sobra 30 L
      final result = StockService.calculateProducts(
        [_product()],
        restore: const [],
        consume: const [
          ProductUsage(productId: 'p1', quantity: 10000, unit: 'ml'),
        ],
      );
      expect(result.single.totalStock, closeTo(30, 1e-9));
      expect(result.single.quantity, closeTo(1.5, 1e-9));
    });

    test('na edição, estorna o antigo antes de validar o novo consumo', () {
      // Estoque atual 40 L. A operação antiga usou 30 L e a nova usa 60 L:
      // 40 + 30 - 60 = 10 L (válido, mesmo sendo 60 > 40)
      final result = StockService.calculateProducts(
        [_product()],
        restore: const [ProductUsage(productId: 'p1', quantity: 30, unit: 'L')],
        consume: const [ProductUsage(productId: 'p1', quantity: 60, unit: 'L')],
      );
      expect(result.single.totalStock, closeTo(10, 1e-9));
    });

    test('lança exceção quando falta estoque e não devolve nada parcial', () {
      expect(
        () => StockService.calculateProducts(
          [_product(), _product(id: 'p2')],
          restore: const [],
          consume: const [
            ProductUsage(productId: 'p1', quantity: 10, unit: 'L'),
            ProductUsage(productId: 'p2', quantity: 100, unit: 'L'),
          ],
        ),
        throwsA(isA<InsufficientStockException>()),
      );
    });

    test('ignora no estorno produto que não existe mais', () {
      final result = StockService.calculateProducts(
        [_product()],
        restore: const [
          ProductUsage(productId: 'apagado', quantity: 5, unit: 'L'),
        ],
        consume: const [],
      );
      expect(result, isEmpty);
    });
  });

  group('StockService.calculateMachines', () {
    test('estorna as horas antigas e soma as novas', () {
      final result = StockService.calculateMachines(
        [_machine()],
        restore: const [MachineUsage(machineId: 'm1', hours: 10)],
        consume: const [MachineUsage(machineId: 'm1', hours: 4)],
      );
      expect(result.single.workingHours, 94);
    });

    test('não altera máquinas sem motor', () {
      final result = StockService.calculateMachines(
        [_machine(isMotorized: false)],
        restore: const [],
        consume: const [MachineUsage(machineId: 'm1', hours: 4)],
      );
      expect(result, isEmpty);
    });

    test('horímetro nunca fica negativo no estorno', () {
      final result = StockService.calculateMachines(
        [_machine(workingHours: 3)],
        restore: const [MachineUsage(machineId: 'm1', hours: 10)],
        consume: const [],
      );
      expect(result.single.workingHours, 0);
    });
  });

  group('Formatters', () {
    test('formata CPF salvo só com números', () {
      expect(Formatters.cpf('12345678900'), '123.456.789-00');
      expect(Formatters.cpf('123'), '123');
    });

    test('formata valores no padrão brasileiro', () {
      expect(Formatters.decimal(1234.5), '1.234,50');
      expect(Formatters.decimal(-100000), '-100.000,00');
    });
  });

  test('CostModel reconhece categorias de mão de obra', () {
    expect(CostModel.isLaborCategory('Mão-de-obra temporária'), isTrue);
    expect(CostModel.isLaborCategory('Mão-de-obra fixa'), isTrue);
    expect(CostModel.isLaborCategory('Insumos'), isFalse);
  });

  test('ResumoMensal soma cada conta na coluna do seu grupo', () {
    final resumo = ResumoMensal()
      ..adicionar('101', 1000)
      ..adicionar('201', 300)
      ..adicionar('301', 100)
      ..adicionar('999', 50); // conta desconhecida é ignorada
    expect(resumo.receitas, 1000);
    expect(resumo.despesas, 300);
    expect(resumo.despesasNaoDedutiveis, 100);
    expect(resumo.resultadoMes, 600);
  });

  test('Seletor de ano: ano atual, 16 anteriores e anos com lançamentos', () {
    final atual = DateTime.now().year;
    final antigo = BookkeepingModel(
      dia: 1,
      mes: 0,
      ano: atual - 30,
      conta: '101',
      historico: 'Lançamento antigo',
      valor: 10,
    );

    final anos = CashBookYearController().availableYears([antigo]);

    expect(anos.first, atual); // mais novo primeiro
    expect(anos, contains(atual - 16));
    expect(anos, isNot(contains(atual - 17)));
    expect(anos.last, atual - 30); // ano de um lançamento antigo também aparece
  });
}
