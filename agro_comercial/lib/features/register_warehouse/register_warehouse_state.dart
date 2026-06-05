abstract class RegisterWarehouseState {}

class RegisterWarehouseInitialState extends RegisterWarehouseState {}

class RegisterWarehouseLoadingState extends RegisterWarehouseState {}

class RegisterWarehouseSuccessState extends RegisterWarehouseState {}

class RegisterWarehouseErrorState extends RegisterWarehouseState {
  final String message;
  RegisterWarehouseErrorState(this.message);
}
