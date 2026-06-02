import 'package:agro_comercial/common/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/services/services.dart';

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
        // Busca os dados adicionais no banco Firestore para pegar o 'role' e 'cpf'
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
      return DataResult.failure(AuthException(code: e.code));
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
      // Repassa as novas informações pra Cloud Function criar o user completo no Firebase
      await _functions.httpsCallable('registerUser').call({
        "email": email,
        "password": password,
        "displayName": name,
        "cpf": cpf,
        "role": role,
      });

      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        return DataResult.success(
          UserModel(
            id: result.user!.uid,
            name: name ?? result.user!.displayName,
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
    } on FirebaseFunctionsException catch (e) {
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
