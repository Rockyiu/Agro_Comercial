import 'dart:math' as math;

import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/empty_state.dart';
import 'package:agro_comercial/common/widgets/page_hero.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'consolidation_controller.dart';
import 'widgets/year_selector.dart';

class ConsolidationPage extends StatefulWidget {
  const ConsolidationPage({super.key});

  @override
  State<ConsolidationPage> createState() => _ConsolidationPageState();
}

class _ConsolidationPageState extends State<ConsolidationPage> {
  final _controller = locator.get<ConsolidationController>();
  final List<String> _meses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
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

  // Verde para positivo, vermelho para negativo
  static Color _resultColor(double value) => value < 0
      ? AppColors.danger
      : (value > 0 ? AppColors.primary : AppColors.ink);

  @override
  Widget build(BuildContext context) {
    // Tela larga (PC/Tablet) mostra a tabela; celular mostra os meses em cartões
    final bool isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(title: const Text("Consolidação")),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoading) {
            return const CustomCircularProgressIndicator();
          }

          if (_controller.errorMessage != null) {
            return Center(
              child: EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Algo deu errado',
                message: _controller.errorMessage!,
                action: TextButton.icon(
                  onPressed: _controller.carregarCalculos,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                ),
              ),
            );
          }

          final total = _controller.totalGeral;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // Filtro do ano-calendário consolidado
              YearSelector(
                year: _controller.anoSelecionado,
                years: _controller.anosDisponiveis,
                onChanged: _controller.selecionarAno,
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                child: PageHero(
                  icon: Icons.account_balance_rounded,
                  eyebrow: 'Resultado de ${_controller.anoSelecionado}',
                  title: Formatters.currency(total.resultadoMes),
                  subtitle:
                      'Receitas e adiantamentos menos as despesas do ano-calendário.',
                  metrics: [
                    HeroMetric(
                      icon: Icons.south_west_rounded,
                      label: 'Receitas',
                      value: Formatters.currency(total.receitas),
                      scaleDown: true,
                    ),
                    HeroMetric(
                      icon: Icons.north_east_rounded,
                      label: 'Despesas',
                      value: Formatters.currency(total.despesas),
                      scaleDown: true,
                    ),
                    HeroMetric(
                      icon: Icons.block_rounded,
                      label: 'Indedutíveis',
                      value: Formatters.currency(total.despesasNaoDedutiveis),
                      scaleDown: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const FadeSlideIn(
                index: 1,
                child: SectionHeader(
                  title: 'Resultado mês a mês',
                  subtitle: 'Verde: sobra no mês  •  Vermelho: falta',
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                index: 2,
                child: _MonthlyBars(
                  values: [
                    for (final m in _controller.resumoAno) m.resultadoMes,
                  ],
                  labels: _mesesSigla,
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Fechamento mensal'),
              const SizedBox(height: 12),
              if (isDesktop)
                _buildDesktopTable()
              else
                for (var i = 0; i < 12; i++)
                  FadeSlideIn(index: i + 3, child: _buildMonthCardMobile(i)),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // LAYOUT 1: PARA COMPUTADOR E TABLET (A tabela clássica)
  // ===========================================================================
  Widget _buildDesktopTable() {
    const header = TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    );
    const bold = TextStyle(fontWeight: FontWeight.w700);

    DataColumn column(String label, {Color? color}) => DataColumn(
      numeric: label != "Mês",
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: color == null ? header : header.copyWith(color: color),
      ),
    );

    final total = _controller.totalGeral;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.primarySoft),
          columnSpacing: 24,
          horizontalMargin: 16,
          border: const TableBorder(
            horizontalInside: BorderSide(color: AppColors.border),
          ),
          columns: [
            column("Mês"),
            column("Receitas"),
            column("Despesas"),
            column("Desp. Não Dedutíveis"),
            column("Adiantamentos\n(Anos Anteriores)"),
            column("Adiantamentos\n(Ano Atual)"),
            column("Total do Mês\n(Resultado)", color: AppColors.primary),
          ],
          rows: [
            ...List.generate(12, (index) {
              final resumo = _controller.resumoAno[index];
              final double resultado = resumo.resultadoMes;

              return DataRow(
                color: WidgetStateProperty.all(
                  index.isEven ? Colors.transparent : AppColors.background,
                ),
                cells: [
                  DataCell(Text(_mesesSigla[index], style: bold)),
                  DataCell(Text(Formatters.decimal(resumo.receitas))),
                  DataCell(Text(Formatters.decimal(resumo.despesas))),
                  DataCell(
                    Text(Formatters.decimal(resumo.despesasNaoDedutiveis)),
                  ),
                  DataCell(
                    Text(Formatters.decimal(resumo.adiantamentosAnteriores)),
                  ),
                  DataCell(
                    Text(Formatters.decimal(resumo.adiantamentosAtuais)),
                  ),
                  DataCell(
                    Text(
                      Formatters.decimal(resultado),
                      style: bold.copyWith(color: _resultColor(resultado)),
                    ),
                  ),
                ],
              );
            }),
            DataRow(
              color: WidgetStateProperty.all(AppColors.harvestSoft),
              cells: [
                const DataCell(Text("Total", style: bold)),
                DataCell(Text(Formatters.decimal(total.receitas), style: bold)),
                DataCell(Text(Formatters.decimal(total.despesas), style: bold)),
                DataCell(
                  Text(
                    Formatters.decimal(total.despesasNaoDedutiveis),
                    style: bold,
                  ),
                ),
                DataCell(
                  Text(
                    Formatters.decimal(total.adiantamentosAnteriores),
                    style: bold,
                  ),
                ),
                DataCell(
                  Text(
                    Formatters.decimal(total.adiantamentosAtuais),
                    style: bold,
                  ),
                ),
                DataCell(
                  Text(
                    Formatters.decimal(total.resultadoMes),
                    style: bold.copyWith(
                      fontSize: 16,
                      color: _resultColor(total.resultadoMes),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // LAYOUT 2: PARA CELULAR (Lista de Cards Expansíveis)
  // ===========================================================================
  Widget _buildMonthCardMobile(int mesIndex) {
    final resumo = _controller.resumoAno[mesIndex];
    final double resultado = resumo.resultadoMes;
    final bool hasData =
        resultado != 0 || resumo.receitas != 0 || resumo.despesas != 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          enabled: hasData,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasData ? AppColors.primarySoft : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _mesesSigla[mesIndex],
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: hasData ? AppColors.primary : AppColors.inkMuted,
              ),
            ),
          ),
          title: Text(
            _meses[mesIndex],
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          subtitle: Text(
            hasData
                ? "Saldo: ${Formatters.currency(resultado)}"
                : "Sem movimentação",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: hasData ? FontWeight.w700 : FontWeight.w500,
              color: hasData ? _resultColor(resultado) : AppColors.inkMuted,
            ),
          ),
          trailing: hasData ? null : const SizedBox.shrink(),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildMobileDetailRow("Receitas (Cód. 100)", resumo.receitas),
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
            ),
          ],
        ),
      ),
    );
  }

  // Linha auxiliar para os detalhes do Card Mobile
  Widget _buildMobileDetailRow(
    String titulo,
    double valor, {
    bool isSaida = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.inkMuted,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            "${isSaida && valor > 0 ? '- ' : ''}${Formatters.currency(valor)}",
            style: TextStyle(
              fontFamily: 'Inter',
              color: isSaida && valor > 0 ? AppColors.danger : AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// Gráfico de barras do resultado de cada mês (barras crescem ao abrir)
class _MonthlyBars extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const _MonthlyBars({required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    final maxAbs = values.fold(0.0, (m, v) => math.max(m, v.abs()));
    final hasNegative = values.any((v) => v < 0);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: maxAbs == 0
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Sem movimentação neste ano.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            )
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => SizedBox(
                height: 170,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < values.length; i++)
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: _bar(values[i] * t, maxAbs, hasNegative),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              labels[i],
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  // Barra para cima (positivo) ou para baixo (negativo) a partir da linha do zero
  Widget _bar(double value, double maxAbs, bool hasNegative) {
    Widget bar(bool positive) => FractionallySizedBox(
      heightFactor: (value.abs() / maxAbs).clamp(0.0, 1.0),
      widthFactor: 0.56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(positive ? 6 : 0),
            bottom: Radius.circular(positive ? 0 : 6),
          ),
          gradient: LinearGradient(
            begin: positive ? Alignment.bottomCenter : Alignment.topCenter,
            end: positive ? Alignment.topCenter : Alignment.bottomCenter,
            colors: positive
                ? const [AppColors.primary, AppColors.primaryLight]
                : [AppColors.danger, AppColors.danger.withValues(alpha: 0.7)],
          ),
        ),
      ),
    );

    final up = Align(
      alignment: Alignment.bottomCenter,
      child: value > 0 ? bar(true) : const SizedBox.shrink(),
    );
    if (!hasNegative) {
      return Column(
        children: [
          Expanded(child: up),
          const Divider(height: 1, color: AppColors.border),
        ],
      );
    }
    return Column(
      children: [
        Expanded(child: up),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: value < 0 ? bar(false) : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
