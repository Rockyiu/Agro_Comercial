import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
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
                appBar: AppBar(
                  title: const Text("Visualização"),
                  backgroundColor: AppColors.greenlightOne,
                  foregroundColor: Colors.white,
                ),
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

  Widget _buildOutputCard(
    _OutputOption option,
    String title,
    IconData icon,
    bool isMobile,
  ) {
    final selected = _output == option;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _output = option),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.greenlightOne : Colors.transparent,
            border: Border.all(
              color: selected
                  ? AppColors.greenlightOne
                  : Colors.grey.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : Colors.grey[600],
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    // Impressão direta só no computador
    if (isMobile && _output == _OutputOption.print) {
      _output = _OutputOption.preview;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final document in ReportDocument.values)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.greenlightOne,
                title: Text(
                  document.title,
                  style: AppTextStyles.smallText.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  document.description,
                  style: AppTextStyles.smallText.copyWith(fontSize: 12),
                ),
                value: _selected.contains(document),
                onChanged: (checked) => setState(() {
                  checked == true
                      ? _selected.add(document)
                      : _selected.remove(document);
                }),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildOutputCard(
                  _OutputOption.preview,
                  "Visualizar",
                  Icons.visibility,
                  isMobile,
                ),
                const SizedBox(width: 12),
                _buildOutputCard(
                  _OutputOption.share,
                  "Gerar PDF",
                  Icons.picture_as_pdf,
                  isMobile,
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 12),
                  _buildOutputCard(
                    _OutputOption.print,
                    "Imprimir",
                    Icons.print,
                    isMobile,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenlightOne,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isGenerating ? null : _generate,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.description),
              label: Text(switch (_output) {
                _OutputOption.preview => "Abrir Relatório",
                _OutputOption.share => "Confirmar PDF",
                _OutputOption.print => "Confirmar Impressão",
              }, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
