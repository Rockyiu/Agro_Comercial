abstract class RegisterMachineState {}

class RegisterMachineInitialState extends RegisterMachineState {}

class RegisterMachineLoadingState extends RegisterMachineState {}

class RegisterMachineSuccessState extends RegisterMachineState {}

class RegisterMachineErrorState extends RegisterMachineState {
  final String message;
  RegisterMachineErrorState(this.message);
}
