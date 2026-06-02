import 'package:agro_comercial/common/models/user_model.dart';

abstract class AuthService {
  Future<DataResult<UserModel>> signUp({
    String? name,
    required String email,
    required String password,
    required String cpf,
    required String role,
  });

  Future<DataResult<UserModel>> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<DataResult<String>> userToken();

  Future<DataResult<bool>> forgotPassword(String email);
}
