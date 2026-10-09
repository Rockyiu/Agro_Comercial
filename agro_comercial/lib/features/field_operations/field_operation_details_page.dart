import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/field_operation_model.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/confirm_dialog.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/loading_overlay.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'field_operation_controller.dart';
import 'field_operation_state.dart';
import 'widgets/field_operation_form.dart';

class FieldOperationDetailsPage extends StatefulWidget {
  final FieldOperationModel operation;
  const FieldOperationDetailsPage({super.key, required this.operation});

  @override
  State<FieldOperationDetailsPage> createState() =>
      _FieldOperationDetailsPageState();
}

class _FieldOperationDetailsPageState extends State<FieldOperationDetailsPage> {
  final _controller = locator.get<FieldOperationController>();
  bool _isEditing = false;
  bool _isProcessing = false;

  final _farm = locator.get<FarmController>().selectedFarm;

  // Talhões cadastrados na fazenda ativa
  late final List<String> _plots = _farm?.plotNames ?? [];

  // Nome atual do talhão do lançamento (acompanha renomeações)
  late final String _plotName =
      _farm?.currentPlotName(
        id: widget.operation.plotId,
        name: widget.operation.plotName,
      ) ??
      widget.operation.plotName;

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
    if (state is FieldOperationErrorState) {
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
          "Deseja apagar este histórico? O estoque e o maquinário serão estornados automaticamente.",
    );
    if (!confirmed) return;
    await _runAndClose(
      () => _controller.deleteSingleOperation(widget.operation),
    );
  }

  Future<void> _update(FieldOperationFormData data) {
    return _runAndClose(
      () => _controller.updateFullOperation(
        widget.operation,
        data.operation,
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
          _isEditing ? "Editar Campo" : "Detalhes da Vistoria",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_controller.canModify(widget.operation.createdBy))
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
            "ATENÇÃO: Ao salvar, o sistema fará o recálculo e estorno automático dos insumos anteriores.",
            style: AppTextStyles.smallText.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FieldOperationForm(
          machines: _controller.machines,
          products: _controller.products,
          plots: _plots,
          initialOperation: widget.operation.copyWith(plotName: _plotName),
          submitText: "Salvar Alterações",
          onSubmit: _update,
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final operation = widget.operation;
    final observations = operation.observations ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "${operation.type} - $_plotName",
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
              observations.isEmpty
                  ? "Sem observações detalhadas."
                  : observations,
              style: AppTextStyles.inputText,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (operation.isInspection)
          ListTile(
            leading: const Icon(Icons.favorite, color: AppColors.greenlightOne),
            title: const Text("Condição:"),
            subtitle: Text(operation.condition ?? ''),
          )
        else ...[
          ListTile(
            leading: const Icon(Icons.science, color: Colors.orange),
            title: Text("Insumo: ${operation.productName}"),
            subtitle: Text(
              "Dosagem: ${operation.dosage} ${operation.dosageUnit}",
            ),
          ),
          if (operation.machineId != null)
            ListTile(
              leading: const Icon(
                Icons.agriculture,
                color: AppColors.greenlightOne,
              ),
              title: Text("Maquinário: ${operation.machineName}"),
              subtitle: Text(
                operation.machineHours != null
                    ? "Operou por: ${operation.machineHours!.toStringAsFixed(1)}h"
                    : "Implemento manual / Sem motor",
              ),
            ),
        ],
      ],
    );
  }
}
