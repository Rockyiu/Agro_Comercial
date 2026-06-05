import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  void initState() {
    super.initState();
    _controller.addListener(_handleStateChange);
  }

  void _handleStateChange() {
    final state = _controller.state;
    if (state is RegisterWarehouseLoadingState) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CustomCircularProgressIndicator(),
      );
    } else if (state is RegisterWarehouseSuccessState) {
      Navigator.pop(context); // Fecha o loading
      Navigator.pop(context); // Volta pra tela de Armazém
    } else if (state is RegisterWarehouseErrorState) {
      Navigator.pop(context); // Fecha o loading
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Cadastrar Armazém",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Dê um nome para o seu novo local de armazenamento.',
                style: AppTextStyles.midText20.copyWith(
                  color: AppColors.greenlightOne,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CustomTextFormField(
                controller: _nameController,
                labelText: "NOME DO ARMAZÉM",
                hintText: "Ex: Galpão Principal, Silo de Sementes",
                validator: (value) => value == null || value.isEmpty
                    ? "O nome não pode ser vazio"
                    : null,
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Salvar Armazém',
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _controller.saveWarehouse(name: _nameController.text);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
