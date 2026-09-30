import 'package:flutter/material.dart';

import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/common/models/cost_model.dart';
import 'package:agro_comercial/locator.dart';

import 'cost_controller.dart';

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

  final List<String> _types = ['Variável', 'Fixo'];

  List<String> get _currentCategories {
    List<String> categories = [];
    if (_selectedType == 'Variável') {
      categories = [
        'Manutenção de Tratores',
        'Manutenção de Implementos',
        'Combustíveis, lubrificantes e filtros',
        'Aluguel de máquinas',
        'Manutenção de benfeitorias',
        'Mão-de-obra temporária',
        'Serviços contratados',
        'Insumos',
        'Despesas gerais',
        'Assistência técnica',
        'Transporte externo',
        'Recepção, secagem, limpeza',
        'Seguro rural',
        'Juros sobre capital de giro',
        'INSS',
      ];
    } else if (_selectedType == 'Fixo') {
      categories = [
        'Depreciação de Máquinas',
        'Depreciação de Benfeitorias',
        'Seguro de Máquinas',
        'Seguro de Benfeitorias',
        'Juros sobre Terras',
        'Juros sobre Máquinas',
        'Juros sobre Benfeitorias',
        'Impostos, taxas e contribuições',
        'Mão-de-obra fixa',
        'Arrendamento',
      ];
    }

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
      _selectedType = cost?.type ?? 'Variável';

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

  double _parse(TextEditingController controller) {
    if (controller.text.isEmpty) return 0.0;
    return double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
  }

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
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
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
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
        finalValue = _parse(_valueController);
        calcData = {};
      }

      final newCost = CostModel(
        id: widget.costToEdit?.id,
        farmId: '',
        type: _selectedType!,
        category: _selectedCategory!,
        value: finalValue,
        dateTimestamp:
            widget.costToEdit?.dateTimestamp ??
            DateTime.now().millisecondsSinceEpoch,
        observation: _obsController.text.trim(),
        calculationData: calcData.isNotEmpty ? calcData : null,
      );

      if (widget.costToEdit != null) {
        await _costController.updateCost(newCost);
      } else {
        await _costController.saveCost(newCost);
      }

      if (!mounted) return;
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
          labelText: "VALOR DO CUSTO (R\$)",
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
          labelText: "VALOR INICIAL NOVO (Vi)",
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
          labelText: "VALOR DE SUCATA (Vs)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
      fields.add(const SizedBox(height: 16));
    }
    if (isSegMaq || isSegBen || isJurMaq || isJurBen) {
      fields.add(
        CustomTextFormField(
          controller: _vmController,
          labelText: "VALOR MÉDIO (Vm)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
      fields.add(const SizedBox(height: 16));
    }
    if (isJurTer) {
      fields.add(
        CustomTextFormField(
          controller: _vtController,
          labelText: "VALOR DA TERRA (Vt)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
      fields.add(const SizedBox(height: 16));
    }
    if (isImplemento) {
      fields.add(
        CustomTextFormField(
          controller: _rController,
          labelText: "TAXA DE MANUTENÇÃO (R%)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
      fields.add(const SizedBox(height: 16));
    }
    if (isTrator || isImplemento || isDepMaq) {
      fields.add(
        CustomTextFormField(
          controller: _vuhController,
          labelText: "VIDA ÚTIL EM HORAS (Vuh)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
    }
    if (isDepBen) {
      fields.add(
        CustomTextFormField(
          controller: _vuaController,
          labelText: "VIDA ÚTIL EM ANOS (Vua)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
    }
    if (isSegMaq || isJurMaq) {
      fields.add(
        CustomTextFormField(
          controller: _uahController,
          labelText: "UTILIZAÇÃO ANUAL EM HORAS (Uah)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
    }
    return fields;
  }

  @override
  Widget build(BuildContext context) {
    // CORREÇÃO: Adicionadas chaves { } no if do _isLoading
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
              icon: const Icon(Icons.delete, color: Colors.redAccent),
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
                        labelText: "TIPO DE CUSTO",
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.greenlightOne,
                          ),
                        ),
                      ),
                      initialValue: _selectedType,
                      items: _types
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
                      decoration: const InputDecoration(
                        labelText: "CATEGORIA",
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.greenlightOne,
                          ),
                        ),
                      ),
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
                    CustomTextFormField(
                      controller: _obsController,
                      labelText: "OBSERVAÇÕES",
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
