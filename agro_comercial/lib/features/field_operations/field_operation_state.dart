abstract class FieldOperationState {}

class FieldOperationInitialState extends FieldOperationState {}

class FieldOperationLoadingState extends FieldOperationState {}

class FieldOperationSuccessState extends FieldOperationState {}

class FieldOperationErrorState extends FieldOperationState {
  final String message;
  FieldOperationErrorState(this.message);
}
