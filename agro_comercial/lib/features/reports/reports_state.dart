import 'production_report.dart';

abstract class ReportsState {}

class ReportsInitialState extends ReportsState {}

class ReportsLoadingState extends ReportsState {}

class ReportsSuccessState extends ReportsState {
  final ProductionReport report;
  ReportsSuccessState(this.report);
}

class ReportsErrorState extends ReportsState {
  final String message;
  ReportsErrorState(this.message);
}
