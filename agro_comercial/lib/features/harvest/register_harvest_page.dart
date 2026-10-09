import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/constants/crop_options.dart';
import 'package:agro_comercial/common/models/harvest_model.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/utils/parsers.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/confirm_dialog.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/loading_overlay.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'harvest_controller.dart';
import 'harvest_state.dart';

// Cadastro e edição da produção colhida em um talhão
class RegisterHarvestPage extends StatefulWidget {
  final HarvestModel? harvestToEdit;

  const RegisterHarvestPage({super.key, this.harvestToEdit});

  @override
  State<RegisterHarvestPage> createState() => _RegisterHarvestPageState();
}

class _RegisterHarvestPageState extends State<RegisterHarvestPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = locator.get<HarvestController>();
  final _farm = locator.get<FarmController>().selectedFarm;

  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _obsController = TextEditingController();

  String? _selectedPlot;
  String? _selectedCrop;
  String _selectedUnit = HarvestUnits.bag;
  DateTime _date = DateTime.now();

  bool get _isEditing => widget.harvestToEdit != null;

  // Talhão da colheita em edição, com o nome atual (se foi renomeado)
  late final String _editingPlot = widget.harvestToEdit == null
      ? ''
      : _farm?.currentPlotName(
              id: widget.harvestToEdit!.plotId,
              name: widget.harvestToEdit!.plotName,
            ) ??
            widget.harvestToEdit!.plotName;

  // Talhões da fazenda + o da colheita em edição (se foi removido)
  late final List<String> _plots = {
    ...?_farm?.plotNames,
    if (_editingPlot.isNotEmpty) _editingPlot,
  }.toList();

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_refresh);
    _priceController.addListener(_refresh);

    final harvest = widget.harvestToEdit;
    if (harvest == null) return;
    _selectedPlot = _editingPlot.isEmpty ? null : _editingPlot;
    _selectedCrop = harvest.crop.isEmpty ? null : harvest.crop;
    if (HarvestUnits.labels.containsKey(harvest.unit)) {
      _selectedUnit = harvest.unit;
    }
    _date = DateTime.fromMillisecondsSinceEpoch(harvest.dateTimestamp);
    _quantityController.text = Formatters.editable(harvest.quantity);
    _priceController.text = Formatters.editable(harvest.unitPrice);
    _obsController.text = harvest.observation ?? '';
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _controller.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  // Ao escolher o talhão, sugere a cultura cadastrada nele
  void _onPlotChanged(String? plot) {
    setState(() {
      _selectedPlot = plot;
      final crop = _farm?.findPlot(name: plot)?.crop ?? '';
      if (crop.isNotEmpty) _selectedCrop = crop;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // Executa a ação no controller; se der certo, fecha a tela
  Future<void> _runAndClose(Future<void> Function() action) async {
    await action();
    if (!mounted) return;
    final state = _controller.state;
    if (state is HarvestErrorState) {
      context.showErrorSnackBar(state.message);
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final harvest = HarvestModel(
      id: widget.harvestToEdit?.id,
      farmId: widget.harvestToEdit?.farmId ?? '',
      plotName: _selectedPlot!,
      crop: _selectedCrop ?? '',
      dateTimestamp: _date.millisecondsSinceEpoch,
      quantity: Parsers.decimal(_quantityController.text) ?? 0,
      unit: _selectedUnit,
      unitPrice: Parsers.decimal(_priceController.text) ?? 0,
      observation: _obsController.text.trim(),
      createdBy: widget.harvestToEdit?.createdBy,
    );

    await _runAndClose(
      () => _isEditing
          ? _controller.updateHarvest(harvest)
          : _controller.saveHarvest(harvest),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Excluir Colheita",
      message: "Deseja apagar este registro de produção?",
    );
    if (!confirmed) return;
    await _runAndClose(
      () => _controller.deleteHarvest(widget.harvestToEdit!.id!),
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
    final revenue =
        (Parsers.decimal(_quantityController.text) ?? 0) *
        (Parsers.decimal(_priceController.text) ?? 0);

    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          _isEditing ? "Editar Colheita" : "Registrar Colheita",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) => LoadingOverlay(
          isLoading: _controller.state is HarvestLoadingState,
          child: child!,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: _decoration("TALHÃO COLHIDO"),
                  initialValue: _selectedPlot,
                  items: _plots
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: _onPlotChanged,
                  validator: (v) => v == null ? "Selecione o talhão" : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  // A key força o campo a refletir a cultura sugerida
                  key: ValueKey('crop_$_selectedCrop'),
                  isExpanded: true,
                  decoration: _decoration("CULTURA"),
                  initialValue: _selectedCrop,
                  items: CropOptions.withCurrent(_selectedCrop)
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCrop = v),
                  validator: (v) => v == null ? "Selecione a cultura" : null,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event, color: AppColors.greenlightOne),
                  label: Text(
                    "Data da colheita: ${Formatters.date(_date.millisecondsSinceEpoch)}",
                    style: const TextStyle(color: AppColors.greenlightOne),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: CustomTextFormField(
                        controller: _quantityController,
                        labelText: "QUANTIDADE PRODUZIDA",
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validator.validateNumber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: _decoration("UNIDADE"),
                          initialValue: _selectedUnit,
                          items: HarvestUnits.labels.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(
                                    e.value,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedUnit = v!),
                        ),
                      ),
                    ),
                  ],
                ),
                CustomTextFormField(
                  controller: _priceController,
                  labelText: "PREÇO DE VENDA POR $_selectedUnit (R\$)",
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validator.validateNumber,
                ),
                CustomTextFormField(
                  controller: _obsController,
                  labelText: "OBSERVAÇÕES",
                  hintText: "Ex: umidade, comprador, contrato (opcional)",
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.greenlightOne.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "RECEITA",
                        style: TextStyle(
                          color: AppColors.greenlightOne,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.currency(revenue),
                        style: AppTextStyles.midText20.copyWith(
                          color: AppColors.greenlightOne,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: _isEditing ? "Salvar Alterações" : "Salvar Colheita",
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
