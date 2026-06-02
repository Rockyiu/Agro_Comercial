import 'package:agro_comercial/common/models/user_model.dart';

abstract class AuthService {
  Future<UserModel> signUp({
    String? name,
    required String email,
    required String cpf,
    required String passwword,
  });
  Future<UserModel> signIn({required String email, required String password});
}
