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

class RegisterOperationPage extends StatefulWidget {
  const RegisterOperationPage({super.key});

  @override
  State<RegisterOperationPage> createState() => _RegisterOperationPageState();
}

class _RegisterOperationPageState extends State<RegisterOperationPage> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();

  final _controller = locator.get<OperationController>();

  bool _isProcessing = false; // Evita duplo clique no botão salvar
  String? _selectedTitle;
  bool _usedMachine = false;
  bool _usedProducts = false;

  // CORREÇÃO: Agora guardamos apenas o ID (String) para evitar erros de memória
  String? _selectedMachineId;
  MachineModel? get _selectedMachine {
    if (_selectedMachineId == null) return null;
    try {
      return _controller.machines.firstWhere((m) => m.id == _selectedMachineId);
    } catch (_) {
      return null;
    }
  }

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  int _productsCount = 1;
  // CORREÇÃO: Guardamos a lista de IDs dos produtos
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
    _controller.loadFarmResources();
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Registrar Operação",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
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
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "NOME DA OPERAÇÃO",
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.greenlightOne),
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
                    validator: (v) => v == null ? "Selecione a operação" : null,
                  ),
                  const SizedBox(height: 16),

                  CustomTextFormField(
                    controller: _descController,
                    labelText: "DESCRIÇÃO / OBSERVAÇÕES",
                    hintText: "Ex: Realizado na gleba de café da encosta.",
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
                    text: "Salvar Operação",
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        if (_usedMachine &&
                            _selectedMachine != null &&
                            _selectedMachine!.isMotorized &&
                            (_startTime == null || _endTime == null)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Defina os horários do trator!"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
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

                        final operation = OperationModel(
                          title: _selectedTitle!,
                          description: _descController.text.trim(),
                          farmId: '',
                          dateTimestamp: 0,
                          usedMachine: _usedMachine,
                          machineId: _usedMachine ? _selectedMachine?.id : null,
                          machineName: _usedMachine
                              ? _selectedMachine?.name
                              : null,
                          usedProducts: _usedProducts,
                          appliedProducts: appliedProductsList,
                        );

                        setState(() => _isProcessing = true);

                        await _controller.saveOperation(
                          operation,
                          appliedProductsList,
                          startTime: _startTime,
                          endTime: _endTime,
                        );

                        if (!context.mounted) return;
                        Navigator.pop(context);
                      }
                    },
                  ),
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
        // Alterado para String (ID)
        decoration: const InputDecoration(
          labelText: "SELECIONE O MAQUINÁRIO",
          border: OutlineInputBorder(),
        ),
        initialValue: _selectedMachineId,
        items: _controller.machines
            .map(
              (m) => DropdownMenuItem<String>(
                value: m.id!, // Vinculado ao ID
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
              child: InkWell(
                onTap: () => _selectTime(true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "HORA INÍCIO",
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_startTime?.format(context) ?? "Selecionar"),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectTime(false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "HORA TÉRMINO",
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_endTime?.format(context) ?? "Selecionar"),
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
          if (v != null) setState(() => _productsCount = v);
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
                  // Alterado para String (ID)
                  decoration: InputDecoration(
                    labelText: "PRODUTO #${i + 1}",
                    border: const OutlineInputBorder(),
                  ),
                  initialValue: _selectedProductIds[i],
                  items: _controller.products
                      .map(
                        (p) => DropdownMenuItem<String>(
                          value: p.id!, // Vinculado ao ID
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
                        // LISTA COMPLETA DE UNIDADES PARA NÃO DAR ERRO!
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
