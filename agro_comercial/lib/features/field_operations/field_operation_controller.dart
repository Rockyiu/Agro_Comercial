import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/common/models/field_operation_model.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/services/field_operation_service/field_operation_service.dart';
import 'package:agro_comercial/services/machine_service/machine_service.dart';
import 'package:agro_comercial/services/warehouse_service/warehouse_service.dart';
import 'package:agro_comercial/services/product_service/product_service.dart';
import 'field_operation_state.dart';

class FieldOperationController extends ChangeNotifier {
  final FieldOperationService _operationService;
  final MachineService _machineService;
  final WarehouseService _warehouseService;
  final ProductService _productService;

  FieldOperationController(
    this._operationService,
    this._machineService,
    this._warehouseService,
    this._productService,
  );

  FieldOperationState _state = FieldOperationInitialState();
  FieldOperationState get state => _state;

  List<MachineModel> machines = [];
  List<ProductModel> products = [];
  bool isLoadingResources = true;

  Future<void> loadOperationsData() async {
    _state = FieldOperationLoadingState();
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ops = await _operationService.getFieldOperations(user.uid);
        _state = FieldOperationSuccessState(operations: ops);
      } else {
        _state = FieldOperationErrorState("Usuário não autenticado.");
      }
    } catch (e) {
      _state = FieldOperationErrorState("Erro ao carregar operações.");
    }
    notifyListeners();
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
      debugPrint("Erro ao carregar recursos: $e");
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

  Future<void> _rollbackOperation(FieldOperationModel op) async {
    if (op.type == 'Aplicação') {
      if (op.productId != null && op.dosage != null && op.dosageUnit != null) {
        try {
          final product = products.firstWhere((p) => p.id == op.productId);
          double convertedQty = convertQuantity(
            op.dosage!,
            op.dosageUnit!,
            product.unit,
          );
          double restoredTotal =
              (product.quantity * product.measure) + convertedQty;

          final updatedProduct = ProductModel(
            id: product.id,
            name: product.name,
            brand: product.brand,
            quantity: restoredTotal / product.measure,
            measure: product.measure,
            unit: product.unit,
            category: product.category,
            warehouseId: product.warehouseId,
            farmId: product.farmId,
            attributes: product.attributes,
            imageUrl: product.imageUrl,
          );
          await _productService.updateProduct(updatedProduct, null);
          int idx = products.indexWhere((p) => p.id == product.id);
          if (idx != -1) products[idx] = updatedProduct;
        } catch (_) {}
      }
      if (op.machineId != null && op.machineHours != null) {
        try {
          final machine = machines.firstWhere((m) => m.id == op.machineId);
          if (machine.isMotorized) {
            int newHours = machine.workingHours - op.machineHours!.round();
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
            int idx = machines.indexWhere((m) => m.id == machine.id);
            if (idx != -1) machines[idx] = updatedMachine;
          }
        } catch (_) {}
      }
    }
  }

  Future<void> launchOperation(
    FieldOperationModel operation, {
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    _state = FieldOperationLoadingState();
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _state = FieldOperationErrorState("Usuário não logado.");
        notifyListeners();
        return;
      }

      double? calculatedHours;

      if (operation.type == 'Aplicação') {
        if (operation.productId != null &&
            operation.dosage != null &&
            operation.dosageUnit != null) {
          final product = products.firstWhere(
            (p) => p.id == operation.productId,
          );
          double totalStock = product.quantity * product.measure;
          double convertedQty = convertQuantity(
            operation.dosage!,
            operation.dosageUnit!,
            product.unit,
          );

          if (totalStock < convertedQty) {
            _state = FieldOperationErrorState(
              "Estoque insuficiente de ${product.name}.",
            );
            notifyListeners();
            return;
          }
          final updatedProduct = ProductModel(
            id: product.id,
            name: product.name,
            brand: product.brand,
            quantity: (totalStock - convertedQty) / product.measure,
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

        if (operation.machineId != null &&
            startTime != null &&
            endTime != null) {
          final machine = machines.firstWhere(
            (m) => m.id == operation.machineId,
          );
          if (machine.isMotorized) {
            calculatedHours = calculateDuration(startTime, endTime);
            final updatedMachine = MachineModel(
              id: machine.id,
              name: machine.name,
              brand: machine.brand,
              model: machine.model,
              power: machine.power,
              workingHours: machine.workingHours + calculatedHours.round(),
              warehouseId: machine.warehouseId,
              farmId: machine.farmId,
              isMotorized: machine.isMotorized,
              imageUrl: machine.imageUrl,
            );
            await _machineService.updateMachine(updatedMachine, null);
          }
        }
      }

      // CORRIGIDO: Injeta o ID da fazenda e o tempo exato trabalhado
      final completeOp = FieldOperationModel(
        type: operation.type,
        plotName: operation.plotName,
        dateTimestamp: operation.dateTimestamp,
        farmId: user.uid,
        condition: operation.condition,
        observations: operation.observations,
        productId: operation.productId,
        productName: operation.productName,
        dosage: operation.dosage,
        dosageUnit: operation.dosageUnit,
        machineId: operation.machineId,
        machineName: operation.machineName,
        machineHours: calculatedHours,
      );

      await _operationService.saveFieldOperation(completeOp);
      await loadOperationsData();
    } catch (e) {
      _state = FieldOperationErrorState("Erro ao salvar operação.");
      notifyListeners();
    }
  }

  Future<void> updateFullOperation(
    FieldOperationModel oldOp,
    FieldOperationModel newOp, {
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    _state = FieldOperationLoadingState();
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _rollbackOperation(oldOp);

      double? calculatedHours;

      if (newOp.type == 'Aplicação') {
        if (newOp.productId != null &&
            newOp.dosage != null &&
            newOp.dosageUnit != null) {
          final product = products.firstWhere((p) => p.id == newOp.productId);
          double totalStock = product.quantity * product.measure;
          double convertedQty = convertQuantity(
            newOp.dosage!,
            newOp.dosageUnit!,
            product.unit,
          );
          if (totalStock < convertedQty) {
            _state = FieldOperationErrorState(
              "Estoque insuficiente após recálculo.",
            );
            notifyListeners();
            return;
          }
          final updatedProduct = ProductModel(
            id: product.id,
            name: product.name,
            brand: product.brand,
            quantity: (totalStock - convertedQty) / product.measure,
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

        if (newOp.machineId != null && startTime != null && endTime != null) {
          final machine = machines.firstWhere((m) => m.id == newOp.machineId);
          if (machine.isMotorized) {
            calculatedHours = calculateDuration(startTime, endTime);
            final updatedMachine = MachineModel(
              id: machine.id,
              name: machine.name,
              brand: machine.brand,
              model: machine.model,
              power: machine.power,
              workingHours: machine.workingHours + calculatedHours.round(),
              warehouseId: machine.warehouseId,
              farmId: machine.farmId,
              isMotorized: machine.isMotorized,
              imageUrl: machine.imageUrl,
            );
            await _machineService.updateMachine(updatedMachine, null);
          }
        }
      }

      final completeOp = FieldOperationModel(
        id: oldOp.id,
        type: newOp.type,
        plotName: newOp.plotName,
        dateTimestamp: oldOp.dateTimestamp,
        farmId: user.uid,
        condition: newOp.condition,
        observations: newOp.observations,
        productId: newOp.productId,
        productName: newOp.productName,
        dosage: newOp.dosage,
        dosageUnit: newOp.dosageUnit,
        machineId: newOp.machineId,
        machineName: newOp.machineName,
        machineHours: calculatedHours,
      );

      await _operationService.updateFieldOperation(completeOp);
      await loadOperationsData();
    } catch (e) {
      _state = FieldOperationErrorState("Erro ao atualizar operação.");
      notifyListeners();
    }
  }

  Future<void> deleteSingleOperation(FieldOperationModel op) async {
    _state = FieldOperationLoadingState();
    notifyListeners();
    try {
      await _rollbackOperation(op);
      await _operationService.deleteFieldOperation(op.id!);
      await loadOperationsData();
    } catch (e) {
      _state = FieldOperationErrorState("Erro ao excluir.");
      notifyListeners();
    }
  }

  Future<void> deleteSelectedOperations(List<String> ids) async {
    _state = FieldOperationLoadingState();
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ops = await _operationService.getFieldOperations(user.uid);
        for (var id in ids) {
          try {
            final op = ops.firstWhere((o) => o.id == id);
            await _rollbackOperation(op);
          } catch (_) {}
        }
      }
      await _operationService.deleteMultipleFieldOperations(ids);
      await loadOperationsData();
    } catch (e) {
      _state = FieldOperationErrorState("Erro ao excluir em lote.");
      notifyListeners();
    }
  }
}
