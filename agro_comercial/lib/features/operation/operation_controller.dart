import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/common/models/operation_model.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/services/operation_service/operation_service.dart';
import 'package:agro_comercial/services/machine_service/machine_service.dart';
import 'package:agro_comercial/services/warehouse_service/warehouse_service.dart';
import 'package:agro_comercial/services/product_service/product_service.dart';
import 'package:agro_comercial/locator.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'operation_state.dart';

class OperationController extends ChangeNotifier {
  final OperationService _operationService;
  final MachineService _machineService;
  final WarehouseService _warehouseService;
  final ProductService _productService;

  OperationController(
    this._operationService,
    this._machineService,
    this._warehouseService,
    this._productService,
  );

  OperationState _state = OperationInitialState();
  OperationState get state => _state;

  List<MachineModel> machines = [];
  List<ProductModel> products = [];
  bool isLoadingResources = true;

  Future<void> loadOperationsData() async {
    _state = OperationLoadingState();
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      // FILTRO MULTI-FAZENDA
      final activeFarmId = locator.get<FarmController>().selectedFarm?.id;

      if (user != null && activeFarmId != null) {
        final operations = await _operationService.getOperations(activeFarmId);
        _state = OperationSuccessState(operations);
      } else {
        _state = OperationErrorState(
          "Usuário não autenticado ou sem fazenda ativa.",
        );
      }
      notifyListeners();
    } catch (e) {
      _state = OperationErrorState("Erro ao carregar operações.");
      notifyListeners();
    }
  }

  Future<void> loadFarmResources() async {
    try {
      // FILTRO MULTI-FAZENDA: Pega os recursos (máquinas e produtos) da fazenda selecionada
      final activeFarmId = locator.get<FarmController>().selectedFarm?.id;
      if (activeFarmId == null) return;

      isLoadingResources = true;
      notifyListeners();

      // Busca os galpões (armazéns) da fazenda atual
      final warehouses = await _warehouseService.getWarehouses(activeFarmId);
      machines.clear();
      products.clear();

      for (var warehouse in warehouses) {
        machines.addAll(
          await _machineService.getMachinesByWarehouse(warehouse.id!),
        );
        products.addAll(
          await _productService.getProductsByWarehouse(warehouse.id!),
        );
      }
    } catch (e) {
      debugPrint("Erro: $e");
    } finally {
      isLoadingResources = false;
      notifyListeners();
    }
  }

  double convertQuantity(
    double appliedQty,
    String usedUnit,
    String productUnit,
  ) {
    if (usedUnit == productUnit) return appliedQty;
    if (productUnit == 'L' && usedUnit == 'ml') return appliedQty / 1000.0;
    if (productUnit == 'ml' && usedUnit == 'L') return appliedQty * 1000.0;
    if (productUnit == 'kg' && usedUnit == 'g') return appliedQty / 1000.0;
    if (productUnit == 'g' && usedUnit == 'kg') return appliedQty * 1000.0;
    if (productUnit == 'L' && usedUnit == 'mg') return appliedQty / 1000000.0;
    if (productUnit == 'kg' && usedUnit == 'mg') return appliedQty / 1000000.0;
    return appliedQty;
  }

  Future<void> _rollbackOperation(OperationModel operation) async {
    if (operation.usedProducts) {
      for (var p in operation.appliedProducts) {
        try {
          final product = products.firstWhere(
            (prod) => prod.id == p['productId'],
          );
          double convertedQty = convertQuantity(
            p['dosage'],
            p['dosageUnit'],
            product.unit,
          );
          double restoredTotalStock =
              (product.quantity * product.measure) + convertedQty;

          final updatedProduct = ProductModel(
            id: product.id,
            name: product.name,
            brand: product.brand,
            quantity: restoredTotalStock / product.measure,
            measure: product.measure,
            unit: product.unit,
            category: product.category,
            warehouseId: product.warehouseId,
            farmId: product.farmId,
            attributes: product.attributes,
            imageUrl: product.imageUrl,
          );
          await _productService.updateProduct(updatedProduct, null);

          int index = products.indexWhere((prod) => prod.id == product.id);
          if (index != -1) products[index] = updatedProduct;
        } catch (e) {
          debugPrint("Produto ignorado no estorno.");
        }
      }
    }

    if (operation.usedMachine &&
        operation.machineId != null &&
        operation.machineHours != null) {
      try {
        final machine = machines.firstWhere((m) => m.id == operation.machineId);
        if (machine.isMotorized) {
          int newHours = machine.workingHours - operation.machineHours!.round();
          if (newHours < 0) newHours = 0;

          final updatedMachine = MachineModel(
            id: machine.id,
            name: machine.name,
            brand: machine.brand,
            model: machine.model,
            power: machine.power,
            workingHours: newHours,
            warehouseId: machine.warehouseId,
            farmId: machine.farmId,
            isMotorized: machine.isMotorized,
            imageUrl: machine.imageUrl,
          );
          await _machineService.updateMachine(updatedMachine, null);

          int index = machines.indexWhere((m) => m.id == machine.id);
          if (index != -1) machines[index] = updatedMachine;
        }
      } catch (e) {
        debugPrint("Máquina ignorada no estorno.");
      }
    }
  }

  Future<void> saveOperation(
    OperationModel operation,
    List<Map<String, dynamic>> appliedProductsList, {
    double? initialHorimeter,
    double? finalHorimeter,
  }) async {
    _state = OperationLoadingState();
    notifyListeners();
    try {
      // VINCULAÇÃO MULTI-FAZENDA
      final activeFarmId = locator.get<FarmController>().selectedFarm?.id;
      if (activeFarmId == null) return;

      if (operation.usedProducts) {
        for (var appliedProduct in appliedProductsList) {
          final product = products.firstWhere(
            (p) => p.id == appliedProduct['productId'],
          );
          double totalStockInProductUnit = product.quantity * product.measure;
          double convertedAppliedQty = convertQuantity(
            appliedProduct['dosage'],
            appliedProduct['dosageUnit'],
            product.unit,
          );

          if (totalStockInProductUnit < convertedAppliedQty) {
            _state = OperationErrorState(
              "Estoque insuficiente para: ${product.name}",
            );
            notifyListeners();
            return;
          }

          final updatedProduct = ProductModel(
            id: product.id,
            name: product.name,
            brand: product.brand,
            quantity:
                (totalStockInProductUnit - convertedAppliedQty) /
                product.measure,
            measure: product.measure,
            unit: product.unit,
            category: product.category,
            warehouseId: product.warehouseId,
            farmId: product.farmId,
            attributes: product.attributes,
            imageUrl: product.imageUrl,
          );
          await _productService.updateProduct(updatedProduct, null);
        }
      }

      double? duration;
      if (operation.usedMachine &&
          operation.machineId != null &&
          initialHorimeter != null &&
          finalHorimeter != null) {
        final machine = machines.firstWhere((m) => m.id == operation.machineId);
        if (machine.isMotorized) {
          duration = finalHorimeter - initialHorimeter;
          final updatedMachine = MachineModel(
            id: machine.id,
            name: operation.machineName ?? 'Máquina',
            brand: machine.brand,
            model: machine.model,
            power: machine.power,
            workingHours: machine.workingHours + duration.round(),
            warehouseId: machine.warehouseId,
            farmId: machine.farmId,
            isMotorized: machine.isMotorized,
            imageUrl: machine.imageUrl,
          );
          await _machineService.updateMachine(updatedMachine, null);
        }
      }

      // Salva a operação contendo o ID da fazenda ativa
      final completeOperation = OperationModel(
        title: operation.title,
        description: operation.description,
        farmId: activeFarmId, // <- AQUI O ISOLAMENTO OCORRE
        dateTimestamp: DateTime.now().millisecondsSinceEpoch,
        usedMachine: operation.usedMachine,
        machineId: operation.machineId,
        machineName: operation.machineName,
        machineHours: duration,
        usedProducts: operation.usedProducts,
        appliedProducts: appliedProductsList,
      );

      await _operationService.createOperation(completeOperation);
      await loadOperationsData();
    } catch (e) {
      _state = OperationErrorState("Erro ao salvar operação.");
      notifyListeners();
    }
  }

  Future<void> updateFullOperation(
    OperationModel oldOp,
    OperationModel newOp,
    List<Map<String, dynamic>> appliedProductsList, {
    double? initialHorimeter,
    double? finalHorimeter,
  }) async {
    _state = OperationLoadingState();
    notifyListeners();
    try {
      final activeFarmId = locator.get<FarmController>().selectedFarm?.id;
      if (activeFarmId == null) return;

      // ADICIONADO: Baixa o estoque atual antes de estornar
      await loadFarmResources();
      await _rollbackOperation(oldOp);

      if (newOp.usedProducts) {
        for (var appliedProduct in appliedProductsList) {
          final product = products.firstWhere(
            (p) => p.id == appliedProduct['productId'],
          );
          double totalStockInProductUnit = product.quantity * product.measure;
          double convertedAppliedQty = convertQuantity(
            appliedProduct['dosage'],
            appliedProduct['dosageUnit'],
            product.unit,
          );

          if (totalStockInProductUnit < convertedAppliedQty) {
            _state = OperationErrorState(
              "Estoque insuficiente para: ${product.name} após recálculo.",
            );
            notifyListeners();
            return;
          }

          final updatedProduct = ProductModel(
            id: product.id,
            name: product.name,
            brand: product.brand,
            quantity:
                (totalStockInProductUnit - convertedAppliedQty) /
                product.measure,
            measure: product.measure,
            unit: product.unit,
            category: product.category,
            warehouseId: product.warehouseId,
            farmId: product.farmId,
            attributes: product.attributes,
            imageUrl: product.imageUrl,
          );
          await _productService.updateProduct(updatedProduct, null);
        }
      }

      double? duration;
      if (newOp.usedMachine &&
          newOp.machineId != null &&
          initialHorimeter != null &&
          finalHorimeter != null) {
        final machine = machines.firstWhere((m) => m.id == newOp.machineId);
        if (machine.isMotorized) {
          duration = finalHorimeter - initialHorimeter;
          final updatedMachine = MachineModel(
            id: machine.id,
            name: newOp.machineName ?? 'Máquina',
            brand: machine.brand,
            model: machine.model,
            power: machine.power,
            workingHours: machine.workingHours + duration.round(),
            warehouseId: machine.warehouseId,
            farmId: machine.farmId,
            isMotorized: machine.isMotorized,
            imageUrl: machine.imageUrl,
          );
          await _machineService.updateMachine(updatedMachine, null);
        }
      }

      final completeOperation = OperationModel(
        id: oldOp.id,
        title: newOp.title,
        description: newOp.description,
        farmId: activeFarmId,
        dateTimestamp: oldOp.dateTimestamp,
        usedMachine: newOp.usedMachine,
        machineId: newOp.machineId,
        machineName: newOp.machineName,
        machineHours: duration,
        usedProducts: newOp.usedProducts,
        appliedProducts: appliedProductsList,
      );

      await _operationService.updateOperation(completeOperation);
      await loadOperationsData();
    } catch (e) {
      _state = OperationErrorState("Erro ao atualizar operação.");
      notifyListeners();
    }
  }

  Future<void> deleteSingleOperation(OperationModel op) async {
    _state = OperationLoadingState();
    notifyListeners();
    try {
      // ADICIONADO: Baixa o estoque atual antes de estornar
      await loadFarmResources();
      await _rollbackOperation(op);
      await _operationService.deleteOperation(op.id!);
      await loadOperationsData();
    } catch (e) {
      _state = OperationErrorState("Erro ao excluir.");
      notifyListeners();
    }
  }

  Future<void> deleteSelectedOperations(List<String> ids) async {
    _state = OperationLoadingState();
    notifyListeners();
    try {
      // ADICIONADO: Baixa o estoque atual antes de estornar
      await loadFarmResources();
      final activeId = locator.get<FarmController>().selectedFarm?.id;
      if (activeId != null) {
        final ops = await _operationService.getOperations(activeId);
        for (var id in ids) {
          try {
            final op = ops.firstWhere((o) => o.id == id);
            await _rollbackOperation(op);
          } catch (e) {}
        }
      }
      await _operationService.deleteMultipleOperations(ids);
      await loadOperationsData();
    } catch (e) {
      _state = OperationErrorState("Erro ao excluir operações em lote.");
      notifyListeners();
    }
  }
}
