import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/field_operation_model.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'field_operation_controller.dart';
import 'field_operation_state.dart';

class RegisterFieldOperationPage extends StatefulWidget {
  const RegisterFieldOperationPage({super.key});

  @override
  State<RegisterFieldOperationPage> createState() =>
      _RegisterFieldOperationPageState();
}

class _RegisterFieldOperationPageState
    extends State<RegisterFieldOperationPage> {
  final _formKey = GlobalKey<FormState>();
  final _plotController = TextEditingController();
  final _obsController = TextEditingController();

  final _controller = locator.get<FieldOperationController>();

  String _selectedType = 'Vistoria';
  String? _selectedCondition;
  MachineModel? _selectedMachine;

  // GERENCIAMENTO DA CALDA DE MISTURA (1 a 10 Itens)
  int _productsCount = 1;
  final List<ProductModel?> _selectedProducts = List.generate(10, (_) => null);
  final List<TextEditingController> _dosageControllers = List.generate(
    10,
    (_) => TextEditingController(),
  );
  final List<String> _selectedDosageUnits = List.generate(10, (_) => 'ml');

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final List<String> _conditions = ['Excelente', 'Atenção', 'Crítico'];
  final List<String> _dosageUnits = ['L', 'ml', 'kg', 'g', 'un'];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleStateChange);
    _controller.loadFarmResources();
  }

  void _handleStateChange() {
    final state = _controller.state;
    if (state is FieldOperationLoadingState) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CustomCircularProgressIndicator(),
      );
    } else if (state is FieldOperationSuccessState) {
      Navigator.pop(context);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Atividade lançada com sucesso!"),
          backgroundColor: AppColors.greenlightOne,
        ),
      );
    } else if (state is FieldOperationErrorState) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _plotController.dispose();
    _obsController.dispose();
    for (var c in _dosageControllers) {
      c.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startTime = picked;
        else
          _endTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Lançamento de Campo",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoadingResources) {
            return const Center(child: CustomCircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "TIPO DE OPERAÇÃO",
                    style: AppTextStyles.smallText.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.greenlightOne,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Vistoria',
                        label: Text('Vistoria'),
                        icon: Icon(Icons.search),
                      ),
                      ButtonSegment(
                        value: 'Aplicação',
                        label: Text('Aplicação'),
                        icon: Icon(Icons.opacity),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() => _selectedType = newSelection.first);
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.greenlightOne,
                      selectedForegroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomTextFormField(
                    controller: _plotController,
                    labelText: "IDENTIFICAÇÃO DO TALHÃO",
                    hintText: "Ex: Talhão 01",
                    validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                  ),
                  const SizedBox(height: 16),

                  if (_selectedType == 'Vistoria') ..._buildInspectionFields(),
                  if (_selectedType == 'Aplicação')
                    ..._buildApplicationFields(),

                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: "Confirmar Lançamento",
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        if (_selectedType == 'Aplicação' &&
                            _selectedMachine != null &&
                            _selectedMachine!.isMotorized &&
                            (_startTime == null || _endTime == null)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Selecione os horários da máquina!",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        List<Map<String, dynamic>> appliedProductsList = [];
                        if (_selectedType == 'Aplicação') {
                          for (int i = 0; i < _productsCount; i++) {
                            if (_selectedProducts[i] != null) {
                              appliedProductsList.add({
                                'productId': _selectedProducts[i]!.id,
                                'productName': _selectedProducts[i]!.name,
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

                        final operation = FieldOperationModel(
                          type: _selectedType,
                          plotName: _plotController.text.trim(),
                          dateTimestamp: DateTime.now().millisecondsSinceEpoch,
                          farmId: '',
                          condition: _selectedType == 'Vistoria'
                              ? _selectedCondition
                              : null,
                          observations: _obsController.text.trim(),
                          machineId: _selectedType == 'Aplicação'
                              ? _selectedMachine?.id
                              : null,
                          machineName: _selectedType == 'Aplicação'
                              ? _selectedMachine?.name
                              : null,
                        );

                        _controller.launchOperation(
                          operation,
                          appliedProductsList,
                          startTime: _startTime,
                          endTime: _endTime,
                        );
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

  List<Widget> _buildInspectionFields() {
    return [
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: "CONDIÇÃO ATUAL",
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.greenlightOne),
          ),
        ),
        initialValue: _selectedCondition,
        items: _conditions
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => setState(() => _selectedCondition = v),
        validator: (v) =>
            _selectedType == 'Vistoria' && v == null ? "Selecione" : null,
      ),
      const SizedBox(height: 16),
      CustomTextFormField(
        controller: _obsController,
        labelText: "OBSERVAÇÕES E DIAGNÓSTICO",
      ),
    ];
  }

  List<Widget> _buildApplicationFields() {
    List<Widget> fields = [
      DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: "QUANTIDADE DE INSUMOS NA CALDA",
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.greenlightOne),
          ),
        ),
        value: _productsCount,
        items: List.generate(10, (index) => index + 1)
            .map(
              (n) =>
                  DropdownMenuItem<int>(value: n, child: Text("$n insumo(s)")),
            )
            .toList(),
        onChanged: (v) => setState(() {
          if (v != null) _productsCount = v;
        }),
      ),
      const SizedBox(height: 20),
    ];

    for (int i = 0; i < _productsCount; i++) {
      fields.add(
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.greenlightOne.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "INSUMO #${i + 1}",
                  style: AppTextStyles.smallText.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.greenlightOne,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ProductModel>(
                  decoration: const InputDecoration(
                    labelText: "PRODUTO",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedProducts[i],
                  items: _controller.products.map((p) {
                    double totalVolume = p.quantity * p.measure;
                    bool isEsgotado = totalVolume <= 0;
                    return DropdownMenuItem(
                      value: isEsgotado ? null : p,
                      enabled: !isEsgotado,
                      child: Text(
                        "${p.name} - ${isEsgotado ? '(ESGOTADO)' : '${totalVolume.toStringAsFixed(1)} ${p.unit}'}",
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() {
                    _selectedProducts[i] = v;
                    if (v != null)
                      _selectedDosageUnits[i] =
                          (v.unit == 'L' || v.unit == 'ml')
                          ? 'ml'
                          : (v.unit == 'kg' || v.unit == 'g')
                          ? 'g'
                          : v.unit;
                  }),
                  validator: (v) => _selectedType == 'Aplicação' && v == null
                      ? "Selecione o produto"
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextFormField(
                        controller: _dosageControllers[i],
                        labelText: "QUANTIDADE TOTAL UTILIZADA",
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _selectedType == 'Aplicação' && v!.isEmpty
                            ? "Obrigatório"
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "UNIDADE",
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedDosageUnits[i],
                        items: _dosageUnits
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
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

    fields.addAll([
      const SizedBox(height: 8),
      DropdownButtonFormField<MachineModel>(
        decoration: const InputDecoration(
          labelText: "MAQUINÁRIO UTILIZADO (Opcional)",
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.greenlightOne),
          ),
        ),
        value: _selectedMachine,
        items: _controller.machines
            .map(
              (m) => DropdownMenuItem(
                value: m,
                child: Text("${m.name} • ${m.brand}"),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _selectedMachine = v),
      ),
      if (_selectedMachine != null && _selectedMachine!.isMotorized) ...[
        const SizedBox(height: 16),
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
                  child: Text(
                    _startTime?.format(context) ?? "Selecionar",
                    style: TextStyle(
                      color: _startTime == null ? Colors.grey : Colors.black,
                    ),
                  ),
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
                  child: Text(
                    _endTime?.format(context) ?? "Selecionar",
                    style: TextStyle(
                      color: _endTime == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ]);

    return fields;
  }
}
