import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/branch.dart';

class BranchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 지점 목록 조회
  Future<List<Branch>> getBranches() async {
    try {
      final snapshot = await _firestore.collection('branches').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Branch.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('지점 목록을 불러오는데 실패했습니다: $e');
    }
  }

  // 지점 추가
  Future<void> addBranch(Branch branch) async {
    try {
      await _firestore.collection('branches').add(branch.toMap());
    } catch (e) {
      throw Exception('지점 추가에 실패했습니다: $e');
    }
  }

  // 지점 수정
  Future<void> updateBranch(Branch branch) async {
    try {
      await _firestore
          .collection('branches')
          .doc(branch.id)
          .update(branch.toMap());
    } catch (e) {
      throw Exception('지점 수정에 실패했습니다: $e');
    }
  }

  // 지점 삭제 (근무 데이터가 있는지 확인 후)
  Future<void> deleteBranch(String branchId) async {
    try {
      // 해당 지점의 근무 데이터 확인
      final scheduleSnapshot = await _firestore
          .collection('schedules')
          .where('branchId', isEqualTo: branchId)
          .limit(1)
          .get();

      if (scheduleSnapshot.docs.isNotEmpty) {
        throw Exception('해당 지점에 근무 데이터가 있어 삭제할 수 없습니다.');
      }

      await _firestore.collection('branches').doc(branchId).delete();
    } catch (e) {
      throw Exception('지점 삭제에 실패했습니다: $e');
    }
  }

  // 지점 ID로 지점 조회
  Future<Branch?> getBranchById(String branchId) async {
    try {
      final doc = await _firestore.collection('branches').doc(branchId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return Branch.fromMap({...data, 'id': doc.id});
      }
      return null;
    } catch (e) {
      throw Exception('지점 조회에 실패했습니다: $e');
    }
  }
}
