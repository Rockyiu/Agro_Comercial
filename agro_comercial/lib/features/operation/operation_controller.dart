import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/common/models/operation_model.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/services/operation_service/operation_service.dart';
import 'package:agro_comercial/services/machine_service/machine_service.dart';
import 'package:agro_comercial/services/warehouse_service/warehouse_service.dart';
import 'package:agro_comercial/services/product_service/product_service.dart';
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
      if (user != null) {
        final operations = await _operationService.getOperations(user.uid);
        _state = OperationSuccessState(operations);
      } else {
        _state = OperationErrorState("Usuário não autenticado.");
      }
      notifyListeners();
    } catch (e) {
      _state = OperationErrorState("Erro ao carregar operações.");
      notifyListeners();
    }
  }

  Future<void> loadFarmResources() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      isLoadingResources = true;
      notifyListeners();

      final warehouses = await _warehouseService.getWarehouses(user.uid);
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

  double calculateDuration(TimeOfDay start, TimeOfDay end) {
    double startDouble = start.hour + (start.minute / 60.0);
    double endDouble = end.hour + (end.minute / 60.0);
    return endDouble >= startDouble
        ? endDouble - startDouble
        : (24.0 - startDouble) + endDouble;
  }

  // --- O CORAÇÃO DO ERP: ESTORNO INTELIGENTE ---
  Future<void> _rollbackOperation(OperationModel operation) async {
    // 1. Devolve produtos ao estoque
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

          double currentTotalStock = product.quantity * product.measure;
          double restoredTotalStock =
              currentTotalStock + convertedQty; // SOMA DE VOLTA

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
          if (index != -1)
            products[index] = updatedProduct; // Atualiza memória local
        } catch (e) {
          debugPrint("Produto ignorado no estorno (já deletado).");
        }
      }
    }

    // 2. Subtrai as horas do trator
    if (operation.usedMachine &&
        operation.machineId != null &&
        operation.machineHours != null) {
      try {
        final machine = machines.firstWhere((m) => m.id == operation.machineId);
        if (machine.isMotorized) {
          int newHours = machine.workingHours - operation.machineHours!.round();
          if (newHours < 0) newHours = 0; // Previne horas negativas

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
          if (index != -1)
            machines[index] = updatedMachine; // Atualiza memória local
        }
      } catch (e) {
        debugPrint("Máquina ignorada no estorno (já deletada).");
      }
    }
  }

  Future<void> saveOperation(
    OperationModel operation,
    List<Map<String, dynamic>> appliedProductsList, {
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    _state = OperationLoadingState();
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (operation.usedProducts) {
        for (var appliedProduct in appliedProductsList) {
          final String productId = appliedProduct['productId'];
          final double dosage = appliedProduct['dosage'];
          final String dosageUnit = appliedProduct['dosageUnit'];

          final product = products.firstWhere((p) => p.id == productId);
          double totalStockInProductUnit = product.quantity * product.measure;
          double convertedAppliedQty = convertQuantity(
            dosage,
            dosageUnit,
            product.unit,
          );

          if (totalStockInProductUnit < convertedAppliedQty) {
            _state = OperationErrorState(
              "Estoque insuficiente para: ${product.name}",
            );
            notifyListeners();
            return;
          }

          double newTotalStock = totalStockInProductUnit - convertedAppliedQty;
          final updatedProduct = ProductModel(
            id: product.id,
            name: product.name,
            brand: product.brand,
            quantity: newTotalStock / product.measure,
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

      if (operation.usedMachine &&
          operation.machineId != null &&
          startTime != null &&
          endTime != null) {
        final machine = machines.firstWhere((m) => m.id == operation.machineId);
        if (machine.isMotorized) {
          double duration = calculateDuration(startTime, endTime);
          final updatedMachine = MachineModel(
            id: machine.id,
            name: machine.name,
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
        title: operation.title,
        description: operation.description,
        farmId: user.uid,
        dateTimestamp: DateTime.now().millisecondsSinceEpoch,
        usedMachine: operation.usedMachine,
        machineId: operation.machineId,
        machineName: operation.machineName,
        machineHours: (startTime != null && endTime != null)
            ? calculateDuration(startTime, endTime)
            : null,
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

  // ATUALIZAÇÃO SEGURA: Estorna o antigo e grava o novo por cima
  Future<void> updateFullOperation(
    OperationModel oldOp,
    OperationModel newOp,
    List<Map<String, dynamic>> appliedProductsList, {
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    _state = OperationLoadingState();
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Desfaz a operação antiga (Devolve pro galpão)
      await _rollbackOperation(oldOp);

      // 2. Aplica as regras de estoque e horas na nova configuração
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

          double newTotalStock = totalStockInProductUnit - convertedAppliedQty;
          final updatedProduct = ProductModel(
            id: product.id,
            name: product.name,
            brand: product.brand,
            quantity: newTotalStock / product.measure,
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

      if (newOp.usedMachine &&
          newOp.machineId != null &&
          startTime != null &&
          endTime != null) {
        final machine = machines.firstWhere((m) => m.id == newOp.machineId);
        if (machine.isMotorized) {
          double duration = calculateDuration(startTime, endTime);
          final updatedMachine = MachineModel(
            id: machine.id,
            name: machine.name,
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
        id: oldOp.id, // MANTÉM O MESMO ID PARA ATUALIZAR
        title: newOp.title,
        description: newOp.description,
        farmId: user.uid,
        dateTimestamp: oldOp.dateTimestamp, // MANTÉM A MESMA DATA DE CRIAÇÃO
        usedMachine: newOp.usedMachine,
        machineId: newOp.machineId,
        machineName: newOp.machineName,
        machineHours: (startTime != null && endTime != null)
            ? calculateDuration(startTime, endTime)
            : null,
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
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ops = await _operationService.getOperations(user.uid);
        for (var id in ids) {
          try {
            final op = ops.firstWhere((o) => o.id == id);
            await _rollbackOperation(op);
          } catch (e) {} // Se der erro em um, continua o resto
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
