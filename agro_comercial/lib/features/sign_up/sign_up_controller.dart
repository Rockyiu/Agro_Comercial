import 'package:agro_comercial/features/sign_up/sing_up_state.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/services/auth_service/auth_service.dart';

class SignUpController extends ChangeNotifier {
  final AuthService _authService;

  SignUpController(this._authService);

  SingUpState _state = SignUpinitialState();
  SingUpState get state => _state;

  void _changeState(SingUpState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String cpf,
    required String password,
    required String role,
  }) async {
    _changeState(SignUpLoadingState());

    try {
      String? managerId;
      String cleanCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

      // 1. Mágica do Vínculo: Verifica se o gerente autorizou este CPF
      if (role == 'colaborador') {
        final inviteDoc = await FirebaseFirestore.instance
            .collection('farm_invites')
            .doc(cleanCpf)
            .get();

        if (!inviteDoc.exists) {
          _changeState(
            SignUpErrorState(
              "CPF não autorizado. Peça ao seu gerente para cadastrar seu CPF no sistema primeiro.",
            ),
          );
          return;
        }
        managerId = inviteDoc.data()?['managerId'];
      }

      // 2. Faz o cadastro original (não mexe no código do seu AuthService!)
      await _authService.signUp(
        name: name,
        email: email,
        cpf: cleanCpf, // Usar o limpo
        password: password,
        role: role,
      );

      // 3. Se for funcionário, salva o vínculo na conta dele
      if (role == 'colaborador' && managerId != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'managerId': managerId});
        }
      }

      _changeState(SignUpSuccessState());
    } catch (e) {
      _changeState(SignUpErrorState(e.toString()));
    }
  }
}
