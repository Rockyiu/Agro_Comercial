import 'package:agro_comercial/common/models/cost_model.dart';

abstract class CostState {}

class CostInitialState extends CostState {}

class CostLoadingState extends CostState {}

class CostSuccessState extends CostState {
  final List<CostModel> costs;
  CostSuccessState(this.costs);
}

class CostErrorState extends CostState {
  final String message;
  CostErrorState(this.message);
}
