abstract class EditWarehouseState {}

class EditWarehouseInitialState extends EditWarehouseState {}

class EditWarehouseLoadingState extends EditWarehouseState {}

class EditWarehouseSuccessState extends EditWarehouseState {}

class EditWarehouseErrorState extends EditWarehouseState {
  final String message;
  EditWarehouseErrorState(this.message);
}
