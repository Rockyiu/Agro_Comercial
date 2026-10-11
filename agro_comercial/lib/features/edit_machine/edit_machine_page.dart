import 'package:agro_comercial/common/models/machine_cost_data.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/photo_change.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/utils/parsers.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/confirm_dialog.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/loading_overlay.dart';
import 'package:agro_comercial/common/widgets/local_photo.dart';
import 'package:agro_comercial/common/widgets/machine_cost_fields.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/locator.dart';
import 'package:agro_comercial/services/local_media_service/local_media_service.dart';
import 'package:flutter/material.dart';

import 'edit_machine_controller.dart';
import 'edit_machine_state.dart';

class EditMachinePage extends StatefulWidget {
  final MachineModel machine;

  const EditMachinePage({super.key, required this.machine});

  @override
  State<EditMachinePage> createState() => _EditMachinePageState();
}

class _EditMachinePageState extends State<EditMachinePage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.machine.name);
  late final _brandController = TextEditingController(
    text: widget.machine.brand,
  );
  late final _modelController = TextEditingController(
    text: widget.machine.model,
  );
  late final _powerController = TextEditingController(
    text: widget.machine.power,
  );
  // Valor exibido no início: usado para saber se o horímetro foi alterado
  late final _initialHours = Formatters.editable(widget.machine.workingHours);
  late final _hoursController = TextEditingController(text: _initialHours);
  late final _costControllers = MachineCostControllers(widget.machine.costData);

  PhotoChange? _photo;
  final _controller = locator.get<EditMachineController>();

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _powerController.dispose();
    _hoursController.dispose();
    _costControllers.dispose();
    _controller.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? "Campo obrigatório" : null;

  // Executa a ação no controller; se der certo, fecha a tela com o aviso
  Future<void> _runAndClose(
    Future<void> Function() action,
    String successMessage,
  ) async {
    await action();
    if (!mounted) return;
    final state = _controller.state;
    if (state is EditMachineErrorState) {
      context.showErrorSnackBar(state.message);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(successMessage)));
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Excluir Máquina",
      message:
          "Tem certeza que deseja excluir esta máquina? Esta ação não pode ser desfeita.",
    );
    if (!confirmed || !mounted) return;
    await _runAndClose(
      () => _controller.deleteMachineData(widget.machine.id!),
      "Máquina excluída.",
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final isMotorized = widget.machine.isMotorized;

    // copyWith mantém os demais campos (ex: isMotorized)
    final updatedMachine = widget.machine.copyWith(
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      power: _powerController.text.trim(),
      workingHours: isMotorized
          ? Parsers.decimal(_hoursController.text) ?? 0
          : 0,
      // Campos apagados: grava os dados de custo vazios
      costData: _costControllers.toCostData() ?? const MachineCostData(),
    );

    await _runAndClose(
      () => _controller.updateMachineData(
        updatedMachine,
        hoursChanged:
            isMotorized && _hoursController.text.trim() != _initialHours,
        photo: _photo,
      ),
      "Máquina atualizada com sucesso!",
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMotorized = widget.machine.isMotorized;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isMotorized ? "Detalhes da Máquina" : "Detalhes do Implemento",
        ),
        actions: [
          IconButton(
            tooltip: 'Excluir',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) => LoadingOverlay(
          isLoading: _controller.state is EditMachineLoadingState,
          child: child!,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PhotoEditor(
                  kind: MediaKind.machine,
                  id: widget.machine.id,
                  change: _photo,
                  onChanged: (change) => setState(() => _photo = change),
                  icon: isMotorized
                      ? Icons.agriculture_rounded
                      : Icons.construction_rounded,
                ),
                const SizedBox(height: 28),

                CustomTextFormField(
                  controller: _nameController,
                  labelText: "Nome da máquina",
                  validator: _required,
                ),
                CustomTextFormField(
                  controller: _brandController,
                  labelText: "Marca",
                  validator: _required,
                ),
                CustomTextFormField(
                  controller: _modelController,
                  labelText: "Modelo",
                  validator: _required,
                ),

                if (isMotorized) ...[
                  CustomTextFormField(
                    controller: _powerController,
                    labelText: "Potência (cv)",
                    keyboardType: TextInputType.number,
                    validator: _required,
                  ),
                  CustomTextFormField(
                    controller: _hoursController,
                    labelText: "Horímetro (horas trabalhadas)",
                    helperText: "Também sobe sozinho com as operações lançadas",
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validator.validateNonNegativeDecimal,
                  ),
                ],
                const SizedBox(height: 8),
                MachineCostFields(
                  controllers: _costControllers,
                  isMotorized: isMotorized,
                ),
                const SizedBox(height: 32),

                PrimaryButton(
                  text: 'Salvar Alterações',
                  icon: Icons.check_rounded,
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
