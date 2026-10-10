import 'package:flutter/material.dart';
import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/constants/crop_options.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/models/plot_model.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/utils/area_units.dart';
import 'package:agro_comercial/common/widgets/area_unit_selector.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/common/models/farm_model.dart';
import 'package:agro_comercial/locator.dart';
import 'farm_controller.dart';

// Campos de um talhão no formulário. [original] é o talhão já gravado (null
// para um talhão novo): ao ser renomeado, ele mantém o id.
class _PlotFields {
  final PlotModel? original;
  final TextEditingController name;
  final TextEditingController area;
  final TextEditingController crop;

  // Talhão novo, ainda não gravado
  _PlotFields.blank(String name)
    : original = null,
      name = TextEditingController(text: name),
      area = TextEditingController(),
      crop = TextEditingController();

  _PlotFields.fromPlot(PlotModel plot)
    : original = plot,
      name = TextEditingController(text: plot.name),
      area = TextEditingController(text: plot.area.toString()),
      crop = TextEditingController(text: plot.crop);

  // Talhão renomeado mantém o id e guarda o nome antigo, para os lançamentos
  // anteriores continuarem ligados a ele
  PlotModel toPlot() {
    final name = this.name.text.trim();
    final area = double.tryParse(this.area.text.replaceAll(',', '.')) ?? 0.0;
    final crop = this.crop.text.trim();
    return original?.update(name: name, area: area, crop: crop) ??
        PlotModel.create(name: name, area: area, crop: crop);
  }

  void dispose() {
    name.dispose();
    area.dispose();
    crop.dispose();
  }
}

class EditFarmPage extends StatefulWidget {
  final FarmModel farm;

  const EditFarmPage({super.key, required this.farm});

  @override
  State<EditFarmPage> createState() => _EditFarmPageState();
}

class _EditFarmPageState extends State<EditFarmPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = locator.get<FarmController>(); // Agora será utilizado!

  late TextEditingController _nameController;
  late TextEditingController _cadProController;
  late TextEditingController _addressController;
  late TextEditingController _totalAreaController;

  final List<_PlotFields> _plotFields = [];
  late String _areaUnit = widget.farm.areaUnit;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Preenche os dados principais
    _nameController = TextEditingController(text: widget.farm.name);
    _cadProController = TextEditingController(text: widget.farm.cadPro);
    _addressController = TextEditingController(text: widget.farm.address);
    _totalAreaController = TextEditingController(text: widget.farm.totalArea);

    // Preenche os talhões existentes (ou um em branco, se não houver)
    _plotFields.addAll(widget.farm.plots.map(_PlotFields.fromPlot));
    if (_plotFields.isEmpty) _addField();
  }

  void _addField() {
    setState(() {
      _plotFields.add(_PlotFields.blank("Talhão ${_plotFields.length + 1}"));
    });
  }

  void _removeField(int index) {
    setState(() {
      _plotFields.removeAt(index).dispose();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cadProController.dispose();
    _addressController.dispose();
    _totalAreaController.dispose();
    for (final fields in _plotFields) {
      fields.dispose();
    }
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final updatedFarm = FarmModel(
        id: widget.farm.id,
        name: _nameController.text.trim(),
        cadPro: _cadProController.text.trim(),
        address: _addressController.text.trim(),
        totalArea: _totalAreaController.text.trim(),
        plots: _plotFields.map((fields) => fields.toPlot()).toList(),
        // Sem o dono, a fazenda some da lista do produtor após salvar
        ownerId: widget.farm.ownerId,
        areaUnit: _areaUnit,
      );

      try {
        await _controller.updateFarm(updatedFarm);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        context.showErrorSnackBar(
          "Erro ao atualizar a fazenda. Tente novamente.",
        );
        return;
      }
      if (!mounted) return;

      // Mostra o aviso na tela anterior, depois de fechar esta
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Fazenda atualizada com sucesso!'),
          backgroundColor: AppColors.greenlightOne,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Editar Fazenda",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CustomCircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Dados Principais",
                      style: AppTextStyles.midText20.copyWith(
                        color: AppColors.greenlightOne,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      controller: _nameController,
                      labelText: "Nome da Fazenda",
                      validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      controller: _cadProController,
                      labelText: "CAD/PRO",
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                    ),
                    const SizedBox(height: 16),
                    // Campo para Endereço
                    CustomTextFormField(
                      controller: _addressController,
                      labelText: "Endereço da Propriedade",
                      validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                    ),
                    const SizedBox(height: 16),
                    AreaUnitSelector(
                      value: _areaUnit,
                      onChanged: (unit) => setState(() => _areaUnit = unit),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    const SizedBox(height: 8),
                    CustomTextFormField(
                      controller: _totalAreaController,
                      labelText:
                          "Área Total (${AreaUnits.shortLabel(_areaUnit)})",
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                    ),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Áreas de Plantio (Talhões)",
                          style: AppTextStyles.midText20.copyWith(
                            color: AppColors.greenlightOne,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_rounded,
                            color: AppColors.greenlightOne,
                            size: 32,
                          ),
                          onPressed: _addField,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ...List.generate(_plotFields.length, (index) {
                      final fields = _plotFields[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: CustomTextFormField(
                                      controller: fields.name,
                                      labelText: "Identificação (Ex: Talhão 1)",
                                      validator: (v) =>
                                          Validator.validatePlotName(
                                            v,
                                            _plotFields.map((f) => f.name.text),
                                          ),
                                    ),
                                  ),
                                  if (_plotFields.length > 1)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_rounded,
                                        color: AppColors.danger,
                                      ),
                                      onPressed: () => _removeField(index),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextFormField(
                                      controller: fields.area,
                                      labelText:
                                          "Área Plantada (${AreaUnits.shortLabel(_areaUnit)})",
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: (v) =>
                                          v!.isEmpty ? "Obrigatório" : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: fields.crop.text.isEmpty
                                          ? null
                                          : fields.crop.text,
                                      decoration: const InputDecoration(
                                        labelText: "Cultura",
                                      ),
                                      items:
                                          CropOptions.withCurrent(
                                                fields.crop.text,
                                              )
                                              .map(
                                                (crop) => DropdownMenuItem(
                                                  value: crop,
                                                  child: Text(crop),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (v) {
                                        if (v != null) {
                                          fields.crop.text = v;
                                        }
                                      },
                                      validator: (v) => v == null || v.isEmpty
                                          ? "Obrigatório"
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: "Atualizar Dados",
                      onPressed: _handleUpdate,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
