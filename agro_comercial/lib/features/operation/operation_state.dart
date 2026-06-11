import 'package:agro_comercial/common/models/operation_model.dart';

abstract class OperationState {}

class OperationInitialState extends OperationState {}

class OperationLoadingState extends OperationState {}

class OperationSuccessState extends OperationState {
  final List<OperationModel> operations;
  OperationSuccessState(this.operations);
}

class OperationErrorState extends OperationState {
  final String message;
  OperationErrorState(this.message);
}
