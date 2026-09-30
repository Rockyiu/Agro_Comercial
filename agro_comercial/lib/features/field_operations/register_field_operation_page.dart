import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/loading_overlay.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'field_operation_controller.dart';
import 'field_operation_state.dart';
import 'widgets/field_operation_form.dart';

class RegisterFieldOperationPage extends StatefulWidget {
  const RegisterFieldOperationPage({super.key});

  @override
  State<RegisterFieldOperationPage> createState() =>
      _RegisterFieldOperationPageState();
}

class _RegisterFieldOperationPageState
    extends State<RegisterFieldOperationPage> {
  final _controller = locator.get<FieldOperationController>();
  bool _isProcessing = false;

  // Talhões cadastrados na fazenda ativa
  final List<String> _plots =
      locator
          .get<FarmController>()
          .selectedFarm
          ?.plantedFields
          .map((field) => field['name'].toString())
          .toList() ??
      [];

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

  Future<void> _save(FieldOperationFormData data) async {
    setState(() => _isProcessing = true);
    await _controller.launchOperation(
      data.operation,
      initialHorimeter: data.initialHorimeter,
      finalHorimeter: data.finalHorimeter,
    );
    if (!mounted) return;

    final state = _controller.state;
    if (state is FieldOperationErrorState) {
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
          "Lançamento de Campo",
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
              child: FieldOperationForm(
                machines: _controller.machines,
                products: _controller.products,
                plots: _plots,
                submitText: "Confirmar Lançamento",
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
