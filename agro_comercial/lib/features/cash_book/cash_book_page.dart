import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:agro_comercial/common/widgets/page_hero.dart';
import 'package:agro_comercial/common/widgets/surface_card.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'taxpayer_identification_page.dart';
import 'chart_of_accounts_page.dart';
import 'bookkeeping_page.dart';
import 'consolidation_controller.dart';
import 'consolidation_page.dart';
import 'reports_page.dart';
import 'register_bookkeeping_page.dart';

// Aba "Livro Caixa" da Home: resumo do ano e os módulos do LCDPR
class CashBookPage extends StatefulWidget {
  const CashBookPage({super.key});

  @override
  State<CashBookPage> createState() => _CashBookPageState();
}

class _CashBookPageState extends State<CashBookPage> {
  // Mesmo cálculo da Consolidação, para o resumo do ano no topo
  final _consolidation = locator.get<ConsolidationController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consolidation.carregarCalculos();
    });
  }

  // Abre um módulo e atualiza o resumo ao voltar (pode ter lançamento novo)
  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _consolidation.carregarCalculos();
  }

  // Lançamento novo no mês atual, no ano selecionado
  void _newEntry() {
    const months = [
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
    final month = DateTime.now().month - 1;
    _open(
      RegisterBookkeepingPage(
        mesBloqueado: month,
        nomeMes: months[month],
        anoInicial: _consolidation.anoSelecionado,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modules = [
      (
        icon: Icons.edit_document,
        color: AppColors.primary,
        background: AppColors.primarySoft,
        title: 'Escrituração',
        subtitle: 'Lançamentos de receitas e despesas, mês a mês',
        page: const BookkeepingPage() as Widget,
      ),
      (
        icon: Icons.table_chart_rounded,
        color: AppColors.water,
        background: AppColors.waterSoft,
        title: 'Consolidação',
        subtitle: 'Fechamento mensal e resultado do ano',
        page: const ConsolidationPage() as Widget,
      ),
      (
        icon: Icons.print_rounded,
        color: AppColors.harvestDark,
        background: AppColors.harvestSoft,
        title: 'Demonstrativos',
        subtitle: 'Visualizar, exportar em PDF e imprimir',
        page: const ReportsPage() as Widget,
      ),
      (
        icon: Icons.account_tree_rounded,
        color: AppColors.earth,
        background: AppColors.earthSoft,
        title: 'Plano de Contas',
        subtitle: 'Categorias de receitas e despesas rurais',
        page: const ChartOfAccountsPage() as Widget,
      ),
      (
        icon: Icons.badge_rounded,
        color: AppColors.sky,
        background: AppColors.skySoft,
        title: 'Identificação do Contribuinte',
        subtitle: 'Dados do produtor e imóveis rurais explorados',
        page: const TaxpayerIdentificationPage() as Widget,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        FadeSlideIn(
          child: ListenableBuilder(
            listenable: _consolidation,
            builder: (context, _) => _buildHero(),
          ),
        ),
        const SizedBox(height: 24),
        const FadeSlideIn(
          index: 1,
          child: SectionHeader(
            title: 'Módulos',
            subtitle: 'Livro Caixa Digital do Produtor Rural',
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 2 : 1;
            const spacing = 12.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              children: [
                for (var i = 0; i < modules.length; i++)
                  SizedBox(
                    width: width,
                    child: FadeSlideIn(
                      index: i + 2,
                      child: SurfaceCard(
                        onTap: () => _open(modules[i].page),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            IconBadge(
                              icon: modules[i].icon,
                              size: 50,
                              color: modules[i].color,
                              background: modules[i].background,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    modules[i].title,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    modules[i].subtitle,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12.5,
                                      height: 1.35,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.inkMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHero() {
    final total = _consolidation.totalGeral;
    final ready =
        !_consolidation.isLoading && _consolidation.errorMessage == null;
    String money(double value) => ready ? Formatters.currency(value) : '...';
    final result = total.resultadoMes;

    return PageHero(
      icon: Icons.account_balance_wallet_rounded,
      eyebrow: 'Ano-calendário ${_consolidation.anoSelecionado}',
      title: 'Livro Caixa',
      subtitle:
          'Receitas, despesas e apuração do resultado da atividade rural.',
      metrics: [
        HeroMetric(
          icon: Icons.south_west_rounded,
          label: 'Receitas',
          value: money(total.receitas),
          scaleDown: true,
        ),
        HeroMetric(
          icon: Icons.north_east_rounded,
          label: 'Despesas',
          value: money(total.despesas + total.despesasNaoDedutiveis),
          scaleDown: true,
        ),
        HeroMetric(
          icon: Icons.account_balance_rounded,
          label: 'Resultado',
          value: money(result),
          scaleDown: true,
          valueColor: ready && result < 0
              ? const Color(0xFFFFB4A9)
              : AppColors.harvest,
        ),
      ],
      action: FilledButton.icon(
        onPressed: _newEntry,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.harvest,
          foregroundColor: AppColors.onHarvest,
          minimumSize: const Size.fromHeight(48),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo lançamento'),
      ),
    );
  }
}
