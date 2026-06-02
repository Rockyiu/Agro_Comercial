import 'package:agro_comercial/common/data/data_result.dart';
import 'package:agro_comercial/common/models/user_model.dart';
import 'package:agro_comercial/services/services.dart';

abstract class AuthService {
  Future<DataResult<UserModel>> signUp({
    String? name,
    required String email,
    required String password,
    required String cpf, // Adicionado para o Agro Comercial
    required String role, // Adicionado para identificar Admin vs Colaborador
  });

  Future<DataResult<UserModel>> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<DataResult<String>> userToken();

  Future<DataResult<bool>> forgotPassword(String email);
}
