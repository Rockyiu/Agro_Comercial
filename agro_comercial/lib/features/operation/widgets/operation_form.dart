import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/constants/operation_options.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/operation_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/common/utils/parsers.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/horimeter_fields.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:flutter/material.dart';

// Dados preenchidos no formulário, prontos para o OperationController
class OperationFormData {
  final OperationModel operation;
  final List<Map<String, dynamic>> appliedProducts;
  final double? initialHorimeter;
  final double? finalHorimeter;

  const OperationFormData({
    required this.operation,
    required this.appliedProducts,
    this.initialHorimeter,
    this.finalHorimeter,
  });
}

// Formulário de operação usado no cadastro e na edição
class OperationForm extends StatefulWidget {
  final List<MachineModel> machines;
  final List<ProductModel> products;
  final OperationModel? initialOperation; // preenchido na edição
  final String submitText;
  // No cadastro o horímetro inicial precisa bater com o da máquina no sistema
  final bool strictHorimeter;
  final Future<void> Function(OperationFormData data) onSubmit;

  const OperationForm({
    super.key,
    required this.machines,
    required this.products,
    required this.submitText,
    required this.onSubmit,
    this.initialOperation,
    this.strictHorimeter = false,
  });

  @override
  State<OperationForm> createState() => _OperationFormState();
}

class _OperationFormState extends State<OperationForm> {
  static const _maxProducts = OperationOptions.maxProducts;

  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _initialHorimeterController = TextEditingController();
  final _finalHorimeterController = TextEditingController();
  final _dosageControllers = List.generate(
    _maxProducts,
    (_) => TextEditingController(),
  );

  String? _selectedTitle;
  bool _usedMachine = false;
  bool _usedProducts = false;
  String? _selectedMachineId;
  int _productsCount = 1;
  final _selectedProductIds = List<String?>.filled(_maxProducts, null);
  final _selectedDosageUnits = List<String>.filled(_maxProducts, 'ml');

  MachineModel? get _selectedMachine =>
      widget.machines.where((m) => m.id == _selectedMachineId).firstOrNull;

  ProductModel? _selectedProduct(int index) => widget.products
      .where((p) => p.id == _selectedProductIds[index])
      .firstOrNull;

  @override
  void initState() {
    super.initState();
    final op = widget.initialOperation;
    if (op == null) return;

    _selectedTitle = OperationOptions.operationTypes.contains(op.title)
        ? op.title
        : null;
    _descController.text = op.description;
    _usedMachine = op.usedMachine;
    // Só pré-seleciona se a máquina ainda existir (senão o Dropdown quebra)
    if (_usedMachine && widget.machines.any((m) => m.id == op.machineId)) {
      _selectedMachineId = op.machineId;
    }

    _usedProducts = op.usedProducts;
    if (_usedProducts && op.appliedProducts.isNotEmpty) {
      _productsCount = op.appliedProducts.length.clamp(1, _maxProducts);
      for (int i = 0; i < _productsCount; i++) {
        final data = op.appliedProducts[i];
        final productId = data['productId'] as String?;
        if (widget.products.any((p) => p.id == productId)) {
          _selectedProductIds[i] = productId;
        }
        _dosageControllers[i].text = data['dosage']?.toString() ?? '';
        final unit = data['dosageUnit'] as String?;
        if (OperationOptions.dosageUnits.contains(unit)) {
          _selectedDosageUnits[i] = unit!;
        }
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _initialHorimeterController.dispose();
    _finalHorimeterController.dispose();
    for (final c in _dosageControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    HorimeterReading? horimeter;
    final machine = _usedMachine ? _selectedMachine : null;
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

    final appliedProducts = <Map<String, dynamic>>[
      if (_usedProducts)
        for (int i = 0; i < _productsCount; i++)
          if (_selectedProduct(i) case final product?)
            {
              'productId': product.id,
              'productName': product.name,
              'dosage': Parsers.decimal(_dosageControllers[i].text) ?? 0.0,
              'dosageUnit': _selectedDosageUnits[i],
            },
    ];

    await widget.onSubmit(
      OperationFormData(
        // farmId, data e autor são preenchidos pelo controller
        operation: OperationModel(
          title: _selectedTitle!,
          description: _descController.text.trim(),
          farmId: '',
          dateTimestamp: 0,
          usedMachine: _usedMachine,
          machineId: machine?.id,
          machineName: machine?.name,
          usedProducts: _usedProducts,
          appliedProducts: appliedProducts,
        ),
        appliedProducts: appliedProducts,
        initialHorimeter: horimeter?.initial,
        finalHorimeter: horimeter?.end,
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
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: "NOME DA OPERAÇÃO",
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.greenlightOne),
              ),
            ),
            initialValue: _selectedTitle,
            items: OperationOptions.operationTypes
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
          _buildSwitch(
            "Utilizou Maquinário?",
            _usedMachine,
            (v) => setState(() => _usedMachine = v),
          ),
          if (_usedMachine) ..._buildMachineSection(),
          _buildSwitch(
            "Utilizou Produtos?",
            _usedProducts,
            (v) => setState(() => _usedProducts = v),
          ),
          if (_usedProducts) ..._buildProductsSection(),
          const SizedBox(height: 32),
          PrimaryButton(text: widget.submitText, onPressed: _submit),
        ],
      ),
    );
  }

  Widget _buildSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: AppTextStyles.inputText.copyWith(fontWeight: FontWeight.bold),
      ),
      activeTrackColor: AppColors.greenlightOne.withValues(alpha: 0.4),
      activeThumbColor: AppColors.greenlightOne,
      value: value,
      onChanged: onChanged,
    );
  }

  List<Widget> _buildMachineSection() {
    final machine = _selectedMachine;
    return [
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: "SELECIONE O MAQUINÁRIO",
          border: OutlineInputBorder(),
        ),
        initialValue: _selectedMachineId,
        items: widget.machines
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
      if (machine != null && machine.isMotorized) ...[
        const SizedBox(height: 12),
        HorimeterFields(
          initialController: _initialHorimeterController,
          finalController: _finalHorimeterController,
        ),
      ],
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildProductsSection() {
    return [
      DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: "QUANTIDADE DE PRODUTOS",
          border: OutlineInputBorder(),
        ),
        initialValue: _productsCount,
        items: List.generate(_maxProducts, (i) => i + 1)
            .map(
              (n) => DropdownMenuItem(value: n, child: Text("$n produto(s)")),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _productsCount = v);
        },
      ),
      const SizedBox(height: 16),
      for (int i = 0; i < _productsCount; i++) _buildProductCard(i),
    ];
  }

  Widget _buildProductCard(int i) {
    return Card(
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
              isExpanded: true,
              decoration: InputDecoration(
                labelText: "PRODUTO #${i + 1}",
                border: const OutlineInputBorder(),
              ),
              initialValue: _selectedProductIds[i],
              items: widget.products
                  .map(
                    (p) => DropdownMenuItem<String>(
                      value: p.id!,
                      child: Text(
                        "${p.name} (${p.category}) - ${p.totalStock} ${p.unit}",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedProductIds[i] = v;
                final product = _selectedProduct(i);
                if (product == null) return;
                final suggested = OperationOptions.defaultDosageUnitFor(
                  product.unit,
                );
                if (OperationOptions.dosageUnits.contains(suggested)) {
                  _selectedDosageUnits[i] = suggested;
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _usedProducts && (v ?? '').isEmpty
                        ? "Obrigatório"
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // A key força o campo a refletir a unidade sugerida
                    // quando o produto é trocado
                    key: ValueKey('unit_${i}_${_selectedDosageUnits[i]}'),
                    decoration: const InputDecoration(
                      labelText: "UNIDADE",
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedDosageUnits[i],
                    items: OperationOptions.dosageUnits
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
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
    );
  }
}
