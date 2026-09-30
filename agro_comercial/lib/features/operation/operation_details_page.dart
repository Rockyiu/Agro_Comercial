import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/operation_model.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/confirm_dialog.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/loading_overlay.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'operation_controller.dart';
import 'operation_state.dart';
import 'widgets/operation_form.dart';

class OperationDetailsPage extends StatefulWidget {
  final OperationModel operation;
  const OperationDetailsPage({super.key, required this.operation});

  @override
  State<OperationDetailsPage> createState() => _OperationDetailsPageState();
}

class _OperationDetailsPageState extends State<OperationDetailsPage> {
  final _controller = locator.get<OperationController>();
  bool _isEditing = false;
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

  // Executa a ação no controller; em caso de erro continua na tela e avisa
  Future<void> _runAndClose(Future<void> Function() action) async {
    setState(() => _isProcessing = true);
    await action();
    if (!mounted) return;

    final state = _controller.state;
    if (state is OperationErrorState) {
      setState(() => _isProcessing = false);
      context.showErrorSnackBar(state.message);
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Excluir Lançamento",
      message:
          "Deseja apagar esta operação do histórico? O maquinário e estoque serão devidamente estornados!",
    );
    if (!confirmed) return;
    await _runAndClose(
      () => _controller.deleteSingleOperation(widget.operation),
    );
  }

  Future<void> _update(OperationFormData data) {
    return _runAndClose(
      () => _controller.updateFullOperation(
        widget.operation,
        data.operation,
        data.appliedProducts,
        initialHorimeter: data.initialHorimeter,
        finalHorimeter: data.finalHorimeter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          _isEditing ? "Editar Operação" : "Detalhes da Operação",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _delete,
            ),
        ],
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
              child: _isEditing ? _buildEditForm() : _buildSummary(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.amber.withValues(alpha: 0.2),
          child: Text(
            "ATENÇÃO: Ao salvar a edição, o sistema fará o recálculo inteligente e estornará os materiais da operação antiga automaticamente.",
            style: AppTextStyles.smallText.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        OperationForm(
          machines: _controller.machines,
          products: _controller.products,
          initialOperation: widget.operation,
          submitText: "Salvar Alterações",
          onSubmit: _update,
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final operation = widget.operation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          operation.title,
          style: AppTextStyles.midText20.copyWith(
            color: AppColors.greenlightOne,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              operation.description.isEmpty
                  ? "Sem descrição detalhada."
                  : operation.description,
              style: AppTextStyles.inputText,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (operation.usedMachine)
          ListTile(
            leading: const Icon(
              Icons.agriculture,
              color: AppColors.greenlightOne,
            ),
            title: Text("Maquinário: ${operation.machineName}"),
            subtitle: Text(
              operation.machineHours != null
                  ? "Operou por: ${operation.machineHours!.toStringAsFixed(1)}h"
                  : "Implemento manual / Sem horas",
            ),
          ),
        if (operation.usedProducts) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(),
          ),
          Text(
            "Produtos Aplicados na Calda:",
            style: AppTextStyles.smallText.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          ...operation.appliedProducts.map(
            (p) => ListTile(
              leading: const Icon(Icons.science, color: Colors.orange),
              title: Text(p['productName'] ?? 'Produto'),
              trailing: Text(
                "${p['dosage']} ${p['dosageUnit']}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
