import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agro_comercial/common/models/machine_cost_data.dart';
import 'package:agro_comercial/common/utils/area_units.dart';
import 'package:agro_comercial/common/widgets/machine_cost_fields.dart';
import 'package:agro_comercial/features/reports/production_report.dart';
import 'package:agro_comercial/features/reports/widgets/management_dashboard.dart';

import 'support/sample_report.dart';

// Tela de celular pequena, para pegar textos estourando a largura
Future<void> _pumpPhone(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('painel gerencial cabe na tela do celular', (tester) async {
    await _pumpPhone(
      tester,
      ManagementDashboard(
        report: buildSampleReport(),
        area: const AreaDisplay(AreaUnits.alqueire),
      ),
    );

    expect(find.text('Painel gerencial'), findsOneWidget);
    expect(find.text('Talhão 12'), findsOneWidget);
    expect(find.text('Resumo por cultura'), findsOneWidget);

    // Abre o detalhe de um talhão
    await tester.tap(find.text('Talhão 12'));
    await tester.pumpAndSettle();
    expect(find.text('Custo por sc'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bloco de custo da máquina mostra o cálculo ao vivo', (
    tester,
  ) async {
    final controllers = MachineCostControllers(
      const MachineCostData(
        acquisitionValue: 1870399.42,
        scrapPercent: 20,
        usefulLifeHours: 10000,
        maintenancePercent: 100,
      ),
    );
    addTearDown(controllers.dispose);

    await _pumpPhone(
      tester,
      Form(
        child: MachineCostFields(controllers: controllers, isMotorized: true),
      ),
    );

    // Começa aberto porque a máquina já tem dados
    // O formato de moeda usa espaço não separável entre "R$" e o valor
    expect(find.textContaining('336,67'), findsOneWidget);

    controllers.fullyDepreciated = true;
    controllers.maintenancePercent.text = '50';
    await tester.pump();
    // Sem depreciação, manutenção/h e total/h ficam iguais
    expect(find.textContaining('93,52'), findsNWidgets(2));

    final data = controllers.toCostData()!;
    expect(data.maintenancePercent, 50);
    expect(data.depreciationPerHour, 0);
    expect(tester.takeException(), isNull);
  });
}
