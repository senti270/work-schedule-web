import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_role.dart';
import '../models/branch.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 현재 사용자
  User? get currentUser => _auth.currentUser;

  // 로그인
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('로그인에 실패했습니다: $e');
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('로그아웃에 실패했습니다: $e');
    }
  }

  // 사용자 권한 조회
  Future<UserRoleModel?> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('user_roles').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return UserRoleModel.fromMap({...data, 'id': doc.id});
      }
      return null;
    } catch (e) {
      throw Exception('사용자 권한 조회에 실패했습니다: $e');
    }
  }

  // 지점 관리자 로그인 확인
  Future<bool> verifyBranchAdmin(String branchId, String adminId, String password) async {
    try {
      final branchDoc = await _firestore.collection('branches').doc(branchId).get();
      if (branchDoc.exists) {
        final branchData = branchDoc.data()!;
        return branchData['adminId'] == adminId && branchData['password'] == password;
      }
      return false;
    } catch (e) {
      throw Exception('지점 관리자 확인에 실패했습니다: $e');
    }
  }

  // 사용자 권한 추가
  Future<void> addUserRole(UserRoleModel userRole) async {
    try {
      await _firestore.collection('user_roles').doc(userRole.id).set(userRole.toMap());
    } catch (e) {
      throw Exception('사용자 권한 추가에 실패했습니다: $e');
    }
  }

  // 사용자 권한 수정
  Future<void> updateUserRole(UserRoleModel userRole) async {
    try {
      await _firestore.collection('user_roles').doc(userRole.id).update(userRole.toMap());
    } catch (e) {
      throw Exception('사용자 권한 수정에 실패했습니다: $e');
    }
  }

  // 사용자 권한 삭제
  Future<void> deleteUserRole(String userId) async {
    try {
      await _firestore.collection('user_roles').doc(userId).delete();
    } catch (e) {
      throw Exception('사용자 권한 삭제에 실패했습니다: $e');
    }
  }

  // 모든 사용자 권한 조회 (마스터 관리자용)
  Future<List<UserRoleModel>> getAllUserRoles() async {
    try {
      final snapshot = await _firestore.collection('user_roles').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserRoleModel.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('사용자 권한 목록 조회에 실패했습니다: $e');
    }
  }

  // 현재 사용자의 권한 확인
  Future<UserRoleModel?> getCurrentUserRole() async {
    final user = currentUser;
    if (user != null) {
      return await getUserRole(user.uid);
    }
    return null;
  }

  // 권한 확인 헬퍼 메서드들
  Future<bool> canEdit() async {
    final userRole = await getCurrentUserRole();
    return userRole?.canEdit ?? false;
  }

  Future<bool> canManageAllBranches() async {
    final userRole = await getCurrentUserRole();
    return userRole?.canManageAllBranches ?? false;
  }

  Future<bool> canManageBranch(String branchId) async {
    final userRole = await getCurrentUserRole();
    if (userRole == null) return false;
    
    if (userRole.canManageAllBranches) return true;
    if (userRole.role == UserRole.admin && userRole.branchId == branchId) return true;
    
    return false;
  }
}
