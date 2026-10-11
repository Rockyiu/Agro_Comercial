import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/loading_overlay.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'register_warehouse_controller.dart';
import 'register_warehouse_state.dart';

class RegisterWarehousePage extends StatefulWidget {
  const RegisterWarehousePage({super.key});

  @override
  State<RegisterWarehousePage> createState() => _RegisterWarehousePageState();
}

class _RegisterWarehousePageState extends State<RegisterWarehousePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _controller = locator.get<RegisterWarehouseController>();

  @override
  void dispose() {
    _nameController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _controller.saveWarehouse(name: _nameController.text);
    if (!mounted) return;

    final state = _controller.state;
    if (state is RegisterWarehouseErrorState) {
      context.showErrorSnackBar(state.message);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text("Armazém cadastrado com sucesso!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cadastrar Armazém")),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) => LoadingOverlay(
          isLoading: _controller.state is RegisterWarehouseLoadingState,
          child: child!,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: IconBadge(
                    icon: Icons.warehouse_rounded,
                    size: 72,
                    color: AppColors.earth,
                    background: AppColors.earthSoft,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dê um nome para o seu novo local de armazenamento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 28),
                CustomTextFormField(
                  controller: _nameController,
                  labelText: "Nome do armazém",
                  hintText: "Ex: Galpão Principal, Silo de Sementes",
                  prefixIcon: Icons.warehouse_rounded,
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? "O nome não pode ser vazio"
                      : null,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Salvar Armazém',
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
