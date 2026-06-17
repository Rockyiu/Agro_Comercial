import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/common/models/user_model.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }

    // Se não existir no banco de dados, gera um temporário com o que tem no Auth
    return UserModel(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      cpf: '',
      password: '',
      role: 'produtor', // role padrão caso não tenha
    );
  }

  Future<void> updateProfile(UserModel profile, {String? newPassword}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    if (profile.name != user.displayName) {
      await user.updateDisplayName(profile.name);
    }

    if (profile.email != user.email) {
      await user.verifyBeforeUpdateEmail(profile.email!);
    }

    if (newPassword != null && newPassword.isNotEmpty) {
      await user.updatePassword(newPassword);
    }

    // Salva na coleção "users" usando o ID do usuário como nome do documento
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }
}
