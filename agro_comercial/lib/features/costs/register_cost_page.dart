import 'package:flutter/material.dart';

import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/constants/cost_categories.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/utils/parsers.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/common/models/cost_model.dart';
import 'package:agro_comercial/locator.dart';

import 'cost_controller.dart';
import 'cost_state.dart';

class RegisterCostPage extends StatefulWidget {
  final CostModel? costToEdit;

  const RegisterCostPage({super.key, this.costToEdit});

  @override
  State<RegisterCostPage> createState() => _RegisterCostPageState();
}

class _RegisterCostPageState extends State<RegisterCostPage> {
  final _formKey = GlobalKey<FormState>();
  final _costController = locator.get<CostController>();

  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isCollaborator = true; // restritivo até confirmar o perfil

  String? _selectedType;
  String? _selectedCategory;
  String? _selectedPlot; // null = fazenda inteira (rateio por área)
  late DateTime _costDate = widget.costToEdit != null
      ? DateTime.fromMillisecondsSinceEpoch(widget.costToEdit!.dateTimestamp)
      : DateTime.now();

  final _farm = locator.get<FarmController>().selectedFarm;

  // Talhão do custo em edição, com o nome atual (se foi renomeado)
  late final String? _editingPlot =
      _farm?.currentPlotName(
        id: widget.costToEdit?.plotId,
        name: widget.costToEdit?.plotName,
      ) ??
      widget.costToEdit?.plotName;

  // Talhões da fazenda ativa + o do custo em edição (se foi removido)
  late final List<String> _plots = {
    ...?_farm?.plotNames,
    if (_editingPlot?.isNotEmpty ?? false) _editingPlot!,
  }.toList();

  final _valueController = TextEditingController();
  final _obsController = TextEditingController();

  final _viController = TextEditingController();
  final _vsController = TextEditingController();
  final _vmController = TextEditingController();
  final _vtController = TextEditingController();
  final _vuhController = TextEditingController();
  final _vuaController = TextEditingController();
  final _uahController = TextEditingController();
  final _rController = TextEditingController();

  List<String> get _currentCategories {
    final categories = List<String>.of(CostCategories.byType(_selectedType));
    if (_isCollaborator) {
      categories.removeWhere(CostModel.isLaborCategory);
    }
    return categories;
  }

  @override
  void initState() {
    super.initState();
    _loadUserRoleAndData();
  }

  Future<void> _loadUserRoleAndData() async {
    final isCollaborator = await _costController.isCurrentUserCollaborator();
    if (!mounted) return;

    final cost = widget.costToEdit;
    setState(() {
      _isCollaborator = isCollaborator;
      _selectedType = cost?.type ?? CostCategories.variable;
      if (_editingPlot?.isNotEmpty ?? false) _selectedPlot = _editingPlot;

      if (cost != null) {
        _selectedCategory = cost.category;
        _valueController.text = cost.value.toString();
        _obsController.text = cost.observation ?? '';

        // Preenche os campos da fórmula com os valores usados no cálculo
        final calcData = cost.calculationData ?? {};
        final calcFields = {
          'vi': _viController,
          'vs': _vsController,
          'vuh': _vuhController,
          'vm': _vmController,
          'uah': _uahController,
          'vua': _vuaController,
          'vt': _vtController,
          'r': _rController,
        };
        calcFields.forEach((key, controller) {
          if (calcData.containsKey(key)) {
            controller.text = calcData[key].toString();
          }
        });
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _valueController.dispose();
    _obsController.dispose();
    _viController.dispose();
    _vsController.dispose();
    _vmController.dispose();
    _vtController.dispose();
    _vuhController.dispose();
    _vuaController.dispose();
    _uahController.dispose();
    _rController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _costDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _costDate = picked);
  }

  // Aceita "1.500.000,00", "1500000" ou "7.5" (valores, horas e taxas)
  double _parse(TextEditingController controller) =>
      Parsers.money(controller.text) ?? 0.0;

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          "Excluir Custo",
          style: AppTextStyles.midText20.copyWith(
            color: AppColors.greenlightOne,
          ),
        ),
        content: const Text(
          "Tem certeza que deseja excluir este lançamento? Esta ação não pode ser desfeita.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: AppColors.inkMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isProcessing = true);
              await _costController.deleteCost(widget.costToEdit!.id!);
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text(
              "Excluir",
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione uma categoria!')),
        );
        return;
      }

      setState(() => _isProcessing = true);

      double finalValue = 0.0;
      Map<String, dynamic> calcData = {};

      if (_selectedCategory == 'Manutenção de Tratores') {
        calcData = {'vi': _parse(_viController), 'vuh': _parse(_vuhController)};
        finalValue = _costController.calcManutencaoTrator(
          calcData['vi'],
          calcData['vuh'],
        );
      } else if (_selectedCategory == 'Manutenção de Implementos') {
        calcData = {
          'vi': _parse(_viController),
          'r': _parse(_rController),
          'vuh': _parse(_vuhController),
        };
        finalValue = _costController.calcManutencaoImplemento(
          calcData['vi'],
          calcData['r'],
          calcData['vuh'],
        );
      } else if (_selectedCategory == 'Depreciação de Máquinas') {
        calcData = {
          'vi': _parse(_viController),
          'vs': _parse(_vsController),
          'vuh': _parse(_vuhController),
        };
        finalValue = _costController.calcDepreciacaoMaquina(
          calcData['vi'],
          calcData['vs'],
          calcData['vuh'],
        );
      } else if (_selectedCategory == 'Depreciação de Benfeitorias') {
        calcData = {
          'vi': _parse(_viController),
          'vs': _parse(_vsController),
          'vua': _parse(_vuaController),
        };
        finalValue = _costController.calcDepreciacaoBenfeitoria(
          calcData['vi'],
          calcData['vs'],
          calcData['vua'],
        );
      } else if (_selectedCategory == 'Seguro de Máquinas') {
        calcData = {'vm': _parse(_vmController), 'uah': _parse(_uahController)};
        finalValue = _costController.calcSeguroMaquina(
          calcData['vm'],
          calcData['uah'],
        );
      } else if (_selectedCategory == 'Seguro de Benfeitorias') {
        calcData = {'vm': _parse(_vmController)};
        finalValue = _costController.calcSeguroBenfeitoria(calcData['vm']);
      } else if (_selectedCategory == 'Juros sobre Terras') {
        calcData = {'vt': _parse(_vtController)};
        finalValue = _costController.calcJurosTerra(calcData['vt']);
      } else if (_selectedCategory == 'Juros sobre Máquinas') {
        calcData = {'vm': _parse(_vmController), 'uah': _parse(_uahController)};
        finalValue = _costController.calcJurosMaquina(
          calcData['vm'],
          calcData['uah'],
        );
      } else if (_selectedCategory == 'Juros sobre Benfeitorias') {
        calcData = {'vm': _parse(_vmController)};
        finalValue = _costController.calcJurosBenfeitoria(calcData['vm']);
      } else {
        finalValue = Parsers.money(_valueController.text) ?? 0;
        calcData = {};
      }

      // Campo da fórmula vazio ou zerado (ex: vida útil 0) gera divisão por
      // zero: não grava valor infinito ou negativo
      if (!finalValue.isFinite || finalValue <= 0) {
        setState(() => _isProcessing = false);
        context.showErrorSnackBar(
          "Confira os valores informados: o custo calculado é inválido.",
        );
        return;
      }

      final newCost = CostModel(
        id: widget.costToEdit?.id,
        farmId: '',
        type: _selectedType!,
        category: _selectedCategory!,
        value: finalValue,
        dateTimestamp: _costDate.millisecondsSinceEpoch,
        observation: _obsController.text.trim(),
        calculationData: calcData.isNotEmpty ? calcData : null,
        plotName: _selectedPlot,
      );

      if (widget.costToEdit != null) {
        await _costController.updateCost(newCost);
      } else {
        await _costController.saveCost(newCost);
      }

      if (!mounted) return;
      final state = _costController.state;
      if (state is CostErrorState) {
        setState(() => _isProcessing = false);
        context.showErrorSnackBar(state.message);
        return;
      }
      Navigator.pop(context, true);
    }
  }

  List<Widget> _buildDynamicFields() {
    if (_selectedCategory == null) return [];

    final isTrator = _selectedCategory == 'Manutenção de Tratores';
    final isImplemento = _selectedCategory == 'Manutenção de Implementos';
    final isDepMaq = _selectedCategory == 'Depreciação de Máquinas';
    final isDepBen = _selectedCategory == 'Depreciação de Benfeitorias';
    final isSegMaq = _selectedCategory == 'Seguro de Máquinas';
    final isSegBen = _selectedCategory == 'Seguro de Benfeitorias';
    final isJurTer = _selectedCategory == 'Juros sobre Terras';
    final isJurMaq = _selectedCategory == 'Juros sobre Máquinas';
    final isJurBen = _selectedCategory == 'Juros sobre Benfeitorias';

    bool hasFormula =
        isTrator ||
        isImplemento ||
        isDepMaq ||
        isDepBen ||
        isSegMaq ||
        isSegBen ||
        isJurTer ||
        isJurMaq ||
        isJurBen;

    if (!hasFormula) {
      return [
        CustomTextFormField(
          controller: _valueController,
          labelText: "Valor do custo (R\$)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) => v == null || v.isEmpty ? "Informe o valor" : null,
        ),
      ];
    }

    List<Widget> fields = [];

    if (isTrator || isImplemento || isDepMaq || isDepBen) {
      fields.add(
        CustomTextFormField(
          controller: _viController,
          labelText: "Valor inicial novo (Vi)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) => v!.isEmpty ? "Obrigatório" : null,
        ),
      );
      fields.add(const SizedBox(height: 16));
    }
    if (isDepMaq || isDepBen) {
      fields.add(
        CustomTextFormField(
          controller: _vsController,
          labelText: "Valor de sucata (Vs)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
      fields.add(const SizedBox(height: 16));
    }
    if (isSegMaq || isSegBen || isJurMaq || isJurBen) {
      fields.add(
        CustomTextFormField(
          controller: _vmController,
          labelText: "Valor médio (Vm)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
      fields.add(const SizedBox(height: 16));
    }
    if (isJurTer) {
      fields.add(
        CustomTextFormField(
          controller: _vtController,
          labelText: "Valor da terra (Vt)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
      fields.add(const SizedBox(height: 16));
    }
    if (isImplemento) {
      fields.add(
        CustomTextFormField(
          controller: _rController,
          labelText: "Taxa de manutenção (R%)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
      fields.add(const SizedBox(height: 16));
    }
    if (isTrator || isImplemento || isDepMaq) {
      fields.add(
        CustomTextFormField(
          controller: _vuhController,
          labelText: "Vida útil em horas (Vuh)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
    }
    if (isDepBen) {
      fields.add(
        CustomTextFormField(
          controller: _vuaController,
          labelText: "Vida útil em anos (Vua)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
    }
    if (isSegMaq || isJurMaq) {
      fields.add(
        CustomTextFormField(
          controller: _uahController,
          labelText: "Utilização anual em horas (Uah)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
    }
    return fields;
  }

  @override
  Widget build(BuildContext context) {
    // Adicionadas chaves { } no if do _isLoading
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CustomCircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          widget.costToEdit != null ? "Editar Custo" : "Lançamento de Custos",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.costToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CustomCircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey('type_$_selectedType'),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Tipo de custo",
                      ),
                      initialValue: _selectedType,
                      items: CostCategories.types
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _selectedType = v;
                        _selectedCategory = null;
                      }),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey('category_$_selectedCategory'),
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: "Categoria"),
                      initialValue: _selectedCategory,
                      items: _currentCategories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      validator: (v) =>
                          v == null ? "Selecione a categoria" : null,
                    ),
                    const SizedBox(height: 24),
                    ..._buildDynamicFields(),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Talhão",
                        helperText:
                            "Sem talhão, o custo é rateado entre os talhões pela área",
                      ),
                      initialValue: _selectedPlot,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text("Fazenda inteira"),
                        ),
                        ..._plots.map(
                          (p) => DropdownMenuItem<String?>(
                            value: p,
                            child: Text(p),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedPlot = v),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(
                        Icons.event_rounded,
                        color: AppColors.greenlightOne,
                      ),
                      label: Text(
                        "Data do custo: ${Formatters.date(_costDate.millisecondsSinceEpoch)}",
                        style: const TextStyle(color: AppColors.greenlightOne),
                      ),
                    ),
                    CustomTextFormField(
                      controller: _obsController,
                      labelText: "Observações",
                      hintText: "Especifique o lançamento (opcional)",
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: widget.costToEdit != null
                          ? "Atualizar Custo"
                          : "Salvar Lançamento",
                      onPressed: _handleSave,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
