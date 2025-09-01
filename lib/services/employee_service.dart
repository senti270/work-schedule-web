import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee.dart';

class EmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 직원 목록 조회
  Future<List<Employee>> getEmployees() async {
    try {
      final snapshot = await _firestore.collection('employees').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Employee.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('직원 목록을 불러오는데 실패했습니다: $e');
    }
  }

  // 활성 직원 목록 조회
  Future<List<Employee>> getActiveEmployees() async {
    try {
      final snapshot = await _firestore
          .collection('employees')
          .where('resignDate', isNull: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Employee.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('활성 직원 목록을 불러오는데 실패했습니다: $e');
    }
  }

  // 직원 추가
  Future<void> addEmployee(Employee employee) async {
    try {
      await _firestore.collection('employees').add(employee.toMap());
    } catch (e) {
      throw Exception('직원 추가에 실패했습니다: $e');
    }
  }

  // 직원 수정
  Future<void> updateEmployee(Employee employee) async {
    try {
      await _firestore
          .collection('employees')
          .doc(employee.id)
          .update(employee.toMap());
    } catch (e) {
      throw Exception('직원 수정에 실패했습니다: $e');
    }
  }

  // 직원 삭제
  Future<void> deleteEmployee(String employeeId) async {
    try {
      await _firestore.collection('employees').doc(employeeId).delete();
    } catch (e) {
      throw Exception('직원 삭제에 실패했습니다: $e');
    }
  }

  // 직원 ID로 직원 조회
  Future<Employee?> getEmployeeById(String employeeId) async {
    try {
      final doc = await _firestore.collection('employees').doc(employeeId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return Employee.fromMap({...data, 'id': doc.id});
      }
      return null;
    } catch (e) {
      throw Exception('직원 조회에 실패했습니다: $e');
    }
  }

  // 직원 이름으로 직원 조회
  Future<Employee?> getEmployeeByName(String name) async {
    try {
      final snapshot = await _firestore
          .collection('employees')
          .where('name', isEqualTo: name)
          .where('resignDate', isNull: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return Employee.fromMap({...data, 'id': snapshot.docs.first.id});
      }
      return null;
    } catch (e) {
      throw Exception('직원 조회에 실패했습니다: $e');
    }
  }

  // 시급 변경 이력 추가
  Future<void> addWageHistory(String employeeId, double oldWage, double newWage) async {
    try {
      await _firestore.collection('wage_history').add({
        'employeeId': employeeId,
        'oldWage': oldWage,
        'newWage': newWage,
        'changedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('시급 변경 이력 추가에 실패했습니다: $e');
    }
  }
}
