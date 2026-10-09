import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/common/models/operation_model.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/services/operation_service/operation_service.dart';
import 'package:agro_comercial/services/stock_service/stock_service.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'operation_state.dart';

class OperationController extends SafeChangeNotifier {
  final OperationService _operationService;
  final StockService _stockService;
  final FarmController _farmController;

  OperationController(
    this._operationService,
    this._stockService,
    this._farmController,
  );

  OperationState _state = OperationInitialState();
  OperationState get state => _state;

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

  void _changeState(OperationState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadOperationsData() async {
    _changeState(OperationLoadingState());
    try {
      // FILTRO MULTI-FAZENDA
      final activeFarmId = _farmController.selectedFarm?.id;
      if (activeFarmId == null) {
        _changeState(OperationErrorState("Nenhuma fazenda ativa selecionada."));
        return;
      }
      final operations = await _operationService.getOperations(activeFarmId);
      _changeState(OperationSuccessState(operations));
    } catch (e) {
      _changeState(OperationErrorState("Erro ao carregar operações."));
    }
  }

  // Máquinas e produtos da fazenda ativa (usados nos formulários e no estoque)
  Future<void> loadFarmResources() async {
    isLoadingResources = true;
    notifyListeners();
    try {
      await _refreshFarmResources();
    } catch (e) {
      debugPrint("Erro ao carregar recursos da fazenda: $e");
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

  List<ProductUsage> _productUsages(OperationModel operation) {
    if (!operation.usedProducts) return const [];
    return operation.appliedProducts
        .map(ProductUsage.fromAppliedProduct)
        .nonNulls
        .toList();
  }

  List<MachineUsage> _machineUsages(OperationModel operation) {
    if (!operation.usedMachine ||
        operation.machineId == null ||
        operation.machineHours == null) {
      return const [];
    }
    return [
      MachineUsage(
        machineId: operation.machineId!,
        hours: operation.machineHours!,
      ),
    ];
  }

  // Monta a operação que será gravada a partir do que veio do formulário
  OperationModel _buildOperation(
    OperationModel form,
    List<Map<String, dynamic>> appliedProductsList, {
    required String farmId,
    required int dateTimestamp,
    required String? createdBy,
    String? id,
    double? initialHorimeter,
    double? finalHorimeter,
  }) {
    return OperationModel(
      id: id,
      title: form.title,
      description: form.description,
      farmId: farmId,
      dateTimestamp: dateTimestamp,
      createdBy: createdBy,
      plotName: form.plotName,
      plotId: _farmController.selectedFarm?.findPlot(name: form.plotName)?.id,
      usedMachine: form.usedMachine,
      machineId: form.machineId,
      machineName: form.machineName,
      machineHours: form.usedMachine
          ? _workedHours(form.machineId, initialHorimeter, finalHorimeter)
          : null,
      implementId: form.usedMachine ? form.implementId : null,
      implementName: form.usedMachine ? form.implementName : null,
      usedProducts: form.usedProducts,
      appliedProducts: appliedProductsList,
    );
  }

  Future<void> saveOperation(
    OperationModel operation,
    List<Map<String, dynamic>> appliedProductsList, {
    double? initialHorimeter,
    double? finalHorimeter,
  }) async {
    _changeState(OperationLoadingState());
    try {
      // VINCULAÇÃO MULTI-FAZENDA
      final activeFarmId = _farmController.selectedFarm?.id;
      if (activeFarmId == null) {
        _changeState(OperationErrorState("Nenhuma fazenda ativa selecionada."));
        return;
      }

      final newOperation = _buildOperation(
        operation,
        appliedProductsList,
        farmId: activeFarmId,
        dateTimestamp: DateTime.now().millisecondsSinceEpoch,
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
      _changeState(OperationErrorState(e.toString()));
    } catch (e) {
      _changeState(OperationErrorState("Erro ao salvar operação."));
    }
  }

  Future<void> updateFullOperation(
    OperationModel oldOp,
    OperationModel newOp,
    List<Map<String, dynamic>> appliedProductsList, {
    double? initialHorimeter,
    double? finalHorimeter,
  }) async {
    _changeState(OperationLoadingState());
    try {
      final activeFarmId = _farmController.selectedFarm?.id;
      if (activeFarmId == null) {
        _changeState(OperationErrorState("Nenhuma fazenda ativa selecionada."));
        return;
      }

      // Estorna sobre o estoque atual do banco
      await _refreshFarmResources();

      final updatedOperation = _buildOperation(
        newOp,
        appliedProductsList,
        id: oldOp.id,
        farmId: activeFarmId,
        dateTimestamp: oldOp.dateTimestamp,
        createdBy: oldOp.createdBy,
        initialHorimeter: initialHorimeter,
        finalHorimeter: finalHorimeter,
      );

      // Devolve o que a operação antiga usou e retira o que a nova usa,
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
      _changeState(OperationErrorState("${e.toString()} (após recálculo)"));
    } catch (e) {
      _changeState(OperationErrorState("Erro ao atualizar operação."));
    }
  }

  Future<void> deleteSingleOperation(OperationModel op) async {
    _changeState(OperationLoadingState());
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
      _changeState(OperationErrorState("Erro ao excluir."));
    }
  }

  Future<void> deleteSelectedOperations(List<String> ids) async {
    _changeState(OperationLoadingState());
    try {
      final activeFarmId = _farmController.selectedFarm?.id;
      if (activeFarmId == null) {
        _changeState(OperationErrorState("Nenhuma fazenda ativa selecionada."));
        return;
      }

      await _refreshFarmResources();
      final selectedIds = ids.toSet();
      final toDelete = (await _operationService.getOperations(
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
      _changeState(OperationErrorState("Erro ao excluir operações em lote."));
    }
  }
}
