import 'package:agro_comercial/common/models/photo_change.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/empty_state.dart';
import 'package:agro_comercial/common/widgets/loading_overlay.dart';
import 'package:agro_comercial/common/widgets/local_photo.dart';
import 'package:agro_comercial/common/widgets/machine_cost_fields.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/locator.dart';
import 'package:agro_comercial/services/local_media_service/local_media_service.dart';
import 'package:flutter/material.dart';

import 'register_machine_controller.dart';
import 'register_machine_state.dart';

class RegisterMachinePage extends StatefulWidget {
  // Armazém já escolhido (cadastro feito de dentro de um armazém)
  final WarehouseModel? initialWarehouse;

  const RegisterMachinePage({super.key, this.initialWarehouse});

  @override
  State<RegisterMachinePage> createState() => _RegisterMachinePageState();
}

class _RegisterMachinePageState extends State<RegisterMachinePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _powerController = TextEditingController();
  final _hoursController = TextEditingController();
  final _costControllers = MachineCostControllers();

  String? _selectedWarehouseId;
  bool _isMotorized = true;
  PhotoChange? _photo;
  final _controller = locator.get<RegisterMachineController>();

  @override
  void initState() {
    super.initState();
    _selectedWarehouseId = widget.initialWarehouse?.id;
    _controller.loadWarehouses();
  }

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

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await _controller.saveMachine(
      name: _nameController.text,
      brand: _brandController.text,
      model: _modelController.text,
      power: _isMotorized ? _powerController.text : '',
      // Implemento não tem horímetro: fica 0
      workingHoursStr: _isMotorized ? _hoursController.text : "",
      warehouseId: _selectedWarehouseId!,
      isMotorized: _isMotorized,
      costData: _costControllers.toCostData(),
      photo: _photo,
    );
    if (!mounted) return;

    final state = _controller.state;
    if (state is RegisterMachineErrorState) {
      context.showErrorSnackBar(state.message);
      return;
    }
    // Mostra o aviso na tela anterior, depois de fechar esta
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text("Máquina salva com sucesso!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cadastrar Máquina")),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoadingWarehouses) {
            return const CustomCircularProgressIndicator();
          }

          final warehouses = _controller.warehouses;
          if (warehouses.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.warehouse_rounded,
                title: "Nenhum armazém",
                message: "Crie um armazém antes de cadastrar uma máquina!",
              ),
            );
          }

          return LoadingOverlay(
            isLoading: _controller.state is RegisterMachineLoadingState,
            child: _buildForm(warehouses),
          );
        },
      ),
    );
  }

  Widget _buildForm(List<WarehouseModel> warehouses) {
    // O armazém escolhido pode não estar na lista (ex: excluído)
    final selectedId = warehouses.any((w) => w.id == _selectedWarehouseId)
        ? _selectedWarehouseId
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PhotoEditor(
              kind: MediaKind.machine,
              id: null,
              change: _photo,
              onChanged: (change) => setState(() => _photo = change),
              icon: Icons.agriculture_rounded,
            ),
            const SizedBox(height: 28),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Armazém",
                prefixIcon: Icon(Icons.warehouse_rounded),
              ),
              initialValue: selectedId,
              items: [
                for (final w in warehouses)
                  DropdownMenuItem(value: w.id, child: Text(w.name)),
              ],
              onChanged: (value) =>
                  setState(() => _selectedWarehouseId = value),
              validator: (value) =>
                  value == null ? "Selecione um armazém" : null,
            ),
            const SizedBox(height: 16),

            CustomTextFormField(
              controller: _nameController,
              labelText: "Nome da máquina",
              hintText: "Ex: Trator Principal",
              validator: _required,
            ),
            CustomTextFormField(
              controller: _brandController,
              labelText: "Marca",
              hintText: "Ex: John Deere, Massey Ferguson",
              validator: _required,
            ),
            CustomTextFormField(
              controller: _modelController,
              labelText: "Modelo",
              hintText: "Ex: 5075E",
              validator: _required,
            ),

            // Motorizada (trator, colhedora) ou implemento (sem motor)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "Possui motor / horímetro?",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: const Text(
                "Desmarque para implementos: plantadeira, grade, pulverizador de arrasto, etc.",
              ),
              value: _isMotorized,
              onChanged: (val) => setState(() => _isMotorized = val),
            ),
            const SizedBox(height: 8),

            if (_isMotorized) ...[
              CustomTextFormField(
                controller: _powerController,
                labelText: "Potência (cv)",
                hintText: "Ex: 75",
                keyboardType: TextInputType.number,
                validator: _required,
              ),
              CustomTextFormField(
                controller: _hoursController,
                labelText: "Horímetro atual (opcional)",
                hintText: "Ex: 1500 (fica 0 se vazio)",
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? null
                    : Validator.validateNonNegativeDecimal(v),
              ),
            ],
            const SizedBox(height: 8),
            MachineCostFields(
              controllers: _costControllers,
              isMotorized: _isMotorized,
            ),
            const SizedBox(height: 32),

            PrimaryButton(
              text: 'Salvar Máquina',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
