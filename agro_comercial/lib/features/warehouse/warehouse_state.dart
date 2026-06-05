import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';

abstract class WarehouseState {}

class WarehouseInitialState extends WarehouseState {}

class WarehouseLoadingState extends WarehouseState {}

class WarehouseSuccessState extends WarehouseState {
  final List<WarehouseModel> warehouses;
  final List<MachineModel> machines;
  // Futuramente adicionaremos: final List<ProductModel> products;

  WarehouseSuccessState({required this.warehouses, required this.machines});
}

class WarehouseErrorState extends WarehouseState {
  final String message;
  WarehouseErrorState(this.message);
}
