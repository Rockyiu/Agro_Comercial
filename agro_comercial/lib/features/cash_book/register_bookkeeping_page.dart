import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/constants/chart_of_accounts.dart';
import 'package:agro_comercial/common/utils/parsers.dart';
import 'package:agro_comercial/common/widgets/confirm_dialog.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:agro_comercial/services/local_media_service/local_media_service.dart';
import 'package:flutter/foundation.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/surface_card.dart';
import 'package:agro_comercial/locator.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';

import 'bookkeeping_controller.dart';
import '../../common/models/bookkeeping_model.dart';

class RegisterBookkeepingPage extends StatefulWidget {
  final int mesBloqueado; // 0 = Jan, 1 = Fev...
  final String nomeMes;
  final BookkeepingModel? dadosEdicao;
  // Ano sugerido para um lançamento novo (o ano selecionado na Escrituração)
  final int? anoInicial;

  const RegisterBookkeepingPage({
    super.key,
    required this.mesBloqueado,
    required this.nomeMes,
    this.dadosEdicao,
    this.anoInicial,
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
  late int _anoSelecionado = widget.anoInicial ?? DateTime.now().year;
  String? _contaSelecionada;

  // Comprovante (PDF): fica só no aparelho
  final _media = locator.get<LocalMediaService>();
  File? _comprovanteSalvo; // já guardado para este lançamento
  Uint8List? _arquivoPdfUpload; // escolhido agora, gravado ao salvar
  String? _nomeArquivoPdfExibicao;
  bool _removerPdf = false;
  bool _isSaving = false;

  // Plano de Contas (+ a conta já salva, caso ela não exista mais no plano)
  late final List<String> _contasDisponiveis = {
    ...ChartOfAccounts.accountLabels,
    ?widget.dadosEdicao?.conta,
  }.toList();

  @override
  void initState() {
    super.initState();
    _ajustarDiaAoMes();

    // Se estiver no modo de edição, preenche os campos usando o Model
    if (widget.dadosEdicao != null) {
      _diaSelecionado = widget.dadosEdicao!.dia;
      _anoSelecionado = widget.dadosEdicao!.ano;
      _contaSelecionada = widget.dadosEdicao!.conta;
      _obsController.text = widget.dadosEdicao!.historico;
      _valorController.text = widget.dadosEdicao!.valor
          .toStringAsFixed(2)
          .replaceAll('.', ',');

      _carregarComprovante(widget.dadosEdicao!.id);
    }
  }

  Future<void> _carregarComprovante(String? id) async {
    if (id == null) return;
    final arquivo = await _media.receipt(id);
    if (mounted) setState(() => _comprovanteSalvo = arquivo);
  }

  // Quantidade de dias do mês no ano selecionado (fevereiro muda no bissexto)
  int get _diasNoMes =>
      DateTime(_anoSelecionado, widget.mesBloqueado + 2, 0).day;

  // Evita um dia que não existe no mês (ex: 31 em abril, 29/02 em ano comum)
  void _ajustarDiaAoMes() {
    if (_diaSelecionado > _diasNoMes) _diaSelecionado = _diasNoMes;
  }

  Future<void> _escolherPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true, // bytes funcionam no celular, no PC e na web
    );
    final file = result?.files.singleOrNull;
    if (file == null || file.bytes == null || !mounted) return;

    if (file.size > _tamanhoMaximoPdf) {
      context.showErrorSnackBar("O PDF deve ter no máximo 10 MB.");
      return;
    }
    // Todo PDF começa com "%PDF": recusa outros arquivos renomeados
    if (!_ehPdf(file.bytes!)) {
      context.showErrorSnackBar("O arquivo escolhido não é um PDF válido.");
      return;
    }
    setState(() {
      _removerPdf = false;
      _arquivoPdfUpload = file.bytes;
      _nomeArquivoPdfExibicao = file.name;
    });
  }

  static const _tamanhoMaximoPdf = 10 * 1024 * 1024;

  static bool _ehPdf(Uint8List bytes) =>
      bytes.length > 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;

  Future<void> _abrirComprovante() async {
    final arquivo = _comprovanteSalvo;
    if (arquivo == null) return;
    final result = await OpenFilex.open(arquivo.path, type: 'application/pdf');
    if (result.type != ResultType.done && mounted) {
      context.showErrorSnackBar("Nenhum leitor de PDF encontrado no aparelho.");
    }
  }

  Future<void> _excluir() async {
    final confirmado = await showConfirmDialog(
      context,
      title: "Excluir Lançamento",
      message: "Deseja realmente excluir este lançamento do Livro Caixa?",
    );
    if (!confirmado) return;
    final ok = await _controller.excluirLancamentos([widget.dadosEdicao!.id!]);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      context.showErrorSnackBar("Erro ao excluir o lançamento.");
    }
  }

  // Comprovante em PDF: escolher, abrir, trocar ou remover. Fica só no
  // aparelho; na web essa parte não aparece.
  Widget _buildComprovante() {
    if (!_media.isSupported) {
      return const Text(
        "O comprovante em PDF pode ser anexado pelo aplicativo do celular.",
        style: TextStyle(fontFamily: 'Inter', color: AppColors.inkMuted),
      );
    }

    final novo = _nomeArquivoPdfExibicao;
    final salvo = !_removerPdf && novo == null ? _comprovanteSalvo : null;
    final temArquivo = novo != null || salvo != null;

    return SurfaceCard(
      onTap: _escolherPdf,
      selected: temArquivo,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      child: Column(
        children: [
          IconBadge(
            icon: temArquivo
                ? Icons.picture_as_pdf_rounded
                : Icons.upload_file_rounded,
            size: 52,
            color: temArquivo ? Colors.white : AppColors.primary,
            background: temArquivo ? AppColors.primary : AppColors.primarySoft,
          ),
          const SizedBox(height: 10),
          Text(
            novo ??
                (salvo != null
                    ? "Comprovante anexado"
                    : "Anexar comprovante (PDF)"),
            textAlign: TextAlign.center,
            style: AppTextStyles.inputText.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            temArquivo
                ? "Salvo somente neste aparelho. Toque para trocar."
                : "Nota fiscal ou recibo. Fica salvo somente neste aparelho.",
            textAlign: TextAlign.center,
            style: AppTextStyles.smallText.copyWith(color: AppColors.inkMuted),
          ),
          if (temArquivo) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (salvo != null)
                  TextButton.icon(
                    onPressed: _abrirComprovante,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text("Abrir"),
                  ),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _arquivoPdfUpload = null;
                    _nomeArquivoPdfExibicao = null;
                    _removerPdf = _comprovanteSalvo != null;
                  }),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text("Remover"),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdicao = widget.dadosEdicao != null;
    // Do ano atual até 16 anos atrás (+ o ano do lançamento, se for mais antigo)
    final anoAtual = DateTime.now().year;
    final List<int> anosPermitidos = {
      for (int i = 0; i <= 16; i++) anoAtual - i,
      _anoSelecionado,
    }.toList()..sort((a, b) => b.compareTo(a));
    final List<int> diasDoMes = List.generate(_diasNoMes, (index) => index + 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? "Editar Escrituração" : "Nova Escrituração"),
        actions: [
          if (isEdicao)
            IconButton(
              tooltip: 'Excluir lançamento',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _excluir,
            ),
        ],
      ),
      body: _isSaving
          ? const CustomCircularProgressIndicator()
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
                            // Recria o campo quando o dia é ajustado pela
                            // troca de ano (ex: 29/02 -> 28/02)
                            key: ValueKey(
                              'dia_${_anoSelecionado}_$_diaSelecionado',
                            ),
                            decoration: const InputDecoration(labelText: "Dia"),
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
                              filled: true,
                              fillColor: Colors.black12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(labelText: "Ano"),
                            initialValue: _anoSelecionado,
                            items: anosPermitidos
                                .map(
                                  (a) => DropdownMenuItem(
                                    value: a,
                                    child: Text(a.toString()),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => setState(() {
                              _anoSelecionado = val!;
                              _ajustarDiaAoMes();
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Conta (Plano de Contas)",
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
                      validator: (v) {
                        final valor = Parsers.money(v ?? '');
                        if (valor == null) return "Informe um valor válido";
                        if (valor <= 0) {
                          return "O valor deve ser maior que zero";
                        }
                        return null;
                      },
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
                    _buildComprovante(),
                    const SizedBox(height: 40),

                    PrimaryButton(
                      icon: Icons.check_rounded,
                      text: isEdicao
                          ? "Salvar Alterações"
                          : "Confirmar Lançamento",
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isSaving = true);

                          final novoLancamento = BookkeepingModel(
                            id: widget
                                .dadosEdicao
                                ?.id, // Se tiver ID, o controller sabe que é edição
                            dia: _diaSelecionado,
                            mes: widget.mesBloqueado,
                            ano: _anoSelecionado,
                            conta: _contaSelecionada!,
                            historico: _obsController.text.trim(),
                            valor: Parsers.money(_valorController.text)!,
                          );

                          // Envia para o motor salvar no banco!
                          final sucesso = await _controller.salvarLancamento(
                            novoLancamento,
                            arquivoPdf: _arquivoPdfUpload,
                            removerPdf: _removerPdf,
                          );

                          if (context.mounted) {
                            setState(() => _isSaving = false);
                            if (sucesso) {
                              Navigator.pop(
                                context,
                              ); // Volta para a tela principal
                            } else {
                              context.showErrorSnackBar(
                                "Falha ao salvar. Verifique sua conexão.",
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
