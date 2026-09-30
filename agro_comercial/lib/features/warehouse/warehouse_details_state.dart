import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';

abstract class WarehouseDetailsState {}

class WarehouseDetailsInitialState extends WarehouseDetailsState {}

class WarehouseDetailsLoadingState extends WarehouseDetailsState {}

class WarehouseDetailsSuccessState extends WarehouseDetailsState {
  final List<MachineModel> machines;
  final List<ProductModel> products; // Adicionado à resposta de sucesso
  WarehouseDetailsSuccessState(this.machines, this.products);
}

class WarehouseDetailsErrorState extends WarehouseDetailsState {
  final String message;
  WarehouseDetailsErrorState(this.message);
}
