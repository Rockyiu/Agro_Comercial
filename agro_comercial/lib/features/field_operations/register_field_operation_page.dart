import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/field_operation_model.dart';
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
  final _dosageController = TextEditingController();

  final _controller = locator.get<FieldOperationController>();

  bool _isProcessing = false;
  String _selectedType = 'Vistoria';
  String? _selectedCondition;

  // Utilizando IDs para blindar o Dropdown contra o AssertionError
  String? _selectedProductId;
  String? _selectedMachineId;
  String _selectedDosageUnit = 'L';

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final List<String> _conditions = ['Excelente', 'Atenção', 'Crítico'];
  final List<String> _dosageUnits = [
    'L',
    'ml',
    'kg',
    'g',
    'un',
    'mg',
    'saco',
    'tambor',
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
  void dispose() {
    _plotController.dispose();
    _obsController.dispose();
    _dosageController.dispose();
    super.dispose();
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
                      setState(() {
                        _selectedType = newSelection.first;
                      });
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
                    hintText: "Ex: Talhão 01, Área Norte",
                    validator: (v) => v!.isEmpty ? "Informe o talhão" : null,
                  ),
                  const SizedBox(height: 16),

                  if (_selectedType == 'Vistoria') ..._buildInspectionFields(),
                  if (_selectedType == 'Aplicação')
                    ..._buildApplicationFields(),

                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: "Confirmar Lançamento",
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        String? machName;
                        bool needsTime = false;

                        if (_selectedType == 'Aplicação' &&
                            _selectedMachineId != null) {
                          try {
                            final m = _controller.machines.firstWhere(
                              (mach) => mach.id == _selectedMachineId,
                            );
                            machName = m.name;
                            needsTime = m.isMotorized;
                          } catch (_) {}
                        }

                        if (_selectedType == 'Aplicação' &&
                            needsTime &&
                            (_startTime == null || _endTime == null)) {
                          // ADICIONADO: Libera o ecrã para tentar de novo
                          setState(() => _isProcessing = false);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Defina os horários do trator!"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        String? prodName;
                        if (_selectedType == 'Aplicação' &&
                            _selectedProductId != null) {
                          try {
                            prodName = _controller.products
                                .firstWhere((p) => p.id == _selectedProductId)
                                .name;
                          } catch (_) {}
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
                          productId: _selectedType == 'Aplicação'
                              ? _selectedProductId
                              : null,
                          productName: _selectedType == 'Aplicação'
                              ? prodName
                              : null,
                          dosage: _selectedType == 'Aplicação'
                              ? double.tryParse(_dosageController.text)
                              : null,
                          dosageUnit: _selectedType == 'Aplicação'
                              ? _selectedDosageUnit
                              : null,
                          machineId: _selectedType == 'Aplicação'
                              ? _selectedMachineId
                              : null,
                          machineName: _selectedType == 'Aplicação'
                              ? machName
                              : null,
                        );

                        setState(() => _isProcessing = true);

                        await _controller.launchOperation(
                          operation,
                          startTime: _startTime,
                          endTime: _endTime,
                        );

                        if (!context.mounted) {
                          return;
                        }

                        if (_controller.state is FieldOperationErrorState) {
                          setState(() => _isProcessing = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                (_controller.state as FieldOperationErrorState)
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
          labelText: "CONDIÇÃO ATUAL DO TALHÃO",
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.greenlightOne),
          ),
        ),
        initialValue: _selectedCondition,
        items: _conditions
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => setState(() => _selectedCondition = v),
        validator: (v) => _selectedType == 'Vistoria' && v == null
            ? "Selecione a condição"
            : null,
      ),
      const SizedBox(height: 16),
      CustomTextFormField(
        controller: _obsController,
        labelText: "OBSERVAÇÕES E DIAGNÓSTICO",
        hintText:
            "Ex: Presença de lagarta do cartucho identificada em nível leve.",
      ),
    ];
  }

  List<Widget> _buildApplicationFields() {
    return [
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: "PRODUTO / INSUMO UTILIZADO",
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.greenlightOne),
          ),
        ),
        initialValue: _selectedProductId,
        items: _controller.products.map((p) {
          return DropdownMenuItem<String>(
            value: p.id,
            child: Text(
              "${p.name} (${p.category}) - ${p.quantity * p.measure} ${p.unit}",
            ),
          );
        }).toList(),
        onChanged: (v) => setState(() {
          _selectedProductId = v;
          if (v != null) {
            try {
              final prod = _controller.products.firstWhere((p) => p.id == v);
              _selectedDosageUnit = (prod.unit == 'L' || prod.unit == 'ml')
                  ? 'ml'
                  : (prod.unit == 'kg' || prod.unit == 'g')
                  ? 'g'
                  : prod.unit;
            } catch (_) {}
          }
        }),
        validator: (v) => _selectedType == 'Aplicação' && v == null
            ? "Selecione o produto aplicado"
            : null,
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: CustomTextFormField(
              controller: _dosageController,
              labelText: "DOSAGEM COBERTURA",
              keyboardType: TextInputType.number,
              validator: (v) => _selectedType == 'Aplicação' && v!.isEmpty
                  ? "Informe a dosagem"
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "UNIDADE",
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.greenlightOne),
                ),
              ),
              initialValue: _selectedDosageUnit,
              items: _dosageUnits
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDosageUnit = v!),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: "MAQUINÁRIO UTILIZADO (Opcional)",
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.greenlightOne),
          ),
        ),
        initialValue: _selectedMachineId,
        items: _controller.machines
            .map(
              (m) => DropdownMenuItem<String>(
                value: m.id,
                child: Text("${m.name} • ${m.brand}"),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _selectedMachineId = v),
      ),
      if (_selectedMachineId != null) ...[
        Builder(
          builder: (context) {
            bool isMotorized = false;
            try {
              isMotorized = _controller.machines
                  .firstWhere((m) => m.id == _selectedMachineId)
                  .isMotorized;
            } catch (_) {}

            if (isMotorized) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
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
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    ];
  }
}
