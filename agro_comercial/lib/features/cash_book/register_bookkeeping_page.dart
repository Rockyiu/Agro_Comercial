import 'dart:io';
import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'bookkeeping_controller.dart';
import '../../common/models/bookkeeping_model.dart';

class RegisterBookkeepingPage extends StatefulWidget {
  final int mesBloqueado; // 0 = Jan, 1 = Fev...
  final String nomeMes;
  final BookkeepingModel?
  dadosEdicao; // CORRIGIDO: Agora recebe o Model correto!

  const RegisterBookkeepingPage({
    super.key,
    required this.mesBloqueado,
    required this.nomeMes,
    this.dadosEdicao,
  });

  @override
  State<RegisterBookkeepingPage> createState() =>
      _RegisterBookkeepingPageState();
}

class _RegisterBookkeepingPageState extends State<RegisterBookkeepingPage> {
  final _formKey = GlobalKey<FormState>();
  final _obsController = TextEditingController();
  final _valorController = TextEditingController();

  // Puxa o Controller para podermos salvar os dados
  final _controller = locator.get<BookkeepingController>();

  int _diaSelecionado = DateTime.now().day;
  int _anoSelecionado = 2026;
  String? _contaSelecionada;

  File? _arquivoPdfUpload;
  String? _nomeArquivoPdfExibicao;
  bool _isSaving = false;

  final List<String> _contasDisponiveis = [
    "101 - Venda de Produtos Agrícolas (Grãos, Hortaliças)",
    "102 - Venda de Produtos Pecuários (Gado, Leite)",
    "103 - Venda de Subprodutos e Derivados",
    "104 - Receitas de Arrendamento Rural",
    "199 - Outras Receitas Rurais",
    "201 - Insumos (Sementes, Fertilizantes, Defensivos)",
    "202 - Combustíveis e Lubrificantes",
    "203 - Manutenção de Maquinário e Implementos",
    "204 - Folha de Pagamento e Encargos (Mão de Obra)",
    "205 - Aquisição de Animais",
    "206 - Compra de Tratores e Equipamentos",
    "299 - Outras Despesas Dedutíveis",
    "301 - Multas e Juros de Mora",
    "302 - Despesas Pessoais do Produtor",
    "303 - Aquisição de Terra Nua",
    "399 - Outras Despesas Não Dedutíveis",
    "401 - Recebidos até ano anterior p/ entrega neste ano",
    "501 - Recebidos neste ano para entrega futura",
  ];

  @override
  void initState() {
    super.initState();
    int ultimoDiaDoMes = DateTime(2026, widget.mesBloqueado + 2, 0).day;
    if (_diaSelecionado > ultimoDiaDoMes) _diaSelecionado = ultimoDiaDoMes;

    // Se estiver no modo de edição, preenche os campos usando o Model
    if (widget.dadosEdicao != null) {
      _diaSelecionado = widget.dadosEdicao!.dia;
      _anoSelecionado = widget.dadosEdicao!.ano;
      _contaSelecionada = widget.dadosEdicao!.conta;
      _obsController.text = widget.dadosEdicao!.historico;
      _valorController.text = widget.dadosEdicao!.valor
          .toStringAsFixed(2)
          .replaceAll('.', ',');

      if (widget.dadosEdicao!.pdfUrl != null) {
        _nomeArquivoPdfExibicao = "Nota_Fiscal_Anexada.pdf";
      }
    }
  }

  void _escolherPdf() {
    // Espaço reservado para a implementação do file_picker
    setState(() {
      _nomeArquivoPdfExibicao =
          "nota_fiscal_${_diaSelecionado}_${widget.nomeMes}.pdf";
      // _arquivoPdfUpload = File('caminho_do_arquivo'); // Lógica futura
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdicao = widget.dadosEdicao != null;
    final List<int> anosPermitidos = List.generate(17, (index) => 2026 - index);
    final List<int> diasDoMes = List.generate(
      DateTime(_anoSelecionado, widget.mesBloqueado + 2, 0).day,
      (index) => index + 1,
    );

    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          isEdicao ? "Editar Escrituração" : "Nova Escrituração",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isEdicao)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () async {
                // Permite apagar a nota de dentro da tela de edição também
                await _controller.excluirLancamentos([widget.dadosEdicao!.id!]);
                if (mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: _isSaving
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.greenlightOne),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DATA DO LANÇAMENTO",
                      style: AppTextStyles.smallText.copyWith(
                        color: AppColors.greenlightOne,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: "Dia",
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _diaSelecionado,
                            items: diasDoMes
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d.toString().padLeft(2, '0')),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _diaSelecionado = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: widget.nomeMes,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: "Mês",
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.black12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: "Ano",
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _anoSelecionado,
                            items: anosPermitidos
                                .map(
                                  (a) => DropdownMenuItem(
                                    value: a,
                                    child: Text(a.toString()),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _anoSelecionado = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Conta (Plano de Contas)",
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _contaSelecionada,
                      hint: const Text("Selecione a categoria"),
                      items: _contasDisponiveis
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _contaSelecionada = val),
                      validator: (v) =>
                          v == null ? "Selecione uma conta" : null,
                    ),
                    const SizedBox(height: 24),

                    CustomTextFormField(
                      controller: _obsController,
                      labelText: "Histórico / Observação",
                      hintText:
                          "Detalhe o tipo de operação (Ex: Compra de 50 sacos de semente)",
                      validator: (v) =>
                          v!.isEmpty ? "Preencha o histórico" : null,
                    ),
                    const SizedBox(height: 24),

                    CustomTextFormField(
                      controller: _valorController,
                      labelText: "Valor (R\$)",
                      hintText: "0,00",
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) => v!.isEmpty ? "Preencha o valor" : null,
                    ),
                    const SizedBox(height: 32),

                    Text(
                      "COMPROVANTE (OPCIONAL)",
                      style: AppTextStyles.smallText.copyWith(
                        color: AppColors.greenlightOne,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _escolherPdf,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.05),
                          border: Border.all(
                            color: Colors.red,
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _nomeArquivoPdfExibicao == null
                                  ? Icons.picture_as_pdf
                                  : Icons.check_circle,
                              size: 40,
                              color: _nomeArquivoPdfExibicao == null
                                  ? Colors.red
                                  : AppColors.greenlightOne,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _nomeArquivoPdfExibicao ??
                                  "Anexar Nota Fiscal (PDF)",
                              style: AppTextStyles.inputText.copyWith(
                                color: _nomeArquivoPdfExibicao == null
                                    ? Colors.red
                                    : AppColors.greenlightOne,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    PrimaryButton(
                      text: isEdicao
                          ? "Salvar Alterações"
                          : "Confirmar Lançamento",
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isSaving = true);

                          // Transforma a string de valor para um double aceito pelo Dart
                          String valorTratado = _valorController.text
                              .replaceAll('.', '')
                              .replaceAll(',', '.');

                          final novoLancamento = BookkeepingModel(
                            id: widget
                                .dadosEdicao
                                ?.id, // Se tiver ID, o controller sabe que é edição
                            dia: _diaSelecionado,
                            mes: widget.mesBloqueado,
                            ano: _anoSelecionado,
                            conta: _contaSelecionada!,
                            historico: _obsController.text.trim(),
                            valor: double.tryParse(valorTratado) ?? 0.0,
                            pdfUrl: widget.dadosEdicao?.pdfUrl,
                          );

                          // Envia para o motor salvar no banco!
                          final sucesso = await _controller.salvarLancamento(
                            novoLancamento,
                            arquivoPdf: _arquivoPdfUpload,
                          );

                          if (mounted) {
                            setState(() => _isSaving = false);
                            if (sucesso) {
                              Navigator.pop(
                                context,
                              ); // Volta para a tela principal
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Falha ao salvar. Verifique sua conexão.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
