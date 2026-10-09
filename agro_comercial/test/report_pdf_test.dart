import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:agro_comercial/common/utils/area_units.dart';
import 'package:agro_comercial/features/reports/pdf/report_pdf_builder.dart';
import 'package:agro_comercial/features/reports/production_report.dart';

import 'support/sample_report.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera os três relatórios em PDF', () async {
    final bytes = await ReportPdfBuilder(
      report: buildSampleReport(),
      area: const AreaDisplay(AreaUnits.hectare),
      producerName: 'Produtor Teste',
      producerCpf: '123.456.789-00',
    ).build(ReportDocument.values.toSet());

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');

    // REPORT_PDF_OUT=caminho.pdf flutter test test/report_pdf_test.dart
    final out = Platform.environment['REPORT_PDF_OUT'];
    if (out != null) await File(out).writeAsBytes(bytes);
  });
}
