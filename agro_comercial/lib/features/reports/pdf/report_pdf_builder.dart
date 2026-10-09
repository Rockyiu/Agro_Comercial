import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../production_report.dart';

// Documentos que podem ser gerados na aba Relatório
enum ReportDocument {
  summaries(
    'Painel gerencial e resumos',
    'Resumo por talhão, por propriedade e por cultura',
  ),
  plotCost(
    'Custo de produção por talhão',
    'Insumos, máquinas, despesas, produção e margem de cada talhão',
  ),
  machineHourCost(
    'Custo da hora-máquina',
    'Depreciação, manutenção, juros, seguro e diesel por máquina',
  );

  final String title;
  final String description;
  const ReportDocument(this.title, this.description);
}

class ReportPdfBuilder {
  final ProductionReport report;
  final AreaDisplay area;
  final String producerName;
  final String producerCpf;

  ReportPdfBuilder({
    required this.report,
    required this.area,
    required this.producerName,
    required this.producerCpf,
  });

  // Mesmo verde dos demonstrativos do Livro Caixa
  static final _green = PdfColor.fromHex('#4CAF50');
  static final _lightGreen = PdfColor.fromHex('#E8F5E9');
  static final _quantity = NumberFormat('#,##0.###', 'pt_BR');

  String get _areaLabel => area.label;

  Future<Uint8List> build(Set<ReportDocument> documents) async {
    final (regular, bold) = await (
      rootBundle.load('assets/fonts/Inter_18pt-Regular.ttf'),
      rootBundle.load('assets/fonts/Inter_18pt-Bold.ttf'),
    ).wait;
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.ttf(regular),
        bold: pw.Font.ttf(bold),
      ),
    );

    if (documents.contains(ReportDocument.summaries)) _addSummaries(pdf);
    if (documents.contains(ReportDocument.plotCost)) _addPlotCosts(pdf);
    if (documents.contains(ReportDocument.machineHourCost)) {
      _addMachineHourCost(pdf);
    }
    if (documents.isEmpty) {
      pdf.addPage(
        pw.Page(
          build: (_) =>
              pw.Center(child: pw.Text("Nenhum relatório foi selecionado.")),
        ),
      );
    }
    return pdf.save();
  }

  // ===========================================================================
  // FORMATAÇÃO
  // ===========================================================================

  static String _money(double value) => Formatters.currency(value);
  static String _number(double value) => Formatters.decimal(value);
  static String _qty(double value) => _quantity.format(value);
  static String _date(int? ts) => ts == null ? '-' : Formatters.date(ts);
  static String _optional(double? value, [String suffix = '']) =>
      value == null ? '-' : "${_number(value)}$suffix";
  static String _optionalMoney(double? value) =>
      value == null ? '-' : _money(value);

  // Unidade da produção por área (ex: "sc/ha")
  String _perArea(String? unit) => unit == null ? '' : " $unit/$_areaLabel";

  // ===========================================================================
  // ELEMENTOS COMUNS
  // ===========================================================================

  pw.Widget _header(String title) {
    final farms = report.farms.map((f) => f.name).join(', ');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  color: _green,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(
              "Agro Comercial",
              style: pw.TextStyle(
                color: PdfColors.grey600,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.Divider(color: _green, thickness: 2),
        pw.Container(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          padding: const pw.EdgeInsets.all(10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Produtor: $producerName",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "CPF: $producerCpf",
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      "Propriedade(s): $farms",
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "Período",
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    report.period.label,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        "Gerado em ${Formatters.date(DateTime.now().millisecondsSinceEpoch)}"
        "  •  Página ${context.pageNumber} de ${context.pagesCount}",
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
      ),
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
      child: pw.Text(
        text.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: _green,
        ),
      ),
    );
  }

  // Tabela padrão: cabeçalho verde, primeira coluna à esquerda e as demais
  // à direita (números). [totalRow] sai em negrito no final.
  pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    List<String>? totalRow,
    Map<int, pw.TableColumnWidth>? columnWidths,
    Set<int> leftAligned = const {0},
    double fontSize = 7.5,
  }) {
    final data = [...rows, ?totalRow];
    // O cabeçalho é a linha 0, então a última linha de dados é data.length
    final totalRowNum = totalRow == null ? -1 : data.length;
    final cellStyle = pw.TextStyle(fontSize: fontSize);
    final totalStyle = cellStyle.copyWith(fontWeight: pw.FontWeight.bold);
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: fontSize,
      ),
      headerDecoration: pw.BoxDecoration(color: _green),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      cellStyle: cellStyle,
      textStyleBuilder: (_, _, rowNum) =>
          rowNum == totalRowNum ? totalStyle : cellStyle,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      columnWidths: columnWidths,
      headerAlignment: pw.Alignment.center,
      cellAlignments: {
        for (var i = 0; i < headers.length; i++)
          i: leftAligned.contains(i)
              ? pw.Alignment.centerLeft
              : pw.Alignment.centerRight,
      },
      cellDecoration: (_, _, rowNum) => rowNum == totalRowNum
          ? pw.BoxDecoration(color: _lightGreen)
          : const pw.BoxDecoration(),
    );
  }

  // Quadro de indicadores (ex: custo total, custo/ha, margem)
  pw.Widget _kpis(List<(String, String)> items) {
    return pw.Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (label, value) in items)
          pw.Container(
            width: 120,
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: _lightGreen,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  label,
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<(String, String)> _summaryKpis(CostSummary s) {
    final unit = s.production.unit;
    return [
      ("Área", "${_number(area.area(s.areaHa))} $_areaLabel"),
      ("Custo total", _money(s.totalCost)),
      ("Custo por $_areaLabel", _money(area.perArea(s.costPerHa))),
      ("Produção", s.production.format()),
      (
        "Produtividade",
        s.productivityPerHa == null
            ? '-'
            : "${_number(area.perArea(s.productivityPerHa!))}${_perArea(unit)}",
      ),
      ("Receita", _money(s.revenue)),
      ("Margem", _money(s.margin)),
      ("Margem por $_areaLabel", _money(area.perArea(s.marginPerHa))),
      ("Custo por ${unit ?? 'unidade'}", _optionalMoney(s.costPerUnit)),
      (
        "Ponto de equilíbrio",
        s.breakEvenPerHa == null
            ? '-'
            : "${_number(area.perArea(s.breakEvenPerHa!))}${_perArea(unit)}",
      ),
    ];
  }

  pw.Widget _costComposition(CostSummary s) {
    final total = s.totalCost;
    return _table(
      headers: ['Grupo de despesa', 'Valor', 'R\$/$_areaLabel', '% do custo'],
      rows: [
        for (final entry in s.sortedGroups)
          [
            entry.key.label,
            _money(entry.value),
            _money(area.perArea(s.areaHa > 0 ? entry.value / s.areaHa : 0)),
            total > 0 ? "${_number(entry.value / total * 100)}%" : '-',
          ],
      ],
      totalRow: [
        'TOTAL',
        _money(total),
        _money(area.perArea(s.costPerHa)),
        total > 0 ? '100%' : '-',
      ],
      columnWidths: {0: const pw.FlexColumnWidth(3)},
    );
  }

  pw.Widget _warnings() {
    final messages = report.warnings.messages;
    if (messages.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle("Observações sobre os dados"),
        for (final message in messages)
          pw.Bullet(text: message, style: const pw.TextStyle(fontSize: 7.5)),
      ],
    );
  }

  // ===========================================================================
  // 1. PAINEL GERENCIAL E RESUMOS
  // ===========================================================================

  List<String> _summaryRow(CostSummary s, {bool withFarm = false}) {
    final unit = s.production.unit;
    return [
      s.name,
      if (withFarm) s.subtitle,
      _number(area.area(s.areaHa)),
      _money(s.totalCost),
      _money(area.perArea(s.costPerHa)),
      s.production.format(),
      s.productivityPerHa == null
          ? '-'
          : "${_number(area.perArea(s.productivityPerHa!))}${_perArea(unit)}",
      _money(s.revenue),
      _money(s.margin),
      _money(area.perArea(s.marginPerHa)),
      _optionalMoney(s.costPerUnit),
    ];
  }

  List<String> _summaryHeaders(String first, {bool withFarm = false}) => [
    first,
    if (withFarm) 'Propriedade',
    'Área ($_areaLabel)',
    'Custo total',
    'Custo/$_areaLabel',
    'Produção',
    'Produtividade',
    'Receita',
    'Margem',
    'Margem/$_areaLabel',
    'Custo/unid.',
  ];

  void _addSummaries(pw.Document pdf) {
    final total = report.total;
    final plotSummaries = [for (final p in report.plots) p.summary];
    final multiFarm = report.farms.length > 1;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        footer: _footer,
        build: (context) => [
          _header("PAINEL GERENCIAL - CUSTO DE PRODUÇÃO"),
          _kpis(_summaryKpis(total)),
          _sectionTitle("Composição do custo"),
          _costComposition(total),
          _sectionTitle("Resumo por talhão"),
          _table(
            headers: _summaryHeaders('Talhão', withFarm: multiFarm),
            rows: [
              for (final s in plotSummaries)
                _summaryRow(s, withFarm: multiFarm),
            ],
            leftAligned: multiFarm ? {0, 1} : {0},
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              if (multiFarm) 1: const pw.FlexColumnWidth(2),
            },
          ),
          _sectionTitle("Resumo por propriedade"),
          _table(
            headers: _summaryHeaders('Propriedade'),
            rows: [for (final s in report.byFarm) _summaryRow(s)],
            totalRow: multiFarm ? _summaryRow(total) : null,
            columnWidths: {0: const pw.FlexColumnWidth(2)},
          ),
          _sectionTitle("Resumo por cultura"),
          _table(
            headers: _summaryHeaders('Cultura'),
            rows: [for (final s in report.byCrop) _summaryRow(s)],
            columnWidths: {0: const pw.FlexColumnWidth(2)},
          ),
          _warnings(),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. CUSTO DE PRODUÇÃO POR TALHÃO
  // ===========================================================================

  void _addPlotCosts(pw.Document pdf) {
    for (final plot in report.plots) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          footer: _footer,
          build: (context) => [
            _header("CUSTO DE PRODUÇÃO POR TALHÃO"),
            _plotTitle(plot),
            pw.SizedBox(height: 8),
            _kpis(_summaryKpis(plot.summary)),
            ..._plotInputs(plot),
            ..._plotMachines(plot),
            ..._plotExpenses(plot),
            ..._plotProduction(plot),
            _sectionTitle("Composição do custo"),
            _costComposition(plot.summary),
            if (_hasShared(plot))
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Text(
                  "* Lançado sem talhão: valor rateado pela área do talhão.",
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }

  bool _hasShared(PlotReport plot) =>
      plot.inputs.any((l) => l.isShared) ||
      plot.machines.any((l) => l.isShared) ||
      plot.expenses.any((l) => l.isShared) ||
      plot.production.any((l) => l.isShared);

  static String _shared(String text, bool isShared) =>
      isShared ? "$text *" : text;

  pw.Widget _plotTitle(PlotReport plot) {
    final crop = plot.crop.isEmpty ? '' : "  •  ${plot.crop}";
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      color: _green,
      child: pw.Text(
        "${plot.farmName}  •  ${plot.plotName}$crop  •  "
        "${_number(area.area(plot.areaHa))} $_areaLabel",
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  List<pw.Widget> _plotInputs(PlotReport plot) {
    if (plot.inputs.isEmpty) return [];
    final lines = [...plot.inputs]..sort((a, b) => a.date.compareTo(b.date));
    final total = lines.fold(0.0, (sum, l) => sum + l.total);
    return [
      _sectionTitle("Controle físico dos insumos"),
      _table(
        headers: [
          'Operação / momento',
          'Data',
          'Produto',
          'Formulação',
          'Qtd. utilizada',
          'Dose/$_areaLabel',
          'Preço unit.',
          'Valor total',
        ],
        rows: [
          for (final l in lines)
            [
              _shared(l.operation, l.isShared),
              _date(l.date),
              l.productName,
              l.formulation.isEmpty ? '-' : l.formulation,
              "${_qty(l.quantity)} ${l.unit}",
              plot.areaHa > 0
                  ? "${_qty(area.perArea(l.quantity / plot.areaHa))} ${l.unit}"
                  : '-',
              l.unitPrice == null ? 'sem preço' : _money(l.unitPrice!),
              _money(l.total),
            ],
        ],
        totalRow: ['TOTAL INSUMOS', '', '', '', '', '', '', _money(total)],
        leftAligned: {0, 1, 2, 3},
        columnWidths: {
          0: const pw.FlexColumnWidth(2.4),
          1: const pw.FlexColumnWidth(1.3),
          2: const pw.FlexColumnWidth(2),
          3: const pw.FlexColumnWidth(1.8),
        },
        fontSize: 7,
      ),
    ];
  }

  List<pw.Widget> _plotMachines(PlotReport plot) {
    if (plot.machines.isEmpty) return [];
    final lines = [...plot.machines]..sort((a, b) => a.date.compareTo(b.date));
    final hours = lines.fold(0.0, (sum, l) => sum + l.hours);
    final fixed = lines.fold(0.0, (sum, l) => sum + l.fixedCost);
    final fuel = lines.fold(0.0, (sum, l) => sum + l.fuelCost);
    return [
      _sectionTitle("Horas de máquinas e combustível"),
      _table(
        headers: [
          'Operação',
          'Data',
          'Máquina / implemento',
          'Horas',
          'R\$/hora',
          'Deprec. + manut.',
          'Diesel',
        ],
        rows: [
          for (final l in lines)
            [
              _shared(l.operation, l.isShared),
              _date(l.date),
              l.machineName,
              _qty(l.hours),
              _money(l.costPerHour),
              _money(l.fixedCost),
              _money(l.fuelCost),
            ],
        ],
        totalRow: [
          'TOTAL MÁQUINAS',
          '',
          '',
          _qty(hours),
          '',
          _money(fixed),
          _money(fuel),
        ],
        leftAligned: {0, 1, 2},
        columnWidths: {
          0: const pw.FlexColumnWidth(2.4),
          1: const pw.FlexColumnWidth(1.3),
          2: const pw.FlexColumnWidth(2.4),
        },
        fontSize: 7,
      ),
    ];
  }

  List<pw.Widget> _plotExpenses(PlotReport plot) {
    if (plot.expenses.isEmpty) return [];
    final lines = [...plot.expenses]
      ..sort((a, b) => a.group.index.compareTo(b.group.index));
    final total = lines.fold(0.0, (sum, l) => sum + l.value);
    return [
      _sectionTitle("Despesas"),
      _table(
        headers: ['Grupo', 'Descrição', 'Data', 'Valor'],
        rows: [
          for (final l in lines)
            [
              l.group.label,
              _shared(l.description, l.isShared),
              _date(l.date),
              _money(l.value),
            ],
        ],
        totalRow: ['TOTAL DESPESAS', '', '', _money(total)],
        leftAligned: {0, 1, 2},
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(4),
          2: const pw.FlexColumnWidth(1.2),
        },
        fontSize: 7,
      ),
    ];
  }

  List<pw.Widget> _plotProduction(PlotReport plot) {
    if (plot.production.isEmpty) return [];
    final lines = [...plot.production]
      ..sort((a, b) => a.date.compareTo(b.date));
    final s = plot.summary;
    return [
      _sectionTitle("Produção obtida"),
      _table(
        headers: ['Data', 'Quantidade', 'Preço de venda', 'Receita'],
        rows: [
          for (final l in lines)
            [
              _shared(_date(l.date), l.isShared),
              "${_qty(l.quantity)} ${l.unit}",
              _money(l.unitPrice),
              _money(l.revenue),
            ],
        ],
        totalRow: [
          'TOTAL',
          s.production.format(),
          _optionalMoney(s.averagePrice),
          _money(s.revenue),
        ],
        fontSize: 7,
      ),
    ];
  }

  // ===========================================================================
  // 3. CUSTO DA HORA-MÁQUINA
  // ===========================================================================

  void _addMachineHourCost(pw.Document pdf) {
    final farms = <String, List<MachineCostRow>>{};
    for (final row in report.machineRows) {
      farms.putIfAbsent(row.farmName, () => []).add(row);
    }
    final multiFarm = farms.length > 1;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        footer: _footer,
        build: (context) => [
          _header("CUSTO DA HORA-MÁQUINA"),
          pw.Text(
            "Preço do diesel: ${report.dieselPrice > 0 ? '${_money(report.dieselPrice)}/L' : 'não informado'}",
            style: const pw.TextStyle(fontSize: 8),
          ),
          if (farms.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 12),
              child: pw.Text("Nenhuma máquina cadastrada."),
            ),
          for (final entry in farms.entries) ...[
            if (multiFarm) _sectionTitle(entry.key),
            pw.SizedBox(height: 6),
            _machineTable(entry.value),
          ],
          _sectionTitle("Como os valores são calculados"),
          ...[
            "Valor de sucata = valor de aquisição x % de sucata.",
            "Depreciação/h = (valor de aquisição - valor de sucata) / vida útil em horas (zerada para bens já depreciados).",
            "Manutenção/h = (% de manutenção x valor de aquisição) / vida útil em horas.",
            "Total/h = depreciação + manutenção (valor usado no custo por talhão).",
            "Juros + seguro/ano = valor atual do bem x (taxa de seguro + juros). Valor fixo anual, rateado pela área.",
            "Diesel/h = consumo (L/h) x preço do diesel.",
          ].map(
            (t) => pw.Bullet(text: t, style: const pw.TextStyle(fontSize: 7.5)),
          ),
        ],
      ),
    );
  }

  pw.Widget _machineTable(List<MachineCostRow> rows) {
    double sum(double Function(MachineCostRow r) value) =>
        rows.fold(0.0, (total, r) => total + value(r));

    String percent(double? value) => _optional(value, '%');

    return _table(
      headers: [
        'Máquina',
        'Valor aquisição',
        'Sucata',
        'Valor sucata',
        'Vida útil (h)',
        'Manut.',
        'Deprec./h',
        'Manut./h',
        'Total/h',
        'Valor atual',
        'Seguro',
        'Juros',
        'Juros+seg./ano',
        'Diesel L/h',
        'Diesel/h',
        'Custo total/h',
        'Horas no período',
        'Custo no período',
      ],
      rows: [
        for (final r in rows)
          if (r.data case final d?)
            [
              r.machine.name,
              _optionalMoney(d.acquisitionValue),
              percent(d.scrapPercent),
              _money(d.scrapValue),
              _optional(d.usefulLifeHours),
              percent(d.maintenancePercent),
              _money(d.depreciationPerHour),
              _money(d.maintenancePerHour),
              _money(d.fixedCostPerHour),
              _optionalMoney(d.marketValue),
              percent(d.insuranceRate),
              percent(d.interestRate),
              _money(d.annualInterestAndInsurance),
              _optional(d.fuelConsumption),
              _money(r.fuelCostPerHour),
              _money(r.totalCostPerHour),
              _qty(r.hoursInPeriod),
              _money(r.costInPeriod),
            ]
          else
            [
              r.machine.name,
              ...List.filled(15, '-'),
              _qty(r.hoursInPeriod),
              '-',
            ],
      ],
      totalRow: [
        'TOTAL',
        ...List.filled(11, ''),
        _money(sum((r) => r.data?.annualInterestAndInsurance ?? 0)),
        '',
        '',
        '',
        _qty(sum((r) => r.hoursInPeriod)),
        _money(sum((r) => r.costInPeriod)),
      ],
      columnWidths: {0: const pw.FlexColumnWidth(3.2)},
      fontSize: 6,
    );
  }
}
