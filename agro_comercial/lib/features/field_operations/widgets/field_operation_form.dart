import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/constants/operation_options.dart';
import 'package:agro_comercial/common/models/field_operation_model.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/common/utils/parsers.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/horimeter_fields.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:flutter/material.dart';

// Dados preenchidos no formulário, prontos para o FieldOperationController
class FieldOperationFormData {
  final FieldOperationModel operation;
  final double? initialHorimeter;
  final double? finalHorimeter;

  const FieldOperationFormData({
    required this.operation,
    this.initialHorimeter,
    this.finalHorimeter,
  });
}

// Formulário de Vistoria/Aplicação usado no cadastro e na edição
class FieldOperationForm extends StatefulWidget {
  final List<MachineModel> machines;
  final List<ProductModel> products;
  final List<String> plots; // talhões da fazenda ativa
  final FieldOperationModel? initialOperation; // preenchido na edição
  final String submitText;
  // No cadastro o horímetro inicial precisa bater com o da máquina no sistema
  final bool strictHorimeter;
  final Future<void> Function(FieldOperationFormData data) onSubmit;

  const FieldOperationForm({
    super.key,
    required this.machines,
    required this.products,
    required this.plots,
    required this.submitText,
    required this.onSubmit,
    this.initialOperation,
    this.strictHorimeter = false,
  });

  @override
  State<FieldOperationForm> createState() => _FieldOperationFormState();
}

class _FieldOperationFormState extends State<FieldOperationForm> {
  final _formKey = GlobalKey<FormState>();
  final _obsController = TextEditingController();
  final _dosageController = TextEditingController();
  final _initialHorimeterController = TextEditingController();
  final _finalHorimeterController = TextEditingController();

  String _selectedType = OperationOptions.inspection;
  String? _selectedPlot;
  String? _selectedCondition;
  String? _selectedProductId;
  String? _selectedMachineId;
  String _selectedDosageUnit = 'L';

  bool get _isApplication => _selectedType == OperationOptions.application;

  MachineModel? get _selectedMachine =>
      widget.machines.where((m) => m.id == _selectedMachineId).firstOrNull;

  ProductModel? get _selectedProduct =>
      widget.products.where((p) => p.id == _selectedProductId).firstOrNull;

  // Talhões da fazenda + o talhão já salvo no lançamento (caso tenha sido
  // renomeado ou removido da fazenda depois)
  late final List<String> _plots = {
    ...widget.plots,
    if (widget.initialOperation?.plotName.isNotEmpty ?? false)
      widget.initialOperation!.plotName,
  }.toList();

  @override
  void initState() {
    super.initState();
    final op = widget.initialOperation;
    if (op == null) return;

    _selectedType = op.type;
    _selectedPlot = op.plotName.isEmpty ? null : op.plotName;
    _obsController.text = op.observations ?? '';
    _dosageController.text = op.dosage?.toString() ?? '';
    if (OperationOptions.fieldConditions.contains(op.condition)) {
      _selectedCondition = op.condition;
    }
    if (OperationOptions.dosageUnits.contains(op.dosageUnit)) {
      _selectedDosageUnit = op.dosageUnit!;
    }
    // Só pré-seleciona se ainda existirem (senão o Dropdown quebra)
    if (widget.products.any((p) => p.id == op.productId)) {
      _selectedProductId = op.productId;
    }
    if (widget.machines.any((m) => m.id == op.machineId)) {
      _selectedMachineId = op.machineId;
    }
  }

  @override
  void dispose() {
    _obsController.dispose();
    _dosageController.dispose();
    _initialHorimeterController.dispose();
    _finalHorimeterController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final machine = _isApplication ? _selectedMachine : null;
    final product = _isApplication ? _selectedProduct : null;

    HorimeterReading? horimeter;
    if (machine != null && machine.isMotorized) {
      final result = HorimeterReading.parse(
        initialController: _initialHorimeterController,
        finalController: _finalHorimeterController,
        expectedInitial: widget.strictHorimeter ? machine.workingHours : null,
      );
      if (result.error != null) {
        context.showErrorSnackBar(result.error!);
        return;
      }
      horimeter = result.reading;
    }

    await widget.onSubmit(
      FieldOperationFormData(
        // farmId e autor são preenchidos pelo controller
        operation: FieldOperationModel(
          type: _selectedType,
          plotName: _selectedPlot!.trim(),
          dateTimestamp: DateTime.now().millisecondsSinceEpoch,
          farmId: '',
          condition: _isApplication ? null : _selectedCondition,
          observations: _obsController.text.trim(),
          productId: product?.id,
          productName: product?.name,
          dosage: _isApplication
              ? Parsers.decimal(_dosageController.text)
              : null,
          dosageUnit: _isApplication ? _selectedDosageUnit : null,
          machineId: machine?.id,
          machineName: machine?.name,
        ),
        initialHorimeter: horimeter?.initial,
        finalHorimeter: horimeter?.end,
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.greenlightOne),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
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
                value: OperationOptions.inspection,
                label: Text(OperationOptions.inspection),
                icon: Icon(Icons.search),
              ),
              ButtonSegment(
                value: OperationOptions.application,
                label: Text(OperationOptions.application),
                icon: Icon(Icons.opacity),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (selection) =>
                setState(() => _selectedType = selection.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.greenlightOne,
              selectedForegroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _selectedPlot,
            decoration: _decoration("IDENTIFICAÇÃO DO TALHÃO").copyWith(
              labelStyle: AppTextStyles.inputLabelText.copyWith(
                color: AppColors.lightkGrey,
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.greenlightOne,
                  width: 2,
                ),
              ),
            ),
            hint: const Text(
              "Selecione o Talhão",
              style: TextStyle(fontSize: 13),
            ),
            items: _plots
                .map(
                  (plot) => DropdownMenuItem(
                    value: plot,
                    child: Text(plot, style: const TextStyle(fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedPlot = v),
            validator: (v) =>
                (v == null || v.isEmpty) ? "Informe o talhão" : null,
          ),
          const SizedBox(height: 16),
          if (_isApplication)
            ..._buildApplicationFields()
          else
            ..._buildInspectionFields(),
          const SizedBox(height: 32),
          PrimaryButton(text: widget.submitText, onPressed: _submit),
        ],
      ),
    );
  }

  List<Widget> _buildInspectionFields() {
    return [
      DropdownButtonFormField<String>(
        decoration: _decoration("CONDIÇÃO ATUAL DO TALHÃO"),
        initialValue: _selectedCondition,
        items: OperationOptions.fieldConditions
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => setState(() => _selectedCondition = v),
        validator: (v) => v == null ? "Selecione a condição" : null,
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
    final machine = _selectedMachine;
    return [
      DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: _decoration("PRODUTO / INSUMO UTILIZADO"),
        initialValue: _selectedProductId,
        items: widget.products
            .map(
              (p) => DropdownMenuItem<String>(
                value: p.id,
                child: Text(
                  "${p.name} (${p.category}) - ${p.totalStock.toStringAsFixed(2)} ${p.unit}",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() {
          _selectedProductId = v;
          final product = _selectedProduct;
          if (product == null) return;
          final suggested = OperationOptions.defaultDosageUnitFor(product.unit);
          if (OperationOptions.dosageUnits.contains(suggested)) {
            _selectedDosageUnit = suggested;
          }
        }),
        validator: (v) => v == null ? "Selecione o produto aplicado" : null,
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: CustomTextFormField(
              controller: _dosageController,
              labelText: "DOSAGEM TOTAL",
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) => (v ?? '').isEmpty ? "Informe a dosagem" : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              // A key força o campo a refletir a unidade sugerida
              // quando o produto é trocado
              key: ValueKey('unit_$_selectedDosageUnit'),
              decoration: _decoration("UNIDADE"),
              initialValue: _selectedDosageUnit,
              items: OperationOptions.dosageUnits
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDosageUnit = v!),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: _decoration("MAQUINÁRIO UTILIZADO (Opcional)"),
        initialValue: _selectedMachineId,
        items: widget.machines
            .map(
              (m) => DropdownMenuItem<String>(
                value: m.id,
                child: Text(
                  "${m.name} • ${m.brand}",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _selectedMachineId = v),
      ),
      if (machine != null && machine.isMotorized)
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: HorimeterFields(
            initialController: _initialHorimeterController,
            finalController: _finalHorimeterController,
          ),
        ),
    ];
  }
}
