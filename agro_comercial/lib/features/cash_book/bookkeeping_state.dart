import '../../common/models/bookkeeping_model.dart';

abstract class BookkeepingState {}

class BookkeepingInitialState extends BookkeepingState {}

class BookkeepingLoadingState extends BookkeepingState {}

class BookkeepingSuccessState extends BookkeepingState {
  final List<BookkeepingModel> lancamentos;
  BookkeepingSuccessState(this.lancamentos);
}

class BookkeepingErrorState extends BookkeepingState {
  final String message;
  BookkeepingErrorState(this.message);
}
