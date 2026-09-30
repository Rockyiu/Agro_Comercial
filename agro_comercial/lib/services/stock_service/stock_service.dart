import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/common/utils/unit_converter.dart';
import 'package:agro_comercial/services/machine_service/machine_service.dart';
import 'package:agro_comercial/services/product_service/product_service.dart';
import 'package:agro_comercial/services/warehouse_service/warehouse_service.dart';

// Quantidade de um produto usada em uma operação (na unidade escolhida pelo usuário)
class ProductUsage {
  final String productId;
  final double quantity;
  final String unit;

  const ProductUsage({
    required this.productId,
    required this.quantity,
    required this.unit,
  });

  // Formato salvo em OperationModel.appliedProducts
  static ProductUsage? fromAppliedProduct(Map<String, dynamic> map) {
    final productId = map['productId'] as String?;
    final dosage = (map['dosage'] as num?)?.toDouble();
    final unit = map['dosageUnit'] as String?;
    if (productId == null || dosage == null || unit == null) return null;
    return ProductUsage(productId: productId, quantity: dosage, unit: unit);
  }
}

// Horas trabalhadas por uma máquina em uma operação
class MachineUsage {
  final String machineId;
  final double hours;

  const MachineUsage({required this.machineId, required this.hours});
}

class InsufficientStockException implements Exception {
  final String productName;
  const InsufficientStockException(this.productName);

  @override
  String toString() => 'Estoque insuficiente de $productName.';
}

class ProductNotFoundException implements Exception {
  const ProductNotFoundException();

  @override
  String toString() => 'Produto não encontrado no estoque.';
}

// Centraliza a baixa/estorno de produtos e o horímetro das máquinas usados
// pelas operações e pelas vistorias/aplicações.
class StockService {
  final WarehouseService _warehouseService;
  final MachineService _machineService;
  final ProductService _productService;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  StockService(
    this._warehouseService,
    this._machineService,
    this._productService,
  );

  // Máquinas e produtos de todos os armazéns da fazenda (buscados em paralelo)
  Future<({List<MachineModel> machines, List<ProductModel> products})>
  loadFarmResources(String farmId) async {
    final warehouses = await _warehouseService.getWarehouses(farmId);

    final (machinesByWarehouse, productsByWarehouse) = await (
      Future.wait(
        warehouses.map((w) => _machineService.getMachinesByWarehouse(w.id!)),
      ),
      Future.wait(
        warehouses.map((w) => _productService.getProductsByWarehouse(w.id!)),
      ),
    ).wait;

    return (
      machines: machinesByWarehouse.expand((list) => list).toList(),
      products: productsByWarehouse.expand((list) => list).toList(),
    );
  }

  // Aplica no estoque a troca de um consumo antigo por um novo:
  // devolve [restoreProducts]/[restoreMachine] e retira [consumeProducts]/[consumeMachine].
  //
  // - Cadastro: só "consume"
  // - Edição: "restore" (valores antigos) + "consume" (valores novos)
  // - Exclusão: só "restore"
  //
  // Tudo é validado ANTES de gravar e as alterações vão em um único lote
  // (batch), então o estoque nunca fica pela metade: ou tudo é aplicado,
  // ou nada é (ex: falta de estoque de um dos produtos).
  //
  // As listas [products] e [machines] (em memória) também são atualizadas.
  Future<void> applyUsage({
    required List<ProductModel> products,
    required List<MachineModel> machines,
    List<ProductUsage> restoreProducts = const [],
    List<ProductUsage> consumeProducts = const [],
    List<MachineUsage> restoreMachines = const [],
    List<MachineUsage> consumeMachines = const [],
  }) async {
    final updatedProducts = calculateProducts(
      products,
      restore: restoreProducts,
      consume: consumeProducts,
    );
    final updatedMachines = calculateMachines(
      machines,
      restore: restoreMachines,
      consume: consumeMachines,
    );

    if (updatedProducts.isEmpty && updatedMachines.isEmpty) return;

    final batch = _firestore.batch();
    for (final product in updatedProducts) {
      batch.update(_firestore.collection('products').doc(product.id), {
        'quantity': product.quantity,
      });
    }
    for (final machine in updatedMachines) {
      batch.update(_firestore.collection('machines').doc(machine.id), {
        'workingHours': machine.workingHours,
      });
    }
    await batch.commit();

    _replaceById(products, updatedProducts, (p) => p.id);
    _replaceById(machines, updatedMachines, (m) => m.id);
  }

  // Calcula o novo estoque dos produtos envolvidos (sem gravar nada).
  // Lança [InsufficientStockException] se algum produto ficar negativo.
  @visibleForTesting
  static List<ProductModel> calculateProducts(
    List<ProductModel> products, {
    required List<ProductUsage> restore,
    required List<ProductUsage> consume,
  }) {
    // Estoque final de cada produto envolvido (na unidade do produto)
    final newTotals = <String, double>{};
    final byId = {for (final p in products) p.id: p};

    for (final usage in restore) {
      final product = byId[usage.productId];
      if (product == null) {
        // Produto excluído do armazém: não há o que estornar
        debugPrint('Produto ${usage.productId} ignorado no estorno.');
        continue;
      }
      final current = newTotals[product.id!] ?? product.totalStock;
      newTotals[product.id!] =
          current +
          UnitConverter.convert(usage.quantity, usage.unit, product.unit);
    }

    for (final usage in consume) {
      final product = byId[usage.productId];
      if (product == null) throw const ProductNotFoundException();
      final current = newTotals[product.id!] ?? product.totalStock;
      final remaining =
          current -
          UnitConverter.convert(usage.quantity, usage.unit, product.unit);
      // Pequena tolerância para erros de arredondamento de ponto flutuante
      if (remaining < -1e-9) throw InsufficientStockException(product.name);
      newTotals[product.id!] = max(0.0, remaining);
    }

    return [
      for (final entry in newTotals.entries)
        byId[entry.key]!.copyWith(
          quantity: entry.value / byId[entry.key]!.measure,
        ),
    ];
  }

  // Calcula o novo horímetro das máquinas motorizadas (sem gravar nada)
  @visibleForTesting
  static List<MachineModel> calculateMachines(
    List<MachineModel> machines, {
    required List<MachineUsage> restore,
    required List<MachineUsage> consume,
  }) {
    final newHours = <String, int>{};
    final byId = {for (final m in machines) m.id: m};

    // Apenas máquinas motorizadas têm horímetro
    MachineModel? motorized(String id) {
      final machine = byId[id];
      if (machine == null) {
        debugPrint('Máquina $id ignorada na atualização do horímetro.');
        return null;
      }
      return machine.isMotorized ? machine : null;
    }

    for (final usage in restore) {
      final machine = motorized(usage.machineId);
      if (machine == null) continue;
      final current = newHours[machine.id!] ?? machine.workingHours;
      newHours[machine.id!] = max(0, current - usage.hours.round());
    }

    for (final usage in consume) {
      final machine = motorized(usage.machineId);
      if (machine == null) continue;
      final current = newHours[machine.id!] ?? machine.workingHours;
      newHours[machine.id!] = current + usage.hours.round();
    }

    return [
      for (final entry in newHours.entries)
        if (entry.value != byId[entry.key]!.workingHours)
          byId[entry.key]!.copyWith(workingHours: entry.value),
    ];
  }

  void _replaceById<T>(
    List<T> list,
    List<T> updated,
    String? Function(T item) idOf,
  ) {
    for (final item in updated) {
      final index = list.indexWhere((e) => idOf(e) == idOf(item));
      if (index != -1) list[index] = item;
    }
  }
}
