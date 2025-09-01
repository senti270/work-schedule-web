import 'package:flutter/material.dart';
import '../models/branch.dart';
import '../services/branch_service.dart';
import '../services/auth_service.dart';

class BranchManagementScreen extends StatefulWidget {
  const BranchManagementScreen({super.key});

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  final BranchService _branchService = BranchService();
  final AuthService _authService = AuthService();
  List<Branch> _branches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await _branchService.getBranches();
      setState(() {
        _branches = branches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('지점 목록을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지점 관리'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBranchList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBranchDialog,
        child: const Icon(Icons.add),
        tooltip: '지점 추가',
      ),
    );
  }

  Widget _buildBranchList() {
    if (_branches.isEmpty) {
      return const Center(
        child: Text(
          '등록된 지점이 없습니다.\n새로운 지점을 추가해보세요!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _branches.length,
      itemBuilder: (context, index) {
        final branch = _branches[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                branch.name.substring(0, 1),
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              branch.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('관리자 ID: ${branch.adminId}'),
                Text('생성일: ${_formatDate(branch.createdAt)}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditBranchDialog(branch);
                    break;
                  case 'delete':
                    _showDeleteBranchDialog(branch);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('수정'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('삭제', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddBranchDialog() {
    final nameController = TextEditingController();
    final adminIdController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지점 추가'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '지점명',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: adminIdController,
                decoration: const InputDecoration(
                  labelText: '관리자 ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  adminIdController.text.trim().isEmpty ||
                  passwordController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('모든 필드를 입력해주세요.')),
                );
                return;
              }

              try {
                final branch = Branch(
                  id: '',
                  name: nameController.text.trim(),
                  adminId: adminIdController.text.trim(),
                  password: passwordController.text.trim(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await _branchService.addBranch(branch);
                Navigator.of(context).pop();
                _loadBranches();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('지점이 추가되었습니다.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('지점 추가에 실패했습니다: $e')),
                );
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showEditBranchDialog(Branch branch) {
    final nameController = TextEditingController(text: branch.name);
    final adminIdController = TextEditingController(text: branch.adminId);
    final passwordController = TextEditingController(text: branch.password);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지점 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '지점명',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: adminIdController,
                decoration: const InputDecoration(
                  labelText: '관리자 ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  adminIdController.text.trim().isEmpty ||
                  passwordController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('모든 필드를 입력해주세요.')),
                );
                return;
              }

              try {
                final updatedBranch = branch.copyWith(
                  name: nameController.text.trim(),
                  adminId: adminIdController.text.trim(),
                  password: passwordController.text.trim(),
                  updatedAt: DateTime.now(),
                );

                await _branchService.updateBranch(updatedBranch);
                Navigator.of(context).pop();
                _loadBranches();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('지점이 수정되었습니다.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('지점 수정에 실패했습니다: $e')),
                );
              }
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  void _showDeleteBranchDialog(Branch branch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지점 삭제'),
        content: Text('정말로 "${branch.name}" 지점을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _branchService.deleteBranch(branch.id);
                Navigator.of(context).pop();
                _loadBranches();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('지점이 삭제되었습니다.')),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('지점 삭제에 실패했습니다: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
