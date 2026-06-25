import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/user_model.dart';

class EmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserModel>> getEmployees(String managerId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('managerId', isEqualTo: managerId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Garante que o ID do doc seja lido
      return UserModel.fromMap(data);
    }).toList();
  }

  Future<void> inviteEmployee(String name, String cpf, String managerId) async {
    final cleanCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    await _firestore.collection('farm_invites').doc(cleanCpf).set({
      'name': name,
      'cpf': cleanCpf,
      'managerId': managerId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeEmployeeAccess(UserModel employee) async {
    if (employee.id != null) {
      await _firestore.collection('users').doc(employee.id).update({
        'managerId': null,
      });
    }
    if (employee.cpf != null) {
      final cleanCpf = employee.cpf!.replaceAll(RegExp(r'[^0-9]'), '');
      await _firestore.collection('farm_invites').doc(cleanCpf).delete();
    }
  }

  Future<void> removeMultipleEmployees(List<UserModel> employees) async {
    final batch = _firestore.batch();
    for (var emp in employees) {
      if (emp.id != null) {
        batch.update(_firestore.collection('users').doc(emp.id), {
          'managerId': null,
        });
      }
      if (emp.cpf != null) {
        final cleanCpf = emp.cpf!.replaceAll(RegExp(r'[^0-9]'), '');
        batch.delete(_firestore.collection('farm_invites').doc(cleanCpf));
      }
    }
    await batch.commit();
  }
}
