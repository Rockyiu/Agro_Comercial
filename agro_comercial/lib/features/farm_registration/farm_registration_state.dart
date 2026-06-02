abstract class FarmRegistrationState {}

class FarmRegistrationInitialState extends FarmRegistrationState {}

class FarmRegistrationLoadingState extends FarmRegistrationState {}

class FarmRegistrationSuccessState extends FarmRegistrationState {}

class FarmRegistrationErrorState extends FarmRegistrationState {
  final String message;
  FarmRegistrationErrorState(this.message);
}
