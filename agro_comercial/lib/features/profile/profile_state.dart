import 'package:agro_comercial/common/models/user_model.dart';

abstract class ProfileState {}

class ProfileInitialState extends ProfileState {}

class ProfileLoadingState extends ProfileState {}

class ProfileSuccessState extends ProfileState {
  final UserModel profile;
  ProfileSuccessState(this.profile);
}

class ProfileErrorState extends ProfileState {
  final String message;
  ProfileErrorState(this.message);
}
