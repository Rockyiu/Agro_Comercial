import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/loading_overlay.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'operation_controller.dart';
import 'operation_state.dart';
import 'widgets/operation_form.dart';

class RegisterOperationPage extends StatefulWidget {
  const RegisterOperationPage({super.key});

  @override
  State<RegisterOperationPage> createState() => _RegisterOperationPageState();
}

class _RegisterOperationPageState extends State<RegisterOperationPage> {
  final _controller = locator.get<OperationController>();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller.loadFarmResources();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(OperationFormData data) async {
    setState(() => _isProcessing = true);
    await _controller.saveOperation(
      data.operation,
      data.appliedProducts,
      initialHorimeter: data.initialHorimeter,
      finalHorimeter: data.finalHorimeter,
    );
    if (!mounted) return;

    // Ex: estoque insuficiente -> continua na tela mostrando o motivo
    final state = _controller.state;
    if (state is OperationErrorState) {
      setState(() => _isProcessing = false);
      context.showErrorSnackBar(state.message);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Registrar Operação",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoadingResources) {
            return const Center(child: CustomCircularProgressIndicator());
          }

          return LoadingOverlay(
            isLoading: _isProcessing,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: OperationForm(
                machines: _controller.machines,
                products: _controller.products,
                submitText: "Salvar Operação",
                strictHorimeter: true,
                onSubmit: _save,
              ),
            ),
          );
        },
      ),
    );
  }
}
