import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/branch_service.dart';
import '../models/user_role.dart';
import '../models/branch.dart';
import 'branch_management_screen.dart';
import 'employee_management_screen.dart';
import 'schedule_management_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final BranchService _branchService = BranchService();
  UserRoleModel? _currentUserRole;
  List<Branch> _branches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userRole = await _authService.getCurrentUserRole();
      final branches = await _branchService.getBranches();
      
      setState(() {
        _currentUserRole = userRole;
        _branches = branches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('근무 스케줄 관리 시스템'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          if (_currentUserRole != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'profile':
                    _showUserProfile();
                    break;
                  case 'logout':
                    await _signOut();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person),
                      const SizedBox(width: 8),
                      Text(_currentUserRole!.email),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('로그아웃'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    if (_currentUserRole == null) {
      return const Center(
        child: Text(
          '권한 정보를 불러올 수 없습니다.\n관리자에게 문의하세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '환영합니다!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '이메일: ${_currentUserRole!.email}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    '권한: ${_getRoleDisplayName(_currentUserRole!.role)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (_currentUserRole!.branchName != null)
                    Text(
                      '담당 지점: ${_currentUserRole!.branchName}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 메뉴 그리드
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMenuCard(
                  '지점 관리',
                  Icons.business,
                  Colors.blue,
                  () => _navigateToBranchManagement(),
                  canAccess: _currentUserRole!.canManageAllBranches,
                ),
                _buildMenuCard(
                  '직원 관리',
                  Icons.people,
                  Colors.green,
                  () => _navigateToEmployeeManagement(),
                  canAccess: _currentUserRole!.canEdit,
                ),
                _buildMenuCard(
                  '스케줄 관리',
                  Icons.schedule,
                  Colors.orange,
                  () => _navigateToScheduleManagement(),
                  canAccess: _currentUserRole!.canEdit,
                ),
                _buildMenuCard(
                  '리포트',
                  Icons.assessment,
                  Colors.purple,
                  () => _navigateToReport(),
                  canAccess: true, // 모든 사용자가 볼 수 있음
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(String title, IconData icon, Color color, VoidCallback onTap, {required bool canAccess}) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: canAccess ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: canAccess 
                ? [color.withOpacity(0.8), color]
                : [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.5)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: canAccess ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: canAccess ? Colors.white : Colors.grey[600],
                ),
              ),
              if (!canAccess) ...[
                const SizedBox(height: 8),
                Text(
                  '권한 없음',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.master:
        return '마스터 관리자';
      case UserRole.admin:
        return '지점 관리자';
      case UserRole.viewer:
        return '조회자';
    }
  }

  void _showUserProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 정보'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이메일: ${_currentUserRole!.email}'),
            Text('권한: ${_getRoleDisplayName(_currentUserRole!.role)}'),
            if (_currentUserRole!.branchName != null)
              Text('담당 지점: ${_currentUserRole!.branchName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _navigateToBranchManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BranchManagementScreen(),
      ),
    );
  }

  void _navigateToEmployeeManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmployeeManagementScreen(),
      ),
    );
  }

  void _navigateToScheduleManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ScheduleManagementScreen(),
      ),
    );
  }

  void _navigateToReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ReportScreen(),
      ),
    );
  }
}
