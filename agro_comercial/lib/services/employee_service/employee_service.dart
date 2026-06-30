import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/user_model.dart';

class EmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Busca apenas os colaboradores vinculados a esta FAZENDA
  Future<List<UserModel>> getEmployees(String farmId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('farmId', isEqualTo: farmId)
        .where('role', isEqualTo: 'colaborador')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return UserModel.fromMap(data);
    }).toList();
  }

  // 2. Vincula um colaborador existente à FAZENDA através do CPF
  Future<void> inviteEmployee(String name, String cpf, String farmId) async {
    String cleanCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    // Procura se o colaborador já se cadastrou no aplicativo
    final query = await _firestore
        .collection('users')
        .where('cpf', isEqualTo: cleanCpf)
        .where('role', isEqualTo: 'colaborador')
        .get();

    if (query.docs.isEmpty) {
      throw Exception(
        "Nenhum colaborador encontrado com este CPF. Peça para ele criar uma conta no app primeiro.",
      );
    }

    // Pega o documento do colaborador encontrado e adiciona a ele o ID da Fazenda
    final collaboratorDoc = query.docs.first;

    await _firestore.collection('users').doc(collaboratorDoc.id).update({
      'farmId': farmId,
    });
  }

  // 3. Remove o acesso (desvincula da fazenda)
  Future<void> removeEmployeeAccess(UserModel employee) async {
    if (employee.id != null) {
      await _firestore.collection('users').doc(employee.id).update({
        'farmId': FieldValue.delete(),
      });
    }
  }

  // 4. Exclui vários colaboradores da fazenda de uma vez
  Future<void> removeMultipleEmployees(List<UserModel> employees) async {
    final batch = _firestore.batch();
    for (var emp in employees) {
      if (emp.id != null) {
        final docRef = _firestore.collection('users').doc(emp.id);
        batch.update(docRef, {'farmId': FieldValue.delete()});
      }
    }
    await batch.commit();
  }
}
