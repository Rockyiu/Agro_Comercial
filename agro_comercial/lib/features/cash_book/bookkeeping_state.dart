import '../../common/models/bookkeeping_model.dart';

abstract class BookkeepingState {}

class BookkeepingInitialState extends BookkeepingState {}

class BookkeepingLoadingState extends BookkeepingState {}

class BookkeepingSuccessState extends BookkeepingState {
  final List<BookkeepingModel> lancamentos;
  // Ids dos lançamentos com comprovante (PDF) guardado no aparelho
  final Set<String> comprovantes;
  BookkeepingSuccessState(this.lancamentos, [this.comprovantes = const {}]);
}

class BookkeepingErrorState extends BookkeepingState {
  final String message;
  BookkeepingErrorState(this.message);
}
