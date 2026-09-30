abstract class EditMachineState {}

class EditMachineInitialState extends EditMachineState {}

class EditMachineLoadingState extends EditMachineState {}

class EditMachineSuccessState extends EditMachineState {}

class EditMachineErrorState extends EditMachineState {
  final String message;
  EditMachineErrorState(this.message);
}
