import 'package:agro_comercial/common/models/user_model.dart';

abstract class EmployeeState {}

class EmployeeInitialState extends EmployeeState {}

class EmployeeLoadingState extends EmployeeState {}

class EmployeeSuccessState extends EmployeeState {
  final List<UserModel> employees;
  EmployeeSuccessState(this.employees);
}

class EmployeeErrorState extends EmployeeState {
  final String message;
  EmployeeErrorState(this.message);
}
