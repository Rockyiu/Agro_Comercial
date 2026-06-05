import 'package:agro_comercial/common/data/data_result.dart';
import 'package:agro_comercial/common/models/user_model.dart';
import 'package:agro_comercial/common/models/app_exception.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService()
    : _auth = FirebaseAuth.instance,
      _functions = FirebaseFunctions.instance,
      _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

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
          return DataResult.success(
            UserModel(
              id: result.user!.uid,
              name: data['name'] ?? result.user!.displayName,
              email: data['email'] ?? result.user!.email,
              cpf: data['cpf'],
              password: password,
              role: data['role'] ?? 'colaborador',
            ),
          );
        } else {
          return DataResult.success(_createUserModelFromAuthUser(result.user!));
        }
      }

      return DataResult.failure(const GeneralException());
    } on FirebaseAuthException catch (e) {
      // Captura erros de e-mail/senha
      return DataResult.failure(AuthException(code: e.code));
    } catch (e) {
      // MUDANÇA AQUI: Captura QUALQUER outro erro (como o do banco de dados) para a tela não travar infinitamente!
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

      if (result.user != null) {
        // 2. Salva os dados extras DIRETAMENTE no Firestore (Banco de Dados)
        await _firestore.collection('users').doc(result.user!.uid).set({
          'name': name,
          'email': email,
          'cpf': cpf,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 3. Atualiza o nome no perfil de autenticação
        await result.user!.updateDisplayName(name);

        return DataResult.success(
          UserModel(
            id: result.user!.uid,
            name: name ?? '',
            email: email,
            cpf: cpf,
            password: password,
            role: role,
          ),
        );
      }

      return DataResult.failure(const GeneralException());
    } on FirebaseAuthException catch (e) {
      return DataResult.failure(AuthException(code: e.code));
    } catch (e) {
      return DataResult.failure(const GeneralException());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
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
      await _auth.sendPasswordResetEmail(email: email);
      return DataResult.success(true);
    } on FirebaseAuthException catch (e) {
      return DataResult.failure(AuthException(code: e.code));
    } catch (e) {
      return DataResult.failure(const GeneralException());
    }
  }
}
