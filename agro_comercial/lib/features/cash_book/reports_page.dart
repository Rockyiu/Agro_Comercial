import 'dart:typed_data';
import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/common/widgets/surface_card.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/locator.dart';
import 'package:agro_comercial/features/profile/profile_controller.dart';
import 'package:agro_comercial/features/profile/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'bookkeeping_controller.dart';
import 'bookkeeping_state.dart';
import 'consolidation_controller.dart';
import 'widgets/year_selector.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // Conectando aos nossos motores de dados reais
  final _consolidationController = locator.get<ConsolidationController>();
  final _bookkeepingController = locator.get<BookkeepingController>();
  final _profileController = locator.get<ProfileController>();

  // Variáveis para armazenar os dados do usuário
  String _cpfUsuario = "Carregando...";
  String _nomeUsuario = "Carregando...";
  bool _carregandoDados = true;

  // Controles dos Checkboxes
  bool _chkApuracao = true;
  bool _chkLivroCaixa = false;

  // Controle da Opção (0 = Visualizar, 1 = PDF, 2 = Imprimir)
  int _opcaoSaida = 0;

  final List<String> _mesesSigla = [
    'JAN',
    'FEV',
    'MAR',
    'ABR',
    'MAI',
    'JUN',
    'JUL',
    'AGO',
    'SET',
    'OUT',
    'NOV',
    'DEZ',
  ];

  @override
  void initState() {
    super.initState();
    _prepararDados();
  }

  Future<void> _prepararDados() async {
    // Dados financeiros mais recentes + nome e CPF do produtor logado.
    // A tela só libera a geração do PDF depois que tudo carregou.
    await Future.wait([
      _consolidationController.carregarCalculos(),
      _bookkeepingController.carregarLancamentos(),
      _profileController.loadProfile(),
    ]);
    if (!mounted) return;

    final state = _profileController.state;
    setState(() {
      if (state is ProfileSuccessState) {
        final cpf = state.profile.cpf;
        _cpfUsuario = (cpf == null || cpf.isEmpty)
            ? "CPF não cadastrado"
            : Formatters.cpf(cpf);
        final nome = state.profile.name;
        _nomeUsuario = (nome == null || nome.isEmpty) ? "Produtor Rural" : nome;
      } else {
        _cpfUsuario = "Erro ao carregar";
        _nomeUsuario = "Erro ao carregar";
      }
      _carregandoDados = false;
    });
  }

  @override
  void dispose() {
    _profileController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // GERADOR DO NOVO DESIGN DE PDF
  // ===========================================================================
  Future<Uint8List> _gerarDocumentoPdf() async {
    final pdf = pw.Document();

    // Cor principal do Agro Comercial para o PDF
    final corPrincipal = PdfColor.fromHex(
      '#0E5E3A',
    ); // Verde lavoura (cor da marca)

    // Widget padrão de Cabeçalho Elegante
    pw.Widget buildCabecalho(String titulo) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                titulo,
                style: pw.TextStyle(
                  color: corPrincipal,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                "Agro Comercial",
                style: pw.TextStyle(
                  color: PdfColors.grey600,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Divider(color: corPrincipal, thickness: 2),
          pw.SizedBox(height: 10),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Produtor: $_nomeUsuario",
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "CPF: $_cpfUsuario",
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "Ano-Calendário",
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      "${_consolidationController.anoSelecionado}",
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: corPrincipal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
        ],
      );
    }

    // 1. RELATÓRIO DE CONSOLIDAÇÃO
    if (_chkApuracao) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape, // Paisagem para caber colunas
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) {
            // Montando os dados reais
            final headers = [
              'Mês',
              'Receitas',
              'Despesas',
              'Desp. Não Dedut.',
              'Adiant. Ant.',
              'Adiant. Atual',
              'Resultado',
            ];
            final data = List<List<String>>.generate(12, (index) {
              final res = _consolidationController.resumoAno[index];
              return [
                _mesesSigla[index],
                Formatters.decimal(res.receitas),
                Formatters.decimal(res.despesas),
                Formatters.decimal(res.despesasNaoDedutiveis),
                Formatters.decimal(res.adiantamentosAnteriores),
                Formatters.decimal(res.adiantamentosAtuais),
                Formatters.decimal(res.resultadoMes),
              ];
            });

            // Adicionando a linha do Total Geral
            data.add([
              'TOTAL',
              Formatters.decimal(_consolidationController.totalGeral.receitas),
              Formatters.decimal(_consolidationController.totalGeral.despesas),
              Formatters.decimal(
                _consolidationController.totalGeral.despesasNaoDedutiveis,
              ),
              Formatters.decimal(
                _consolidationController.totalGeral.adiantamentosAnteriores,
              ),
              Formatters.decimal(
                _consolidationController.totalGeral.adiantamentosAtuais,
              ),
              Formatters.decimal(
                _consolidationController.totalGeral.resultadoMes,
              ),
            ]);

            return [
              buildCabecalho("CONSOLIDAÇÃO DE RECEITAS E DESPESAS"),
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: data,
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration: pw.BoxDecoration(color: corPrincipal),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                  6: pw.Alignment.centerRight,
                },
              ),
            ];
          },
        ),
      );
    }

    // 2. RELATÓRIO DO LIVRO CAIXA DETALHADO
    if (_chkLivroCaixa) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4, // Retrato
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) {
            final state = _bookkeepingController.state;
            List<List<String>> data = [];

            final ano = _consolidationController.anoSelecionado;
            final lancamentosDoAno = [
              if (state is BookkeepingSuccessState)
                ...state.lancamentos.where((l) => l.ano == ano),
            ];

            if (lancamentosDoAno.isNotEmpty) {
              data = lancamentosDoAno.map((l) {
                return [
                  "${l.dia.toString().padLeft(2, '0')}/${(l.mes + 1).toString().padLeft(2, '0')}/${l.ano}",
                  l.conta.split(' - ')[0],
                  l.historico,
                  Formatters.decimal(l.valor),
                ];
              }).toList();
            } else {
              data = [
                ['-', '-', 'Nenhum lançamento encontrado', '-'],
              ];
            }

            return [
              buildCabecalho("EXTRATO DO LIVRO CAIXA"),
              pw.TableHelper.fromTextArray(
                headers: ['Data', 'Conta', 'Histórico', 'Valor (R\$)'],
                data: data,
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration: pw.BoxDecoration(color: corPrincipal),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                cellPadding: const pw.EdgeInsets.all(8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(5),
                  3: const pw.FlexColumnWidth(3),
                },
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                },
              ),
            ];
          },
        ),
      );
    }

    if (!_chkApuracao && !_chkLivroCaixa) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context ctx) => pw.Center(
            child: pw.Text("Nenhum demonstrativo foi selecionado."),
          ),
        ),
      );
    }

    return pdf.save();
  }

  void _processarAcao() async {
    final bytes = await _gerarDocumentoPdf();

    if (_opcaoSaida == 0) {
      // VISUALIZAR
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text("Visualização")),
              body: PdfPreview(
                build: (format) => bytes,
                allowPrinting: true,
                allowSharing: true,
                canChangeOrientation: false,
                canChangePageFormat: false,
              ),
            ),
          ),
        );
      }
    } else if (_opcaoSaida == 1) {
      // GERAR PDF (Salvar/Compartilhar)
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'relatorio_agro_comercial.pdf',
      );
    } else if (_opcaoSaida == 2) {
      // IMPRIMIR (Apenas PC)
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    // Impressão direta só no computador
    if (isMobile && _opcaoSaida == 2) {
      _opcaoSaida = 0;
    }

    final outputs = [
      (0, "Visualizar", Icons.visibility_rounded),
      (1, "Gerar PDF", Icons.picture_as_pdf_rounded),
      if (!isMobile) (2, "Imprimir", Icons.print_rounded),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Demonstrativos")),
      body: _carregandoDados
          ? const CustomCircularProgressIndicator()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    FadeSlideIn(child: _buildProducerCard()),
                    const SizedBox(height: 12),
                    // Ano-calendário dos relatórios (o mesmo da Escrituração
                    // e da Consolidação)
                    ListenableBuilder(
                      listenable: _consolidationController,
                      builder: (context, _) => YearSelector(
                        year: _consolidationController.anoSelecionado,
                        years: _consolidationController.anosDisponiveis,
                        onChanged: _consolidationController.selecionarAno,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionHeader(
                      title: "Demonstrativos",
                      subtitle: "Escolha o que vai no documento",
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      index: 1,
                      child: CheckCard(
                        title: "Demonstrativo de Apuração",
                        subtitle:
                            "Consolidação: resumo mensal de receitas, "
                            "despesas e resultado",
                        icon: Icons.table_chart_rounded,
                        value: _chkApuracao,
                        onChanged: (val) => setState(() => _chkApuracao = val),
                      ),
                    ),
                    FadeSlideIn(
                      index: 2,
                      child: CheckCard(
                        title: "Extrato do Livro Caixa",
                        subtitle:
                            "Todos os lançamentos do ano, com data, "
                            "conta e histórico",
                        icon: Icons.receipt_long_rounded,
                        value: _chkLivroCaixa,
                        onChanged: (val) =>
                            setState(() => _chkLivroCaixa = val),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SectionHeader(title: "Ação desejada"),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (final (valor, titulo, icone) in outputs) ...[
                          if (valor != 0) const SizedBox(width: 10),
                          Expanded(
                            child: OptionCard(
                              icon: icone,
                              label: titulo,
                              selected: _opcaoSaida == valor,
                              onTap: () => setState(() => _opcaoSaida = valor),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      icon: switch (_opcaoSaida) {
                        1 => Icons.ios_share_rounded,
                        2 => Icons.print_rounded,
                        _ => Icons.description_rounded,
                      },
                      text: switch (_opcaoSaida) {
                        1 => "Confirmar PDF",
                        2 => "Confirmar Impressão",
                        _ => "Abrir Relatório",
                      },
                      onPressed: _processarAcao,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Produtor que aparece no cabeçalho dos PDFs
  Widget _buildProducerCard() {
    final inicial = _nomeUsuario.trim().isEmpty
        ? '?'
        : _nomeUsuario.trim()[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: AppColors.brandGradient),
            ),
            child: Text(
              inicial,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "PRODUTOR RURAL",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.harvestDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _nomeUsuario,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  "CPF: $_cpfUsuario",
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
