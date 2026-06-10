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

  double _convertQuantity(
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

  double _calculateDuration(TimeOfDay start, TimeOfDay end) {
    double startDouble = start.hour + (start.minute / 60.0);
    double endDouble = end.hour + (end.minute / 60.0);
    return endDouble >= startDouble
        ? endDouble - startDouble
        : (24.0 - startDouble) + endDouble;
  }

  // ATUALIZADO: Agora aceita uma lista completa de produtos aplicados (Mistura de Calda)
  Future<void> launchOperation(
    FieldOperationModel operation,
    List<Map<String, dynamic>> appliedProductsList, {
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    _state = FieldOperationLoadingState();
    notifyListeners();

    try {
      // REGRA 1: PROCESSAMENTO DO ESTOQUE DINÂMICO EM LOTE (1 a 10 produtos)
      for (var appliedProduct in appliedProductsList) {
        final String? productId = appliedProduct['productId'];
        final double? dosage = appliedProduct['dosage'];
        final String? dosageUnit = appliedProduct['dosageUnit'];

        if (productId != null && dosage != null && dosageUnit != null) {
          final product = products.firstWhere((p) => p.id == productId);

          // CAPACIDADE TOTAL DO ESTOQUE = Quantidade de Embalagens × Tamanho da Medida
          double totalStockInProductUnit = product.quantity * product.measure;
          double convertedAppliedQty = _convertQuantity(
            dosage,
            dosageUnit,
            product.unit,
          );

          if (totalStockInProductUnit < convertedAppliedQty) {
            _state = FieldOperationErrorState(
              "Estoque insuficiente para o item: ${product.name}! Disponível: ${(totalStockInProductUnit).toStringAsFixed(1)} ${product.unit}.",
            );
            notifyListeners();
            return;
          }

          // DEDUÇÃO DO SALDO DO ENGENHO
          double newTotalStock = totalStockInProductUnit - convertedAppliedQty;
          double newQuantity =
              newTotalStock /
              product.measure; // Converte de volta para frações de pacotes

          final updatedProduct = ProductModel(
            id: product.id,
            name: product.name,
            brand: product.brand,
            quantity: newQuantity,
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

      // REGRA 2: SOMA DE HORAS DA MÁQUINA
      if (operation.machineId != null && startTime != null && endTime != null) {
        final machine = machines.firstWhere((m) => m.id == operation.machineId);

        if (machine.isMotorized) {
          double duration = _calculateDuration(startTime, endTime);
          int roundedHours = duration.round();

          if (roundedHours > 0) {
            final updatedMachine = MachineModel(
              id: machine.id,
              name: machine.name,
              brand: machine.brand,
              model: machine.model,
              power: machine.power,
              workingHours: machine.workingHours + roundedHours,
              warehouseId: machine.warehouseId,
              farmId: machine.farmId,
              isMotorized: machine.isMotorized,
              imageUrl: machine.imageUrl,
            );
            await _machineService.updateMachine(updatedMachine, null);
          }
        }
      }

      await _operationService.saveFieldOperation(operation);
      _state = FieldOperationSuccessState();
      notifyListeners();
    } catch (e) {
      _state = FieldOperationErrorState("Erro ao salvar operação: $e");
      notifyListeners();
    }
  }
}
