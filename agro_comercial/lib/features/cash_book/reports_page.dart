import 'dart:typed_data';
import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
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
    // 1. Garante que os dados financeiros mais recentes estejam calculados
    _consolidationController.carregarCalculos();
    _bookkeepingController.carregarLancamentos();

    // 2. Busca nome e CPF do produtor logado
    await _profileController.loadProfile();
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
    final corPrincipal = PdfColor.fromHex('#4CAF50'); // Verde

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
                headers: [
                  'Data',
                  'Conta',
                  'Histórico',
                  'Valor (R\$)',
                ], // <--- CORRIGIDO AQUI!
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
              appBar: AppBar(
                title: const Text("Visualização"),
                backgroundColor: AppColors.greenlightOne,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
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

  // ===========================================================================
  // COMPONENTE NOVO: CARD INTERATIVO DE SELEÇÃO (Substitui os botões Radio)
  // ===========================================================================
  Widget _buildOpcaoCard(
    int valor,
    String titulo,
    IconData icone,
    bool isMobile,
  ) {
    final selecionado = _opcaoSaida == valor;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _opcaoSaida = valor),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selecionado ? AppColors.greenlightOne : Colors.transparent,
            border: Border.all(
              color: selecionado
                  ? AppColors.greenlightOne
                  : Colors.grey.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icone,
                color: selecionado ? Colors.white : Colors.grey[600],
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                titulo,
                style: TextStyle(
                  color: selecionado ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 12 : 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile && _opcaoSaida == 2) {
      _opcaoSaida = 0;
    }

    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Imprimir Relatórios",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _carregandoDados
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.greenlightOne),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // DADOS DO USUÁRIO REAIS
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: AppColors.greenlightOne,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Produtor: $_nomeUsuario\nCPF: $_cpfUsuario",
                              style: AppTextStyles.inputText.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.greenlightOne,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                      const Divider(height: 32),

                      // SESSÃO 1: CONSOLIDAÇÃO
                      Text(
                        "Consolidação",
                        style: AppTextStyles.smallText.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      CheckboxListTile(
                        title: const Text(
                          "Demonstrativo de Apuração (Resumo Mensal)",
                        ),
                        activeColor: AppColors.greenlightOne,
                        value: _chkApuracao,
                        onChanged: (val) => setState(() => _chkApuracao = val!),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const Divider(height: 32),

                      // SESSÃO 2: LIVRO CAIXA
                      Text(
                        "Livro Caixa",
                        style: AppTextStyles.smallText.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      CheckboxListTile(
                        title: const Text(
                          "Extrato de todos os lançamentos do ano",
                        ),
                        activeColor: AppColors.greenlightOne,
                        value: _chkLivroCaixa,
                        onChanged: (val) =>
                            setState(() => _chkLivroCaixa = val!),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const Divider(height: 32),

                      // SESSÃO 3: OPÇÃO DESEJADA (CARDS MODERNOS)
                      Text(
                        "Ação desejada:",
                        style: AppTextStyles.inputText.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildOpcaoCard(
                            0,
                            "Visualizar",
                            Icons.visibility,
                            isMobile,
                          ),
                          const SizedBox(width: 12),
                          _buildOpcaoCard(
                            1,
                            "Gerar PDF",
                            Icons.picture_as_pdf,
                            isMobile,
                          ),
                          if (!isMobile) ...[
                            const SizedBox(width: 12),
                            _buildOpcaoCard(
                              2,
                              "Imprimir",
                              Icons.print,
                              isMobile,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 40),

                      // BOTÕES DE AÇÃO
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.greenlightOne,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 16,
                              ),
                            ),
                            onPressed: _processarAcao,
                            child: Text(
                              _opcaoSaida == 1
                                  ? "Confirmar PDF"
                                  : (_opcaoSaida == 2
                                        ? "Confirmar Impressão"
                                        : "Abrir Relatório"),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
