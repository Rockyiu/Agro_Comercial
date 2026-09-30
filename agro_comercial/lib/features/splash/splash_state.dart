abstract class SplashState {}

class SplashStateInitial extends SplashState {}

class AuthenticatedUser extends SplashState {
  final bool isCollaborator;
  AuthenticatedUser({required this.isCollaborator});
}

class UnauthenticatedUser extends SplashState {}
