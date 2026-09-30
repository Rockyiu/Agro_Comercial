import 'package:agro_comercial/common/data/data_result.dart';
import 'package:agro_comercial/common/models/user_model.dart';

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

  // Sai da conta e apaga o usuário salvo no aparelho
  Future<void> signOut();

  // Aguarda o Firebase restaurar a sessão salva e diz se há usuário logado
  Future<bool> hasActiveSession();

  Future<bool> isCurrentUserCollaborator();

  Future<DataResult<String>> userToken();

  Future<DataResult<bool>> forgotPassword(String email);

  // Valida o código (oobCode) do link de redefinição e devolve o e-mail da conta
  Future<DataResult<String>> verifyPasswordResetCode(String code);

  Future<DataResult<bool>> confirmPasswordReset({
    required String code,
    required String newPassword,
  });
}
