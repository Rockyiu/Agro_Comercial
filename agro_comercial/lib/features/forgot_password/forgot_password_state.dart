abstract class ForgotPasswordState {}

class ForgotPasswordInitialState extends ForgotPasswordState {}

class ForgotPasswordLoadingState extends ForgotPasswordState {}

class ForgotPasswordSuccessState extends ForgotPasswordState {
  final String email;
  ForgotPasswordSuccessState(this.email);
}

class ForgotPasswordErrorState extends ForgotPasswordState {
  final String message;
  ForgotPasswordErrorState(this.message);
}
