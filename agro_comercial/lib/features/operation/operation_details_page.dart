import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/operation_model.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'operation_controller.dart';
import 'operation_state.dart';

class OperationDetailsPage extends StatefulWidget {
  final OperationModel operation;
  const OperationDetailsPage({super.key, required this.operation});

  @override
  State<OperationDetailsPage> createState() => _OperationDetailsPageState();
}

class _OperationDetailsPageState extends State<OperationDetailsPage> {
  bool _isEditing = false;
  bool _isProcessing = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descController;
  final _controller = locator.get<OperationController>();

  // ADICIONADO: Controladores para o horímetro
  final _initialHorimeterController = TextEditingController();
  final _finalHorimeterController = TextEditingController();

  String? _selectedTitle;
  bool _usedMachine = false;
  bool _usedProducts = false;

  String? _selectedMachineId;
  MachineModel? get _selectedMachine {
    if (_selectedMachineId == null) return null;
    try {
      return _controller.machines.firstWhere((m) => m.id == _selectedMachineId);
    } catch (_) {
      return null;
    }
  }

  int _productsCount = 1;
  final List<String?> _selectedProductIds = List.generate(10, (_) => null);

  ProductModel? _getSelectedProduct(int index) {
    if (_selectedProductIds[index] == null) return null;
    try {
      return _controller.products.firstWhere(
        (p) => p.id == _selectedProductIds[index],
      );
    } catch (_) {
      return null;
    }
  }

  final List<TextEditingController> _dosageControllers = List.generate(
    10,
    (_) => TextEditingController(),
  );
  final List<String> _selectedDosageUnits = List.generate(10, (_) => 'ml');

  final List<String> _operationsList = [
    'Pulverização - dessecação',
    'Pulverização - pós emergente',
    'Pulverização - pré emergente',
    'Pulverização - pragas e doenças',
    'Pulverização - herbicidas',
    'Pulverização - biológicos',
    'Pulverização - bioestimulantes',
    'Adubação - manual',
    'Adubação - tratorizada',
    'Semeadura - manual',
    'Semeadura - tratorizada',
    'Plantio - manual',
    'Plantio - tratorizado',
    'Poda - manual',
    'Poda - tratorizada',
    'Gradeação - tratorizada',
    'Subsolagem - tratorizada',
    'Escarificação - tratorizada',
    'Desbrota - manual',
    'Irrigação - gotejamento',
    'Irrigação - pivô',
    'Irrigação - aspersão',
    'Capina - manual',
    'Roçadeira - manual',
    'Roçadeira - tratorizada',
    'Trincha - tratorizada',
    'Soprador arruador - tratorizado',
    'Arruação - manual',
    'Colheita - manual',
    'Colheita - mecanizada',
    'Enterrio de mudas - manual',
    'Enterrio de mudas - mecanizada',
    'Serviços diversos - manual',
    'Serviços diversos - tratorizado',
    'Trabalho administrativo - geral',
    'Trabalho administrativo - gerencial',
    'Conserto de máquinas e equipamentos - individual',
    'Manutenção de máquinas e equipamentos - individual',
  ];

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.operation.description);
    _controller.loadFarmResources();
  }

  void _initializeEditData() {
    _selectedTitle = widget.operation.title;
    _descController.text = widget.operation.description;

    _usedMachine = widget.operation.usedMachine;
    if (_usedMachine && widget.operation.machineId != null) {
      _selectedMachineId = widget.operation.machineId;
    }

    _usedProducts = widget.operation.usedProducts;
    if (_usedProducts && widget.operation.appliedProducts.isNotEmpty) {
      _productsCount = widget.operation.appliedProducts.length;
      for (int i = 0; i < _productsCount; i++) {
        var pData = widget.operation.appliedProducts[i];
        _selectedProductIds[i] = pData['productId'];
        _dosageControllers[i].text = pData['dosage'].toString();
        _selectedDosageUnits[i] = pData['dosageUnit'];
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _initialHorimeterController.dispose();
    _finalHorimeterController.dispose();
    for (var c in _dosageControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          _isEditing ? "Editar Operação" : "Detalhes da Operação",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (_isEditing) {
                  _initializeEditData();
                }
              });
            },
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text("Excluir Lançamento"),
                    content: const Text(
                      "Deseja apagar esta operação do histórico? O maquinário e estoque serão devidamente estornados!",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text("Cancelar"),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          setState(() => _isProcessing = true);
                          await _controller.deleteSingleOperation(
                            widget.operation,
                          );

                          if (!context.mounted) return;

                          if (_controller.state is OperationErrorState) {
                            setState(() => _isProcessing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  (_controller.state as OperationErrorState)
                                      .message,
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Excluir",
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
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoadingResources || _isProcessing) {
            return const Center(child: CustomCircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isEditing) ...[
                    Text(
                      widget.operation.title,
                      style: AppTextStyles.midText20.copyWith(
                        color: AppColors.greenlightOne,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          widget.operation.description.isEmpty
                              ? "Sem descrição detalhada."
                              : widget.operation.description,
                          style: AppTextStyles.inputText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.operation.usedMachine)
                      ListTile(
                        leading: const Icon(
                          Icons.agriculture,
                          color: AppColors.greenlightOne,
                        ),
                        title: Text(
                          "Maquinário: ${widget.operation.machineName}",
                        ),
                        subtitle: Text(
                          widget.operation.machineHours != null
                              ? "Operou por: ${widget.operation.machineHours!.toStringAsFixed(1)}h"
                              : "Implemento manual / Sem horas",
                        ),
                      ),
                    if (widget.operation.usedProducts) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),
                      Text(
                        "Produtos Aplicados na Calda:",
                        style: AppTextStyles.smallText.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ...widget.operation.appliedProducts.map(
                        (p) => ListTile(
                          leading: const Icon(
                            Icons.science,
                            color: Colors.orange,
                          ),
                          title: Text(p['productName'] ?? 'Produto'),
                          trailing: Text(
                            "${p['dosage']} ${p['dosageUnit']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.amber.withValues(alpha: 0.2),
                      child: Text(
                        "ATENÇÃO: Ao salvar a edição, o sistema fará o recálculo inteligente e estornará os materiais da operação antiga automaticamente.",
                        style: AppTextStyles.smallText.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "NOME DA OPERAÇÃO",
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.greenlightOne,
                          ),
                        ),
                      ),
                      initialValue: _selectedTitle,
                      items: _operationsList
                          .map(
                            (o) => DropdownMenuItem(
                              value: o,
                              child: Text(
                                o,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedTitle = v),
                      validator: (v) =>
                          v == null ? "Selecione a operação" : null,
                    ),
                    const SizedBox(height: 16),

                    CustomTextFormField(
                      controller: _descController,
                      labelText: "DESCRIÇÃO / OBSERVAÇÕES",
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: Text(
                        "Utilizou Maquinário?",
                        style: AppTextStyles.inputText.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      activeTrackColor: AppColors.greenlightOne.withValues(
                        alpha: 0.4,
                      ),
                      activeThumbColor: AppColors.greenlightOne,
                      value: _usedMachine,
                      onChanged: (v) => setState(() => _usedMachine = v),
                    ),

                    if (_usedMachine) ..._buildMachineSection(),

                    SwitchListTile(
                      title: Text(
                        "Utilizou Produtos?",
                        style: AppTextStyles.inputText.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      activeTrackColor: AppColors.greenlightOne.withValues(
                        alpha: 0.4,
                      ),
                      activeThumbColor: AppColors.greenlightOne,
                      value: _usedProducts,
                      onChanged: (v) => setState(() => _usedProducts = v),
                    ),

                    if (_usedProducts) ..._buildProductsSection(),

                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: "Salvar Alterações",
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          double? initHori;
                          double? finalHori;

                          if (_usedMachine &&
                              _selectedMachine != null &&
                              _selectedMachine!.isMotorized) {
                            initHori = double.tryParse(
                              _initialHorimeterController.text.replaceAll(
                                ',',
                                '.',
                              ),
                            );
                            finalHori = double.tryParse(
                              _finalHorimeterController.text.replaceAll(
                                ',',
                                '.',
                              ),
                            );

                            if (initHori == null || finalHori == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Preencha o horímetro!"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (finalHori < initHori) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Horímetro final deve ser maior que o inicial!",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          }

                          List<Map<String, dynamic>> appliedProductsList = [];
                          if (_usedProducts) {
                            for (int i = 0; i < _productsCount; i++) {
                              final prod = _getSelectedProduct(i);
                              if (prod != null) {
                                appliedProductsList.add({
                                  'productId': prod.id,
                                  'productName': prod.name,
                                  'dosage':
                                      double.tryParse(
                                        _dosageControllers[i].text,
                                      ) ??
                                      0.0,
                                  'dosageUnit': _selectedDosageUnits[i],
                                });
                              }
                            }
                          }

                          final newOperation = OperationModel(
                            title: _selectedTitle!,
                            description: _descController.text.trim(),
                            farmId: '',
                            dateTimestamp: 0,
                            usedMachine: _usedMachine,
                            machineId: _usedMachine
                                ? _selectedMachine?.id
                                : null,
                            machineName: _usedMachine
                                ? _selectedMachine?.name
                                : null,
                            usedProducts: _usedProducts,
                            appliedProducts: appliedProductsList,
                          );

                          setState(() => _isProcessing = true);

                          // CHAMADA CORRIGIDA PARA USAR O HORÍMETRO
                          await _controller.updateFullOperation(
                            widget.operation,
                            newOperation,
                            appliedProductsList,
                            initialHorimeter: initHori,
                            finalHorimeter: finalHori,
                          );

                          if (!context.mounted) return;

                          if (_controller.state is OperationErrorState) {
                            setState(() => _isProcessing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  (_controller.state as OperationErrorState)
                                      .message,
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildMachineSection() {
    return [
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: "SELECIONE O MAQUINÁRIO",
          border: OutlineInputBorder(),
        ),
        initialValue: _selectedMachineId,
        items: _controller.machines
            .map(
              (m) => DropdownMenuItem<String>(
                value: m.id!,
                child: Text("${m.name} • ${m.brand}"),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _selectedMachineId = v),
        validator: (v) => _usedMachine && v == null ? "Obrigatório" : null,
      ),
      if (_selectedMachine != null && _selectedMachine!.isMotorized) ...[
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomTextFormField(
                controller: _initialHorimeterController,
                labelText: "HORÍMETRO INICIAL",
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextFormField(
                controller: _finalHorimeterController,
                labelText: "HORÍMETRO FINAL",
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildProductsSection() {
    List<Widget> blocks = [
      DropdownButtonFormField<int>(
        key: ValueKey(_productsCount),
        decoration: const InputDecoration(
          labelText: "QUANTIDADE DE PRODUTOS UTILIZADOS",
          border: OutlineInputBorder(),
        ),
        initialValue: _productsCount,
        items: List.generate(10, (i) => i + 1)
            .map(
              (n) => DropdownMenuItem(value: n, child: Text("$n produto(s)")),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) {
            setState(() => _productsCount = v);
          }
        },
      ),
      const SizedBox(height: 16),
    ];

    for (int i = 0; i < _productsCount; i++) {
      blocks.add(
        Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.black12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "PRODUTO #${i + 1}",
                    border: const OutlineInputBorder(),
                  ),
                  initialValue: _selectedProductIds[i],
                  items: _controller.products
                      .map(
                        (p) => DropdownMenuItem<String>(
                          value: p.id!,
                          child: Text(
                            "${p.name} (${p.category}) - ${p.quantity * p.measure} ${p.unit}",
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedProductIds[i] = v;
                    final prod = _getSelectedProduct(i);
                    if (prod != null) {
                      _selectedDosageUnits[i] =
                          (prod.unit == 'L' || prod.unit == 'ml')
                          ? 'ml'
                          : (prod.unit == 'kg' || prod.unit == 'g')
                          ? 'g'
                          : prod.unit;
                    }
                  }),
                  validator: (v) =>
                      _usedProducts && v == null ? "Obrigatório" : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextFormField(
                        controller: _dosageControllers[i],
                        labelText: "QTD GASTA",
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _usedProducts && v!.isEmpty ? "Obrigatório" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "UNIDADE",
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _selectedDosageUnits[i],
                        items:
                            [
                                  'L',
                                  'ml',
                                  'kg',
                                  'g',
                                  'mg',
                                  'un',
                                  'm',
                                  'saco',
                                  'tambor',
                                ]
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedDosageUnits[i] = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    return blocks;
  }
}
