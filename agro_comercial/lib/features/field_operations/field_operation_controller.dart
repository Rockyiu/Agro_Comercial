import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/common/models/field_operation_model.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/services/field_operation_service/field_operation_service.dart';
import 'package:agro_comercial/services/stock_service/stock_service.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'field_operation_state.dart';

class FieldOperationController extends SafeChangeNotifier {
  final FieldOperationService _operationService;
  final StockService _stockService;
  final FarmController _farmController;

  FieldOperationController(
    this._operationService,
    this._stockService,
    this._farmController,
  );

  FieldOperationState _state = FieldOperationInitialState();
  FieldOperationState get state => _state;

  List<MachineModel> machines = [];
  List<ProductModel> products = [];
  bool isLoadingResources = true;

  // O produtor (dono da fazenda) altera e exclui qualquer lançamento; o
  // colaborador, só os que ele mesmo registrou
  bool canModify(String? createdBy) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    return _farmController.selectedFarm?.ownerId == uid || createdBy == uid;
  }

  void _changeState(FieldOperationState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadOperationsData() async {
    _changeState(FieldOperationLoadingState());
    try {
      final activeFarmId = _farmController.selectedFarm?.id;
      if (activeFarmId == null) {
        _changeState(
          FieldOperationErrorState("Nenhuma fazenda ativa selecionada."),
        );
        return;
      }
      final ops = await _operationService.getFieldOperations(activeFarmId);
      _changeState(FieldOperationSuccessState(operations: ops));
    } catch (e) {
      _changeState(FieldOperationErrorState("Erro ao carregar operações."));
    }
  }

  // Máquinas e produtos da fazenda ativa (usados nos formulários e no estoque)
  Future<void> loadFarmResources() async {
    isLoadingResources = true;
    notifyListeners();
    try {
      await _refreshFarmResources();
    } catch (e) {
      debugPrint("Erro ao carregar recursos: $e");
    } finally {
      isLoadingResources = false;
      notifyListeners();
    }
  }

  // Recarrega o estoque sem mostrar o loading na tela (antes de editar/excluir,
  // para estornar sobre os valores mais recentes do banco)
  Future<void> _refreshFarmResources() async {
    final activeFarmId = _farmController.selectedFarm?.id;
    if (activeFarmId == null) return;
    final resources = await _stockService.loadFarmResources(activeFarmId);
    machines = resources.machines;
    products = resources.products;
  }

  // Horas trabalhadas, apenas para máquinas motorizadas (com horímetro)
  double? _workedHours(
    String? machineId,
    double? initialHorimeter,
    double? finalHorimeter,
  ) {
    if (machineId == null ||
        initialHorimeter == null ||
        finalHorimeter == null) {
      return null;
    }
    final machine = machines.where((m) => m.id == machineId).firstOrNull;
    if (machine == null || !machine.isMotorized) return null;
    return finalHorimeter - initialHorimeter;
  }

  // Só a Aplicação movimenta estoque e horímetro; a Vistoria não.
  List<ProductUsage> _productUsages(FieldOperationModel op) {
    if (op.isInspection ||
        op.productId == null ||
        op.dosage == null ||
        op.dosageUnit == null) {
      return const [];
    }
    return [
      ProductUsage(
        productId: op.productId!,
        quantity: op.dosage!,
        unit: op.dosageUnit!,
      ),
    ];
  }

  List<MachineUsage> _machineUsages(FieldOperationModel op) {
    if (op.isInspection || op.machineId == null || op.machineHours == null) {
      return const [];
    }
    return [MachineUsage(machineId: op.machineId!, hours: op.machineHours!)];
  }

  // Monta a vistoria/aplicação que será gravada a partir do formulário
  FieldOperationModel _buildOperation(
    FieldOperationModel form, {
    required String farmId,
    required int dateTimestamp,
    required String? createdBy,
    String? id,
    double? initialHorimeter,
    double? finalHorimeter,
  }) {
    return FieldOperationModel(
      id: id,
      type: form.type,
      plotName: form.plotName,
      plotId: _farmController.selectedFarm?.findPlot(name: form.plotName)?.id,
      dateTimestamp: dateTimestamp,
      farmId: farmId,
      createdBy: createdBy,
      condition: form.condition,
      observations: form.observations,
      productId: form.productId,
      productName: form.productName,
      dosage: form.dosage,
      dosageUnit: form.dosageUnit,
      unitPrice: form.unitPrice,
      productUnit: form.productUnit,
      machineId: form.machineId,
      machineName: form.machineName,
      machineHours: form.isInspection
          ? null
          : _workedHours(form.machineId, initialHorimeter, finalHorimeter),
    );
  }

  Future<void> launchOperation(
    FieldOperationModel operation, {
    double? initialHorimeter,
    double? finalHorimeter,
  }) async {
    _changeState(FieldOperationLoadingState());
    try {
      final activeFarmId = _farmController.selectedFarm?.id;
      if (activeFarmId == null) {
        _changeState(
          FieldOperationErrorState("Nenhuma fazenda ativa selecionada."),
        );
        return;
      }

      // Confere o estoque com os valores mais recentes do banco (outra pessoa
      // pode ter lançado depois que o formulário abriu)
      await _refreshFarmResources();

      final newOperation = _buildOperation(
        operation,
        farmId: activeFarmId, // <- Vinculado ao ID da fazenda ativa
        dateTimestamp: operation.dateTimestamp,
        createdBy: FirebaseAuth.instance.currentUser?.uid,
        initialHorimeter: initialHorimeter,
        finalHorimeter: finalHorimeter,
      );

      await _stockService.applyUsage(
        products: products,
        machines: machines,
        consumeProducts: _productUsages(newOperation),
        consumeMachines: _machineUsages(newOperation),
        alsoWrite: (batch) =>
            _operationService.addCreateToBatch(batch, newOperation),
      );
      await loadOperationsData();
    } on InsufficientStockException catch (e) {
      _changeState(FieldOperationErrorState(e.toString()));
    } catch (e) {
      _changeState(FieldOperationErrorState("Erro ao salvar operação."));
    }
  }

  Future<void> updateFullOperation(
    FieldOperationModel oldOp,
    FieldOperationModel newOp, {
    double? initialHorimeter,
    double? finalHorimeter,
  }) async {
    _changeState(FieldOperationLoadingState());
    try {
      final activeFarmId = _farmController.selectedFarm?.id;
      if (activeFarmId == null) {
        _changeState(
          FieldOperationErrorState("Nenhuma fazenda ativa selecionada."),
        );
        return;
      }

      // Estorna sobre o estoque atual do banco
      await _refreshFarmResources();

      final updatedOperation = _buildOperation(
        newOp,
        id: oldOp.id,
        farmId: activeFarmId,
        dateTimestamp: oldOp.dateTimestamp,
        createdBy: oldOp.createdBy,
        initialHorimeter: initialHorimeter,
        finalHorimeter: finalHorimeter,
      );

      // Devolve o que a aplicação antiga usou e retira o que a nova usa,
      // validando tudo antes de gravar (se faltar estoque, nada é alterado)
      await _stockService.applyUsage(
        products: products,
        machines: machines,
        restoreProducts: _productUsages(oldOp),
        restoreMachines: _machineUsages(oldOp),
        consumeProducts: _productUsages(updatedOperation),
        consumeMachines: _machineUsages(updatedOperation),
        alsoWrite: (batch) =>
            _operationService.addUpdateToBatch(batch, updatedOperation),
      );
      await loadOperationsData();
    } on InsufficientStockException catch (e) {
      _changeState(
        FieldOperationErrorState("${e.toString()} (após recálculo)"),
      );
    } catch (e) {
      _changeState(FieldOperationErrorState("Erro ao atualizar operação."));
    }
  }

  Future<void> deleteSingleOperation(FieldOperationModel op) async {
    _changeState(FieldOperationLoadingState());
    try {
      await _refreshFarmResources();
      await _stockService.applyUsage(
        products: products,
        machines: machines,
        restoreProducts: _productUsages(op),
        restoreMachines: _machineUsages(op),
        alsoWrite: (batch) =>
            _operationService.addDeleteToBatch(batch, [op.id!]),
      );
      await loadOperationsData();
    } catch (e) {
      _changeState(FieldOperationErrorState("Erro ao excluir."));
    }
  }

  Future<void> deleteSelectedOperations(List<String> ids) async {
    _changeState(FieldOperationLoadingState());
    try {
      final activeFarmId = _farmController.selectedFarm?.id;
      if (activeFarmId == null) {
        _changeState(
          FieldOperationErrorState("Nenhuma fazenda ativa selecionada."),
        );
        return;
      }

      await _refreshFarmResources();
      final selectedIds = ids.toSet();
      final toDelete = (await _operationService.getFieldOperations(
        activeFarmId,
      )).where((op) => selectedIds.contains(op.id)).toList();

      // Estorna todas de uma vez
      await _stockService.applyUsage(
        products: products,
        machines: machines,
        restoreProducts: toDelete.expand(_productUsages).toList(),
        restoreMachines: toDelete.expand(_machineUsages).toList(),
        alsoWrite: (batch) => _operationService.addDeleteToBatch(
          batch,
          toDelete.map((op) => op.id!),
        ),
      );
      await loadOperationsData();
    } catch (e) {
      _changeState(FieldOperationErrorState("Erro ao excluir em lote."));
    }
  }
}
