import 'package:agro_comercial/common/models/field_operation_model.dart';
import 'package:agro_comercial/common/models/operation_model.dart';

abstract class HomeState {}

class HomeInitialState extends HomeState {}

class HomeLoadingState extends HomeState {}

class HomeSuccessState extends HomeState {
  final List<OperationModel> operations;
  final List<FieldOperationModel> fieldOperations;
  final String currentUserId;
  final Map<String, String> authorNames; // UID -> nome de quem registrou

  HomeSuccessState({
    required this.operations,
    required this.fieldOperations,
    required this.currentUserId,
    required this.authorNames,
  });

  bool get isEmpty => operations.isEmpty && fieldOperations.isEmpty;

  // Registros sem 'createdBy' foram salvos antes de o app guardar o autor.
  // Nessa época só o produtor conseguia registrar atividades (o colaborador
  // ficava sem fazenda ativa), então eles contam como do produtor.
  String authorName(String? createdBy) {
    if (createdBy == null || createdBy == currentUserId) return 'Você';
    return authorNames[createdBy] ?? 'Colaborador';
  }
}

class HomeErrorState extends HomeState {
  final String message;
  HomeErrorState(this.message);
}
