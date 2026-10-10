import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/models/bookkeeping_model.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:agro_comercial/common/widgets/confirm_dialog.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/empty_state.dart';
import 'package:agro_comercial/common/widgets/surface_card.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'bookkeeping_controller.dart';
import 'bookkeeping_state.dart';
import 'cash_book_year_controller.dart';
import 'register_bookkeeping_page.dart';
import 'widgets/year_selector.dart';

class BookkeepingPage extends StatefulWidget {
  const BookkeepingPage({super.key});

  @override
  State<BookkeepingPage> createState() => _BookkeepingPageState();
}

class _BookkeepingPageState extends State<BookkeepingPage>
    with SingleTickerProviderStateMixin {
  final _controller = locator.get<BookkeepingController>();
  // Ano-calendário compartilhado com Consolidação e Relatórios
  final _yearController = locator.get<CashBookYearController>();

  // Abas dos meses (arrastar a lista também troca o mês)
  late TabController _tabController;

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

  final Set<String> _itensSelecionados = {};

  @override
  void initState() {
    super.initState();
    // Inicia na aba do mês atual (0 a 11)
    _tabController = TabController(
      length: 12,
      vsync: this,
      initialIndex: DateTime.now().month - 1,
    );

    _tabController.addListener(_refresh);
    _yearController.addListener(_refresh);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.carregarLancamentos();
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // O controller do ano é compartilhado (singleton): só remove o listener
    _yearController.removeListener(_refresh);
    _tabController.dispose();
    super.dispose();
  }

  // "JANEIRO" -> "Janeiro"
  String _nomeMes(int index) =>
      _meses[index][0] + _meses[index].substring(1).toLowerCase();

  Widget _buildYearSelector() {
    // Reconstrói quando os lançamentos carregam (anos antigos entram na lista)
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        return YearSelector(
          year: _yearController.year,
          years: _yearController.availableYears(
            state is BookkeepingSuccessState ? state.lancamentos : const [],
          ),
          onChanged: (ano) {
            // Seleções de outro ano não fazem sentido no ano novo
            _itensSelecionados.clear();
            _yearController.changeYear(ano);
          },
        );
      },
    );
  }

  void _toggleSelecao(String id) {
    setState(() {
      if (_itensSelecionados.contains(id)) {
        _itensSelecionados.remove(id);
      } else {
        _itensSelecionados.add(id);
      }
    });
  }

  Future<void> _confirmarExclusao() async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Excluir Lançamentos",
      message:
          "Deseja realmente excluir ${_itensSelecionados.length} lançamento(s)?",
    );
    if (confirmed && mounted) _excluirSelecionados();
  }

  Future<void> _excluirSelecionados() async {
    await _controller.excluirLancamentos(_itensSelecionados.toList());
    if (!mounted) return;

    setState(() => _itensSelecionados.clear());

    // Só confirma o sucesso se a exclusão realmente deu certo
    final state = _controller.state;
    if (state is BookkeepingErrorState) {
      context.showErrorSnackBar(state.message);
    } else {
      context.showSuccessSnackBar("Lançamentos excluídos com sucesso!");
    }
  }

  Future<void> _abrirRegistro(int mes, {BookkeepingModel? edicao}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterBookkeepingPage(
          mesBloqueado: mes,
          nomeMes: _meses[mes].substring(0, 3), // "JAN", "FEV"...
          dadosEdicao: edicao,
          anoInicial: edicao == null ? _yearController.year : null,
        ),
      ),
    );
    _controller.carregarLancamentos();
  }

  @override
  Widget build(BuildContext context) {
    final selecionando = _itensSelecionados.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            selecionando
                ? "${_itensSelecionados.length} selecionado(s)"
                : "Escrituração",
            key: ValueKey(selecionando),
          ),
        ),
        leading: selecionando
            ? IconButton(
                tooltip: 'Limpar seleção',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(_itensSelecionados.clear),
              )
            : null,
        actions: [
          if (selecionando)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _confirmarExclusao,
            ),
        ],
      ),
      body: Column(
        children: [
          // Ano + meses
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.only(top: 12, bottom: 10),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildYearSelector(),
                ),
                const SizedBox(height: 10),
                _buildMonthTabs(),
              ],
            ),
          ),

          // LISTA DE LANÇAMENTOS
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, child) {
                final state = _controller.state;

                if (state is BookkeepingLoadingState ||
                    state is BookkeepingInitialState) {
                  return const CustomCircularProgressIndicator();
                }

                if (state is BookkeepingErrorState) {
                  return Center(
                    child: EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Algo deu errado',
                      message: state.message,
                      action: TextButton.icon(
                        onPressed: _controller.carregarLancamentos,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tentar novamente'),
                      ),
                    ),
                  );
                }

                if (state is BookkeepingSuccessState) {
                  return TabBarView(
                    controller: _tabController,
                    children: List.generate(12, (indexMes) {
                      final lancamentosDoMes = state.lancamentos
                          .where(
                            (l) =>
                                l.mes == indexMes &&
                                l.ano == _yearController.year,
                          )
                          .toList();
                      return _buildMonth(indexMes, lancamentosDoMes);
                    }),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirRegistro(_tabController.index),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Lançar'),
      ),
    );
  }

  // Meses em "pílulas": a pílula verde desliza junto com a lista
  Widget _buildMonthTabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      splashBorderRadius: BorderRadius.circular(999),
      indicator: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      labelColor: Colors.white,
      unselectedLabelColor: AppColors.inkMuted,
      labelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      tabs: [
        for (var i = 0; i < 12; i++)
          Tab(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(_nomeMes(i).substring(0, 3)),
            ),
          ),
      ],
    );
  }

  Widget _buildMonth(int indexMes, List<BookkeepingModel> lancamentos) {
    final nomeMes = _nomeMes(indexMes);

    if (lancamentos.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 96),
        children: [
          EmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'Nenhum lançamento em $nomeMes',
            message:
                'Toque em Lançar para registrar uma receita ou despesa de $nomeMes de ${_yearController.year}.',
          ),
        ],
      );
    }

    double entradas = 0;
    double saidas = 0;
    for (final l in lancamentos) {
      l.tipo == 'Entrada' ? entradas += l.valor : saidas += l.valor;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        FadeSlideIn(
          child: _MonthSummary(
            title: '$nomeMes de ${_yearController.year}',
            entradas: entradas,
            saidas: saidas,
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: 'Lançamentos',
          subtitle: lancamentos.length == 1
              ? '1 lançamento no mês'
              : '${lancamentos.length} lançamentos no mês',
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < lancamentos.length; i++)
          FadeSlideIn(
            index: i + 1,
            child: _EntryCard(
              item: lancamentos[i],
              selected: _itensSelecionados.contains(lancamentos[i].id),
              onLongPress: () => _toggleSelecao(lancamentos[i].id!),
              onTap: () {
                if (_itensSelecionados.isNotEmpty) {
                  _toggleSelecao(lancamentos[i].id!);
                } else {
                  _abrirRegistro(indexMes, edicao: lancamentos[i]);
                }
              },
            ),
          ),
      ],
    );
  }
}

// Entradas, saídas e saldo do mês
class _MonthSummary extends StatelessWidget {
  final String title;
  final double entradas;
  final double saidas;

  const _MonthSummary({
    required this.title,
    required this.entradas,
    required this.saidas,
  });

  @override
  Widget build(BuildContext context) {
    final saldo = entradas - saidas;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
              StatusChip(
                label: saldo < 0 ? 'Saldo negativo' : 'Saldo positivo',
                icon: saldo < 0
                    ? Icons.trending_down_rounded
                    : Icons.trending_up_rounded,
                color: saldo < 0 ? AppColors.danger : AppColors.primary,
                background: saldo < 0
                    ? AppColors.dangerSoft
                    : AppColors.primarySoft,
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Formatters.currency(saldo),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: saldo < 0 ? AppColors.danger : AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MoneyLine(
                  icon: Icons.south_west_rounded,
                  label: 'Entradas',
                  value: entradas,
                  color: AppColors.primary,
                  background: AppColors.primarySoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MoneyLine(
                  icon: Icons.north_east_rounded,
                  label: 'Saídas',
                  value: saidas,
                  color: AppColors.danger,
                  background: AppColors.dangerSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final Color background;

  const _MoneyLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Formatters.currency(value),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
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

class _EntryCard extends StatelessWidget {
  final BookkeepingModel item;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _EntryCard({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isEntrada = item.tipo == 'Entrada';
    final color = isEntrada ? AppColors.primary : AppColors.danger;
    final data =
        "${item.dia.toString().padLeft(2, '0')}/${(item.mes + 1).toString().padLeft(2, '0')}/${item.ano}";
    // "101 - Venda de Produtos" -> código "101" e nome "Venda de Produtos"
    final partes = item.conta.split(' - ');
    final codigo = partes.length > 1 ? partes.first : null;
    final nome = partes.length > 1 ? partes.skip(1).join(' - ') : item.conta;

    return SurfaceCard(
      selected: selected,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: selected
                ? const IconBadge(
                    key: ValueKey('selected'),
                    icon: Icons.check_rounded,
                    color: Colors.white,
                    background: AppColors.primary,
                  )
                : IconBadge(
                    key: ValueKey(isEntrada),
                    icon: isEntrada
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    color: color,
                    background: isEntrada
                        ? AppColors.primarySoft
                        : AppColors.dangerSoft,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${isEntrada ? '+' : '-'} ${Formatters.currency(item.valor)}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (codigo != null) ...[
                      Text(
                        "Conta $codigo",
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const Text(
                        "  •  ",
                        style: TextStyle(color: AppColors.inkMuted),
                      ),
                    ],
                    Text(
                      data,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    if (item.pdfUrl != null) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.attach_file_rounded,
                        size: 14,
                        color: AppColors.inkMuted,
                      ),
                    ],
                  ],
                ),
                if (item.historico.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.historico,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
