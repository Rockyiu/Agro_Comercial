import 'package:agro_comercial/common/models/field_operation_model.dart';

abstract class FieldOperationState {}

class FieldOperationInitialState extends FieldOperationState {}

class FieldOperationLoadingState extends FieldOperationState {}

class FieldOperationSuccessState extends FieldOperationState {
  final List<FieldOperationModel> operations;
  FieldOperationSuccessState({this.operations = const []});
}

class FieldOperationErrorState extends FieldOperationState {
  final String message;
  FieldOperationErrorState(this.message);
}
