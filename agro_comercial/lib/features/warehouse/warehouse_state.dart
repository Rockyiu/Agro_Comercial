import 'package:agro_comercial/common/models/warehouse_model.dart';

abstract class WarehouseState {}

class WarehouseInitialState extends WarehouseState {}

class WarehouseLoadingState extends WarehouseState {}

class WarehouseSuccessState extends WarehouseState {
  final List<WarehouseModel> warehouses;

  WarehouseSuccessState({required this.warehouses});
}

class WarehouseErrorState extends WarehouseState {
  final String message;
  WarehouseErrorState(this.message);
}
