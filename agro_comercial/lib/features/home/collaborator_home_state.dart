import 'package:agro_comercial/common/models/field_operation_model.dart';
import 'package:agro_comercial/common/models/operation_model.dart';

abstract class CollaboratorHomeState {}

class CollaboratorHomeInitialState extends CollaboratorHomeState {}

class CollaboratorHomeLoadingState extends CollaboratorHomeState {}

// O colaborador ainda não foi vinculado a nenhuma fazenda pelo produtor
class CollaboratorHomeNoFarmState extends CollaboratorHomeState {}

class CollaboratorHomeSuccessState extends CollaboratorHomeState {
  final List<OperationModel> operations;
  final List<FieldOperationModel> fieldOperations;

  CollaboratorHomeSuccessState({
    required this.operations,
    required this.fieldOperations,
  });

  bool get isEmpty => operations.isEmpty && fieldOperations.isEmpty;
}

class CollaboratorHomeErrorState extends CollaboratorHomeState {
  final String message;
  CollaboratorHomeErrorState(this.message);
}
