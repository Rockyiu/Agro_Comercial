import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'edit_warehouse_controller.dart';

class EditWarehousePage extends StatefulWidget {
  final WarehouseModel warehouse;
  const EditWarehousePage({super.key, required this.warehouse});
  @override
  State<EditWarehousePage> createState() => _EditWarehousePageState();
}

class _EditWarehousePageState extends State<EditWarehousePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final _controller = locator.get<EditWarehouseController>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.warehouse.name);
    _controller.addListener(_handleStateChange);
  }

  void _handleStateChange() {
    final state = _controller.state;
    if (state is EditWarehouseLoadingState) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CustomCircularProgressIndicator(),
      );
    } else if (state is EditWarehouseSuccessState) {
      Navigator.pop(context); // Fecha loading
      Navigator.pop(context); // Fecha edição
      Navigator.pop(context); // Volta pra aba Armazém para forçar atualização
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ação concluída!"),
          backgroundColor: AppColors.greenlightOne,
        ),
      );
    } else if (state is EditWarehouseErrorState) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Excluir Armazém",
          style: AppTextStyles.midText20.copyWith(
            color: AppColors.greenlightOne,
          ),
        ),
        content: const Text(
          "Tem certeza que deseja excluir este armazém? Todas as máquinas nele ficarão sem local.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.deleteWarehouse(widget.warehouse.id!);
            },
            child: const Text(
              "Sim, excluir",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Editar Armazém",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _showDeleteDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextFormField(
                controller: _nameController,
                labelText: "NOME DO ARMAZÉM",
                validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Salvar Alterações',
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _controller.updateWarehouseName(
                      widget.warehouse,
                      _nameController.text.trim(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
