import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'bookkeeping_controller.dart';
import 'bookkeeping_state.dart';
import 'register_bookkeeping_page.dart';

class BookkeepingPage extends StatefulWidget {
  const BookkeepingPage({super.key});

  @override
  // ADICIONADO: SingleTickerProviderStateMixin é necessário para o TabController manual
  State<BookkeepingPage> createState() => _BookkeepingPageState();
}

class _BookkeepingPageState extends State<BookkeepingPage>
    with SingleTickerProviderStateMixin {
  final _controller = locator.get<BookkeepingController>();

  // ADICIONADO: Controlador manual das abas
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

    // Fica escutando as abas. Se o usuário arrastar a tela no celular, atualiza o Dropdown
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.carregarLancamentos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    // ADICIONADO: Verifica a largura da tela. Se for maior que 600 pixels, considera como PC/Tablet
    final bool isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        backgroundColor: _itensSelecionados.isNotEmpty
            ? AppColors.greenlightOne.withValues(alpha: 0.8)
            : AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
        title: _itensSelecionados.isNotEmpty
            ? Text(
                "${_itensSelecionados.length} selecionado(s)",
                style: AppTextStyles.midText20.copyWith(color: Colors.white),
              )
            : Text(
                "Escrituração",
                style: AppTextStyles.midText20.copyWith(color: Colors.white),
              ),
        actions: [
          if (_itensSelecionados.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text(
                      "Excluir Lançamentos",
                      style: TextStyle(color: AppColors.greenlightOne),
                    ),
                    content: Text(
                      "Deseja realmente excluir ${_itensSelecionados.length} lançamento(s)?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancelar",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _excluirSelecionados();
                        },
                        child: const Text(
                          "Sim, excluir",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],

        // NOVIDADE: A TabBar só aparece na AppBar se for Desktop/PC!
        bottom: isDesktop
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: _meses
                    .map((m) => Tab(text: m.substring(0, 3)))
                    .toList(), // Mostra "JAN", "FEV"
              )
            : null,
      ),

      body: Column(
        children: [
          // NOVIDADE: Filtro de Mês (Dropdown) exclusivo para versão de Celular
          if (!isDesktop)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.greenlightOne.withValues(alpha: 0.05),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.greenlightOne.withValues(alpha: 0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _tabController.index,
                    icon: const Icon(
                      Icons.arrow_drop_down_circle,
                      color: AppColors.greenlightOne,
                    ),
                    isExpanded: true,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text(
                          "Mês de Referência: ${_meses[index]}",
                          style: AppTextStyles.inputText.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey,
                          ),
                        ),
                      );
                    }),
                    onChanged: (int? novoMes) {
                      if (novoMes != null) {
                        // Faz a tela deslizar suavemente para o mês escolhido
                        _tabController.animateTo(novoMes);
                      }
                    },
                  ),
                ),
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
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.greenlightOne,
                    ),
                  );
                }

                if (state is BookkeepingErrorState) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (state is BookkeepingSuccessState) {
                  final todosLancamentos = state.lancamentos;

                  return TabBarView(
                    controller: _tabController,
                    children: List.generate(12, (indexMes) {
                      final lancamentosDoMes = todosLancamentos
                          .where((l) => l.mes == indexMes)
                          .toList();

                      if (lancamentosDoMes.isEmpty) {
                        return Center(
                          child: Text(
                            "Nenhum lançamento em ${_meses[indexMes]}.",
                            style: AppTextStyles.inputText.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: lancamentosDoMes.length,
                        itemBuilder: (context, index) {
                          final item = lancamentosDoMes[index];
                          final isSelected = _itensSelecionados.contains(
                            item.id,
                          );
                          final isEntrada = item.tipo == 'Entrada';

                          return Card(
                            elevation: isSelected ? 0 : 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isSelected
                                ? AppColors.greenlightOne.withValues(alpha: 0.1)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.greenlightOne
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ListTile(
                              onLongPress: () => _toggleSelecao(item.id!),
                              onTap: () async {
                                if (_itensSelecionados.isNotEmpty) {
                                  _toggleSelecao(item.id!);
                                } else {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RegisterBookkeepingPage(
                                        mesBloqueado: indexMes,
                                        nomeMes: _meses[indexMes].substring(
                                          0,
                                          3,
                                        ), // Passa "JAN", "FEV" para a tela de registro
                                        dadosEdicao: item,
                                      ),
                                    ),
                                  );
                                  _controller.carregarLancamentos();
                                }
                              },
                              leading: CircleAvatar(
                                backgroundColor: isEntrada
                                    ? Colors.blue.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                                child: Icon(
                                  isEntrada
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: isEntrada ? Colors.blue : Colors.red,
                                ),
                              ),
                              title: Text(
                                item.conta,
                                style: AppTextStyles.inputText.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                "${item.dia.toString().padLeft(2, '0')}/${(indexMes + 1).toString().padLeft(2, '0')}/${item.ano} • ${item.historico}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                Formatters.currency(item.valor),
                                style: AppTextStyles.inputText.copyWith(
                                  color: isEntrada ? Colors.blue : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.greenlightOne,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () async {
          // Pega o índice diretamente do nosso controlador manual
          final tabIndex = _tabController.index;

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterBookkeepingPage(
                mesBloqueado: tabIndex,
                nomeMes: _meses[tabIndex].substring(0, 3),
              ),
            ),
          );
          _controller.carregarLancamentos();
        },
      ),
    );
  }
}
