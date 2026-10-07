import 'package:agro_comercial/common/models/harvest_model.dart';

abstract class HarvestState {}

class HarvestInitialState extends HarvestState {}

class HarvestLoadingState extends HarvestState {}

class HarvestSuccessState extends HarvestState {
  final List<HarvestModel> harvests;
  HarvestSuccessState(this.harvests);
}

class HarvestErrorState extends HarvestState {
  final String message;
  HarvestErrorState(this.message);
}
