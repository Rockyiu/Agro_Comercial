import 'package:agro_comercial/common/models/warehouse_model.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/confirm_dialog.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/loading_overlay.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'edit_warehouse_controller.dart';
import 'edit_warehouse_state.dart';

// Resultado da tela de edição, devolvido para quem a abriu
sealed class EditWarehouseResult {
  const EditWarehouseResult();
}

class WarehouseRenamed extends EditWarehouseResult {
  final WarehouseModel warehouse;
  const WarehouseRenamed(this.warehouse);
}

class WarehouseDeleted extends EditWarehouseResult {
  const WarehouseDeleted();
}

class EditWarehousePage extends StatefulWidget {
  final WarehouseModel warehouse;
  const EditWarehousePage({super.key, required this.warehouse});
  @override
  State<EditWarehousePage> createState() => _EditWarehousePageState();
}

class _EditWarehousePageState extends State<EditWarehousePage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.warehouse.name,
  );
  final _controller = locator.get<EditWarehouseController>();

  @override
  void dispose() {
    _nameController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Executa a ação; se der certo, fecha a tela devolvendo [result]
  Future<void> _runAndClose(
    Future<void> Function() action,
    EditWarehouseResult result,
  ) async {
    await action();
    if (!mounted) return;
    final state = _controller.state;
    if (state is EditWarehouseErrorState) {
      context.showErrorSnackBar(state.message);
      return;
    }
    Navigator.pop(context, result);
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Excluir Armazém",
      message:
          "Tem certeza que deseja excluir este armazém? Todas as máquinas e produtos guardados nele também serão apagados.",
    );
    if (!confirmed || !mounted) return;
    await _runAndClose(
      () => _controller.deleteWarehouse(widget.warehouse),
      const WarehouseDeleted(),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _nameController.text.trim();
    await _runAndClose(
      () => _controller.updateWarehouseName(widget.warehouse, name),
      WarehouseRenamed(widget.warehouse.copyWith(name: name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Armazém"),
        actions: [
          IconButton(
            tooltip: 'Excluir armazém',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) => LoadingOverlay(
          isLoading: _controller.state is EditWarehouseLoadingState,
          child: child!,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextFormField(
                  controller: _nameController,
                  labelText: "Nome do armazém",
                  prefixIcon: Icons.warehouse_rounded,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? "Campo obrigatório" : null,
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
