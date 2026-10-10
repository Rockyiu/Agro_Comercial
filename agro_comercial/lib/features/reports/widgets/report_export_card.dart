import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/common/widgets/surface_card.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/features/profile/profile_controller.dart';
import 'package:agro_comercial/features/profile/profile_state.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../pdf/report_pdf_builder.dart';
import '../production_report.dart';

// Escolha dos relatórios em PDF e da ação (visualizar, compartilhar, imprimir)
class ReportExportCard extends StatefulWidget {
  final ProductionReport report;
  final AreaDisplay area;

  const ReportExportCard({super.key, required this.report, required this.area});

  @override
  State<ReportExportCard> createState() => _ReportExportCardState();
}

enum _OutputOption { preview, share, print }

class _ReportExportCardState extends State<ReportExportCard> {
  final Set<ReportDocument> _selected = {
    ReportDocument.summaries,
    ReportDocument.plotCost,
    ReportDocument.machineHourCost,
  };
  _OutputOption _output = _OutputOption.preview;
  bool _isGenerating = false;

  // Nome e CPF do produtor para o cabeçalho dos PDFs
  Future<(String, String)> _loadProducer() async {
    final profileController = locator.get<ProfileController>();
    try {
      await profileController.loadProfile();
      final state = profileController.state;
      if (state is ProfileSuccessState) {
        final name = state.profile.name ?? '';
        final cpf = state.profile.cpf ?? '';
        return (
          name.isEmpty ? "Produtor Rural" : name,
          cpf.isEmpty ? "CPF não cadastrado" : Formatters.cpf(cpf),
        );
      }
    } finally {
      profileController.dispose();
    }
    return ("Produtor Rural", "-");
  }

  Future<void> _generate() async {
    if (_selected.isEmpty) {
      context.showWarningSnackBar("Selecione ao menos um relatório.");
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final (name, cpf) = await _loadProducer();
      final bytes = await ReportPdfBuilder(
        report: widget.report,
        area: widget.area,
        producerName: name,
        producerCpf: cpf,
      ).build(_selected);
      if (!mounted) return;

      switch (_output) {
        case _OutputOption.preview:
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text("Visualização")),
                body: PdfPreview(
                  build: (_) => bytes,
                  allowPrinting: true,
                  allowSharing: true,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  pdfFileName: 'relatorio_custo_producao.pdf',
                ),
              ),
            ),
          );
        case _OutputOption.share:
          await Printing.sharePdf(
            bytes: bytes,
            filename: 'relatorio_custo_producao.pdf',
          );
        case _OutputOption.print:
          await Printing.layoutPdf(onLayout: (PdfPageFormat _) async => bytes);
      }
    } catch (e) {
      debugPrint("Erro ao gerar o relatório em PDF: $e");
      if (mounted) context.showErrorSnackBar("Erro ao gerar o relatório.");
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  static IconData _documentIcon(ReportDocument document) => switch (document) {
    ReportDocument.summaries => Icons.space_dashboard_rounded,
    ReportDocument.plotCost => Icons.grid_view_rounded,
    ReportDocument.machineHourCost => Icons.agriculture_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    // Impressão direta só no computador
    if (isMobile && _output == _OutputOption.print) {
      _output = _OutputOption.preview;
    }

    final outputs = [
      (_OutputOption.preview, "Visualizar", Icons.visibility_rounded),
      (_OutputOption.share, "Gerar PDF", Icons.picture_as_pdf_rounded),
      if (!isMobile) (_OutputOption.print, "Imprimir", Icons.print_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final document in ReportDocument.values)
          CheckCard(
            title: document.title,
            subtitle: document.description,
            icon: _documentIcon(document),
            value: _selected.contains(document),
            onChanged: (checked) => setState(() {
              checked ? _selected.add(document) : _selected.remove(document);
            }),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final (option, title, icon) in outputs) ...[
              if (option != _OutputOption.preview) const SizedBox(width: 10),
              Expanded(
                child: OptionCard(
                  icon: icon,
                  label: title,
                  selected: _output == option,
                  onTap: () => setState(() => _output = option),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          icon: _isGenerating
              ? Icons.hourglass_top_rounded
              : switch (_output) {
                  _OutputOption.preview => Icons.description_rounded,
                  _OutputOption.share => Icons.ios_share_rounded,
                  _OutputOption.print => Icons.print_rounded,
                },
          text: _isGenerating
              ? "Gerando relatório..."
              : switch (_output) {
                  _OutputOption.preview => "Abrir Relatório",
                  _OutputOption.share => "Confirmar PDF",
                  _OutputOption.print => "Confirmar Impressão",
                },
          onPressed: _isGenerating ? null : _generate,
        ),
      ],
    );
  }
}
