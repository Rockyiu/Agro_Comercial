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

class FieldOperationDetailsPage extends StatefulWidget {
  final FieldOperationModel operation;
  const FieldOperationDetailsPage({super.key, required this.operation});

  @override
  State<FieldOperationDetailsPage> createState() =>
      _FieldOperationDetailsPageState();
}

class _FieldOperationDetailsPageState extends State<FieldOperationDetailsPage> {
  bool _isEditing = false;
  bool _isProcessing = false;
  final _formKey = GlobalKey<FormState>();

  final _controller = locator.get<FieldOperationController>();

  late TextEditingController _plotController;
  late TextEditingController _obsController;
  late TextEditingController _dosageController;

  String _selectedType = 'Vistoria';
  String? _selectedCondition;
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
    _plotController = TextEditingController(text: widget.operation.plotName);
    _obsController = TextEditingController(text: widget.operation.observations);
    _dosageController = TextEditingController(
      text: widget.operation.dosage?.toString() ?? '',
    );
    _controller.loadFarmResources();
  }

  void _initializeEditData() {
    _selectedType = widget.operation.type;
    _selectedCondition = widget.operation.condition;
    _selectedProductId = widget.operation.productId;
    _selectedMachineId = widget.operation.machineId;
    _selectedDosageUnit = widget.operation.dosageUnit ?? 'L';
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null)
      setState(() {
        if (isStart)
          _startTime = picked;
        else
          _endTime = picked;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          _isEditing ? "Editar Campo" : "Detalhes da Vistoria",
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
                if (_isEditing) _initializeEditData();
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
                      "Deseja apagar este histórico? O estoque e o maquinário serão estornados automaticamente.",
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
                          if (_controller.state is FieldOperationErrorState) {
                            setState(() => _isProcessing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  (_controller.state
                                          as FieldOperationErrorState)
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
          if (_controller.isLoadingResources || _isProcessing)
            return const Center(child: CustomCircularProgressIndicator());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isEditing) ...[
                    Text(
                      "${widget.operation.type} - ${widget.operation.plotName}",
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
                          widget.operation.observations?.isEmpty ?? true
                              ? "Sem observações detalhadas."
                              : widget.operation.observations!,
                          style: AppTextStyles.inputText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.operation.type == 'Vistoria')
                      ListTile(
                        leading: const Icon(
                          Icons.favorite,
                          color: AppColors.greenlightOne,
                        ),
                        title: const Text("Condição:"),
                        subtitle: Text(widget.operation.condition ?? ''),
                      ),
                    if (widget.operation.type == 'Aplicação') ...[
                      ListTile(
                        leading: const Icon(
                          Icons.science,
                          color: Colors.orange,
                        ),
                        title: Text("Insumo: ${widget.operation.productName}"),
                        subtitle: Text(
                          "Dosagem: ${widget.operation.dosage} ${widget.operation.dosageUnit}",
                        ),
                      ),
                      if (widget.operation.machineId != null)
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
                                : "Implemento manual / Sem motor",
                          ),
                        ),
                    ],
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.amber.withValues(alpha: 0.2),
                      child: Text(
                        "ATENÇÃO: Ao salvar, o sistema fará o recálculo e estorno automático dos insumos anteriores.",
                        style: AppTextStyles.smallText.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      onSelectionChanged: (Set<String> newSelection) =>
                          setState(() => _selectedType = newSelection.first),
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: AppColors.greenlightOne,
                        selectedForegroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomTextFormField(
                      controller: _plotController,
                      labelText: "IDENTIFICAÇÃO DO TALHÃO",
                      validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                    ),
                    const SizedBox(height: 16),

                    if (_selectedType == 'Vistoria') ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "CONDIÇÃO",
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _selectedCondition,
                        items: _conditions
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCondition = v),
                        validator: (v) =>
                            _selectedType == 'Vistoria' && v == null
                            ? "Selecione"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        controller: _obsController,
                        labelText: "OBSERVAÇÕES E DIAGNÓSTICO",
                      ),
                    ],

                    if (_selectedType == 'Aplicação') ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "PRODUTO / INSUMO UTILIZADO",
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _selectedProductId,
                        items: _controller.products
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id!,
                                child: Text(
                                  "${p.name} (${p.category}) - ${p.quantity * p.measure} ${p.unit}",
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedProductId = v;
                          try {
                            final prod = _controller.products.firstWhere(
                              (p) => p.id == v,
                            );
                            _selectedDosageUnit =
                                (prod.unit == 'L' || prod.unit == 'ml')
                                ? 'ml'
                                : (prod.unit == 'kg' || prod.unit == 'g')
                                ? 'g'
                                : prod.unit;
                          } catch (_) {}
                        }),
                        validator: (v) =>
                            _selectedType == 'Aplicação' && v == null
                            ? "Selecione"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: CustomTextFormField(
                              controller: _dosageController,
                              labelText: "DOSAGEM TOTAL",
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  _selectedType == 'Aplicação' && v!.isEmpty
                                  ? "Obrigatório"
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "UNIDADE",
                                border: OutlineInputBorder(),
                              ),
                              initialValue: _selectedDosageUnit,
                              items: _dosageUnits
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedDosageUnit = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "MAQUINÁRIO (Opcional)",
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _selectedMachineId,
                        items: _controller.machines
                            .map(
                              (m) => DropdownMenuItem(
                                value: m.id!,
                                child: Text("${m.name} • ${m.brand}"),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedMachineId = v),
                      ),
                      if (_selectedMachineId != null) ...[
                        Builder(
                          builder: (context) {
                            final m = _controller.machines.firstWhere(
                              (m) => m.id == _selectedMachineId,
                            );
                            if (m.isMotorized) {
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
                                            _startTime?.format(context) ??
                                                "Selecionar",
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
                                            _endTime?.format(context) ??
                                                "Selecionar",
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
                    ],
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: "Salvar Alterações",
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          String? machName;
                          bool needsTime = false;
                          if (_selectedMachineId != null) {
                            final m = _controller.machines.firstWhere(
                              (mach) => mach.id == _selectedMachineId,
                            );
                            machName = m.name;
                            needsTime = m.isMotorized;
                          }

                          if (_selectedType == 'Aplicação' &&
                              needsTime &&
                              (_startTime == null || _endTime == null)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Defina os horários do trator!"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          String? prodName;
                          if (_selectedProductId != null) {
                            prodName = _controller.products
                                .firstWhere((p) => p.id == _selectedProductId)
                                .name;
                          }

                          final newOperation = FieldOperationModel(
                            id: widget.operation.id,
                            type: _selectedType,
                            plotName: _plotController.text.trim(),
                            dateTimestamp: widget.operation.dateTimestamp,
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
                          await _controller.updateFullOperation(
                            widget.operation,
                            newOperation,
                            startTime: _startTime,
                            endTime: _endTime,
                          );

                          if (!context.mounted) return;
                          if (_controller.state is FieldOperationErrorState) {
                            setState(() => _isProcessing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  (_controller.state
                                          as FieldOperationErrorState)
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
}
