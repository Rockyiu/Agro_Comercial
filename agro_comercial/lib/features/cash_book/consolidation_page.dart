import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'consolidation_controller.dart';

class ConsolidationPage extends StatefulWidget {
  const ConsolidationPage({super.key});

  @override
  State<ConsolidationPage> createState() => _ConsolidationPageState();
}

class _ConsolidationPageState extends State<ConsolidationPage> {
  final _controller = locator.get<ConsolidationController>();
  final List<String> _meses = [
    'JANEIRO',
    'FEVEREIRO',
    'MARÇO',
    'ABRIL',
    'MAIO',
    'JUNHO',
    'JULHO',
    'AGOSTO',
    'SETEMBRO',
    'OUTUBRO',
    'NOVEMBRO',
    'DEZEMBRO',
  ];
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.carregarCalculos();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Verifica se a tela é larga (PC/Tablet) ou estreita (Celular)
    final bool isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Consolidação",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.greenlightOne),
            );
          }

          if (_controller.errorMessage != null) {
            return Center(
              child: Text(
                _controller.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // Decide qual layout renderizar com base no tamanho da tela!
          return isDesktop ? _buildDesktopTable() : _buildMobileList();
        },
      ),
    );
  }

  // ===========================================================================
  // LAYOUT 1: PARA COMPUTADOR E TABLET (A tabela clássica)
  // ===========================================================================
  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppColors.greenlightOne.withValues(alpha: 0.1),
              ),
              columnSpacing: 24,
              horizontalMargin: 16,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                verticalInside: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              columns: [
                DataColumn(
                  label: Text(
                    "Mês",
                    style: AppTextStyles.inputText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    "Receitas",
                    style: AppTextStyles.inputText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    "Despesas",
                    style: AppTextStyles.inputText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    "Desp. Não Dedutíveis",
                    style: AppTextStyles.inputText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    "Adiantamentos\n(Anos Anteriores)",
                    style: AppTextStyles.inputText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    "Adiantamentos\n(Ano Atual)",
                    style: AppTextStyles.inputText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    "Total do Mês\n(Resultado)",
                    style: AppTextStyles.inputText.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.greenlightOne,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              rows: [
                ...List.generate(12, (index) {
                  final resumo = _controller.resumoAno[index];
                  final bool isPar = index % 2 == 0;
                  final double resultado = resumo.resultadoMes;

                  return DataRow(
                    color: WidgetStateProperty.all(
                      isPar
                          ? Colors.transparent
                          : Colors.blue.withValues(alpha: 0.05),
                    ),
                    cells: [
                      DataCell(
                        Text(
                          _mesesSigla[index],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(Text(Formatters.decimal(resumo.receitas))),
                      DataCell(Text(Formatters.decimal(resumo.despesas))),
                      DataCell(
                        Text(Formatters.decimal(resumo.despesasNaoDedutiveis)),
                      ),
                      DataCell(
                        Text(
                          Formatters.decimal(resumo.adiantamentosAnteriores),
                        ),
                      ),
                      DataCell(
                        Text(Formatters.decimal(resumo.adiantamentosAtuais)),
                      ),
                      DataCell(
                        Text(
                          Formatters.decimal(resultado),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: resultado < 0
                                ? Colors.red
                                : (resultado > 0
                                      ? Colors.blue
                                      : Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                DataRow(
                  color: WidgetStateProperty.all(
                    Colors.grey.withValues(alpha: 0.2),
                  ),
                  cells: [
                    const DataCell(
                      Text(
                        "Total",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        Formatters.decimal(_controller.totalGeral.receitas),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(
                        Formatters.decimal(_controller.totalGeral.despesas),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(
                        Formatters.decimal(
                          _controller.totalGeral.despesasNaoDedutiveis,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(
                        Formatters.decimal(
                          _controller.totalGeral.adiantamentosAnteriores,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(
                        Formatters.decimal(
                          _controller.totalGeral.adiantamentosAtuais,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(
                        Formatters.decimal(_controller.totalGeral.resultadoMes),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _controller.totalGeral.resultadoMes < 0
                              ? Colors.red
                              : (_controller.totalGeral.resultadoMes > 0
                                    ? Colors.blue
                                    : Colors.black87),
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

  // ===========================================================================
  // LAYOUT 2: PARA CELULAR (Lista de Cards Expansíveis)
  // ===========================================================================
  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 13, // 1 Card de Total no topo + 12 Cards de Meses
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildTotalCardMobile();
        }

        final mesIndex = index - 1;
        return _buildMonthCardMobile(mesIndex);
      },
    );
  }

  Widget _buildTotalCardMobile() {
    final double resultadoFinal = _controller.totalGeral.resultadoMes;
    final bool isPositivo = resultadoFinal >= 0;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 24),
      color: isPositivo ? AppColors.greenlightOne : Colors.red[700],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "RESULTADO ANUAL",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "R\$ ${Formatters.decimal(resultadoFinal)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white30),
            const SizedBox(height: 8),
            _buildMobileDetailRow(
              "Total Receitas",
              _controller.totalGeral.receitas,
              isWhiteText: true,
            ),
            _buildMobileDetailRow(
              "Total Despesas",
              _controller.totalGeral.despesas,
              isWhiteText: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCardMobile(int mesIndex) {
    final resumo = _controller.resumoAno[mesIndex];
    final double resultado = resumo.resultadoMes;
    final bool hasData =
        resultado != 0 || resumo.receitas != 0 || resumo.despesas != 0;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.lightkGrey.withValues(alpha: 0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.greenlightOne,
          collapsedIconColor: AppColors.grey,
          title: Text(
            _meses[mesIndex],
            style: AppTextStyles.inputText.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            hasData
                ? "Saldo: R\$ ${Formatters.decimal(resultado)}"
                : "Sem movimentação",
            style: TextStyle(
              color: hasData
                  ? (resultado < 0 ? Colors.red : Colors.blue[700])
                  : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: hasData
              ? [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: Column(
                      children: [
                        const Divider(),
                        _buildMobileDetailRow(
                          "Receitas (Cód. 100)",
                          resumo.receitas,
                        ),
                        _buildMobileDetailRow(
                          "Desp. Dedutíveis (Cód. 200)",
                          resumo.despesas,
                          isSaida: true,
                        ),
                        _buildMobileDetailRow(
                          "Desp. Não Dedutíveis (Cód. 300)",
                          resumo.despesasNaoDedutiveis,
                          isSaida: true,
                        ),
                        _buildMobileDetailRow(
                          "Adiantamentos Anteriores",
                          resumo.adiantamentosAnteriores,
                        ),
                        _buildMobileDetailRow(
                          "Adiantamentos Atuais",
                          resumo.adiantamentosAtuais,
                          isSaida: true,
                        ),
                      ],
                    ),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  // Linha auxiliar para os detalhes do Card Mobile
  Widget _buildMobileDetailRow(
    String titulo,
    double valor, {
    bool isWhiteText = false,
    bool isSaida = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                color: isWhiteText ? Colors.white70 : Colors.grey[700],
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            "${isSaida && valor > 0 ? '-' : ''} R\$ ${Formatters.decimal(valor)}",
            style: TextStyle(
              color: isWhiteText
                  ? Colors.white
                  : (isSaida && valor > 0 ? Colors.red : Colors.black87),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
