import 'package:agro_comercial/common/data/data_result.dart';
import 'package:agro_comercial/common/models/user_model.dart';
import 'package:agro_comercial/common/models/app_exception.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../cpf_index_service/cpf_index_service.dart';
import '../secure_storage.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._secureStorage, this._cpfIndexService)
    : _auth = FirebaseAuth.instance,
      _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SecureStorageService _secureStorage;
  final CpfIndexService _cpfIndexService;

  @override
  Future<DataResult<UserModel>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // AQUI era onde o Firebase bloqueava e o app travava
        final doc = await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          final user = UserModel(
            id: result.user!.uid,
            name: data['name'] ?? result.user!.displayName,
            email: data['email'] ?? result.user!.email,
            cpf: data['cpf'],
            password: null, // A senha nunca fica guardada no app
            role: data['role'] ?? 'colaborador',
          );
          await _ensureCpfIndexed(user);
          return DataResult.success(user);
        } else {
          return DataResult.success(_createUserModelFromAuthUser(result.user!));
        }
      }

      return DataResult.failure(const GeneralException());
    } on FirebaseAuthException catch (e) {
      // Captura erros de e-mail/senha
      return DataResult.failure(AuthException(code: e.code));
    } catch (e) {
      // Qualquer outro erro (ex: banco de dados) vira erro genérico, para a tela não travar
      return DataResult.failure(const GeneralException());
    }
  }

  @override
  Future<DataResult<UserModel>> signUp({
    String? name,
    required String email,
    required String password,
    required String cpf,
    required String role,
  }) async {
    try {
      // 1. Cria o usuário na aba Authentication (E-mail e Senha)
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user == null) return DataResult.failure(const GeneralException());

      // 2. Um CPF por conta: se ele já for de outra pessoa, desfaz a conta
      // recém-criada
      try {
        await _cpfIndexService.ensureAvailable(cpf: cpf, uid: user.uid);
      } on CpfAlreadyInUseException catch (e) {
        await user.delete();
        return DataResult.failure(BusinessException(e.toString()));
      }

      // 3. Salva o cadastro e reserva o CPF juntos (as regras do Firestore
      // exigem os dois no mesmo lote)
      final batch = _firestore.batch();
      batch.set(_firestore.collection('users').doc(user.uid), {
        'name': name,
        'email': email,
        'cpf': cpf,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _cpfIndexService.addClaimToBatch(
        batch,
        cpf: cpf,
        uid: user.uid,
        role: role,
      );
      await batch.commit();

      // 4. Atualiza o nome no perfil de autenticação
      await user.updateDisplayName(name);

      return DataResult.success(
        UserModel(
          id: user.uid,
          name: name ?? '',
          email: email,
          cpf: cpf,
          password: null, // A senha nunca fica guardada no app
          role: role,
        ),
      );
    } on FirebaseAuthException catch (e) {
      return DataResult.failure(AuthException(code: e.code));
    } catch (e) {
      return DataResult.failure(const GeneralException());
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    // Sem isso o Splash acharia que ainda há alguém logado ao reabrir o app
    await _secureStorage.deleteOne(key: SecureStorageService.currentUserKey);
  }

  @override
  Future<bool> hasActiveSession() async {
    final user = await _auth.authStateChanges().first;
    return user != null;
  }

  @override
  Future<bool> isCurrentUserCollaborator() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final data = (await _firestore.collection('users').doc(user.uid).get())
        .data();
    // 'tipo' é o nome antigo do campo, mantido para cadastros antigos
    return data != null &&
        (data['role'] == 'colaborador' || data['tipo'] == 'colaborador');
  }

  @override
  Future<DataResult<String>> userToken() async {
    try {
      final token = await _auth.currentUser?.getIdToken();
      return DataResult.success(token ?? '');
    } catch (e) {
      return DataResult.success('');
    }
  }

  // Contas criadas antes do índice de CPF: registra o CPF no primeiro login.
  // Não impede o login se falhar (ex: CPF repetido entre contas antigas,
  // que precisa ser resolvido manualmente).
  Future<void> _ensureCpfIndexed(UserModel user) async {
    final cpf = user.cpf ?? '';
    if (user.id == null || CpfIndexService.normalize(cpf).length != 11) return;
    try {
      await _cpfIndexService.claimExisting(
        cpf: cpf,
        uid: user.id!,
        role: user.role ?? 'colaborador',
      );
    } catch (e) {
      debugPrint("CPF da conta ${user.id} não foi indexado: $e");
    }
  }

  UserModel _createUserModelFromAuthUser(User user) {
    return UserModel(
      name: user.displayName,
      email: user.email,
      id: user.uid,
      cpf: null,
      password: null,
      role: 'colaborador',
    );
  }

  @override
  Future<DataResult<bool>> forgotPassword(String email) async {
    try {
      // Envia o e-mail de redefinição em português
      await _auth.setLanguageCode('pt-BR');
      await _auth.sendPasswordResetEmail(email: email.trim());
      return DataResult.success(true);
    } on FirebaseAuthException catch (e) {
      return DataResult.failure(AuthException(code: e.code));
    } catch (e) {
      return DataResult.failure(const GeneralException());
    }
  }

  @override
  Future<DataResult<String>> verifyPasswordResetCode(String code) async {
    try {
      final email = await _auth.verifyPasswordResetCode(code);
      return DataResult.success(email);
    } on FirebaseAuthException catch (e) {
      return DataResult.failure(AuthException(code: e.code));
    } catch (e) {
      return DataResult.failure(const GeneralException());
    }
  }

  @override
  Future<DataResult<bool>> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
      return DataResult.success(true);
    } on FirebaseAuthException catch (e) {
      return DataResult.failure(AuthException(code: e.code));
    } catch (e) {
      return DataResult.failure(const GeneralException());
    }
  }
}
