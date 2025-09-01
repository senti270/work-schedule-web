import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/employee_service.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final EmployeeService _employeeService = EmployeeService();
  List<Employee> _employees = [];
  bool _isLoading = true;
  bool _showOnlyActive = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = _showOnlyActive 
          ? await _employeeService.getActiveEmployees()
          : await _employeeService.getEmployees();
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('직원 목록을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('직원 관리'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          Switch(
            value: _showOnlyActive,
            onChanged: (value) {
              setState(() {
                _showOnlyActive = value;
              });
              _loadEmployees();
            },
          ),
          const Text('활성 직원만', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildEmployeeList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEmployeeDialog,
        child: const Icon(Icons.add),
        tooltip: '직원 추가',
      ),
    );
  }

  Widget _buildEmployeeList() {
    if (_employees.isEmpty) {
      return const Center(
        child: Text(
          '등록된 직원이 없습니다.\n새로운 직원을 추가해보세요!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final employee = _employees[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: employee.isActive ? Colors.green[100] : Colors.grey[100],
              child: Text(
                employee.name.substring(0, 1),
                style: TextStyle(
                  color: employee.isActive ? Colors.green[800] : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  employee.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: employee.type == EmployeeType.employee ? Colors.blue[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    employee.type == EmployeeType.employee ? '정직원' : '알바',
                    style: TextStyle(
                      fontSize: 10,
                      color: employee.type == EmployeeType.employee ? Colors.blue[800] : Colors.orange[800],
                    ),
                  ),
                ),
                if (!employee.isActive)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '퇴사',
                      style: TextStyle(fontSize: 10, color: Colors.red),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('연락처: ${employee.phone}'),
                Text('시급: ${employee.hourlyWage.toStringAsFixed(0)}원'),
                Text('입사일: ${_formatDate(employee.hireDate)}'),
                if (employee.resignDate != null)
                  Text('퇴사일: ${_formatDate(employee.resignDate!)}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditEmployeeDialog(employee);
                    break;
                  case 'delete':
                    _showDeleteEmployeeDialog(employee);
                    break;
                  case 'resign':
                    _showResignEmployeeDialog(employee);
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
                if (employee.isActive)
                  const PopupMenuItem(
                    value: 'resign',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('퇴사 처리', style: TextStyle(color: Colors.orange)),
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

  void _showAddEmployeeDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final residentNumberController = TextEditingController();
    final hourlyWageController = TextEditingController();
    EmployeeType selectedType = EmployeeType.employee;
    DateTime? hireDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('직원 추가'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '이름',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: '연락처',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: residentNumberController,
                  decoration: const InputDecoration(
                    labelText: '주민등록번호',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hourlyWageController,
                  decoration: const InputDecoration(
                    labelText: '시급 (원)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EmployeeType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: '직원 유형',
                    border: OutlineInputBorder(),
                  ),
                  items: EmployeeType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type == EmployeeType.employee ? '정직원' : '알바'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('입사일'),
                  subtitle: Text(hireDate != null ? _formatDate(hireDate) : '선택되지 않음'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: hireDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        hireDate = date;
                      });
                    }
                  },
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
                    phoneController.text.trim().isEmpty ||
                    residentNumberController.text.trim().isEmpty ||
                    hourlyWageController.text.trim().isEmpty ||
                    hireDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모든 필드를 입력해주세요.')),
                  );
                  return;
                }

                try {
                  final hourlyWage = double.parse(hourlyWageController.text.trim());
                  final employee = Employee(
                    id: '',
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    residentNumber: residentNumberController.text.trim(),
                    hourlyWage: hourlyWage,
                    hireDate: hireDate!,
                    type: selectedType,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  await _employeeService.addEmployee(employee);
                  Navigator.of(context).pop();
                  _loadEmployees();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('직원이 추가되었습니다.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('직원 추가에 실패했습니다: $e')),
                  );
                }
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEmployeeDialog(Employee employee) {
    final nameController = TextEditingController(text: employee.name);
    final phoneController = TextEditingController(text: employee.phone);
    final residentNumberController = TextEditingController(text: employee.residentNumber);
    final hourlyWageController = TextEditingController(text: employee.hourlyWage.toString());
    EmployeeType selectedType = employee.type;
    DateTime? hireDate = employee.hireDate;
    DateTime? resignDate = employee.resignDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('직원 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '이름',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: '연락처',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: residentNumberController,
                  decoration: const InputDecoration(
                    labelText: '주민등록번호',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hourlyWageController,
                  decoration: const InputDecoration(
                    labelText: '시급 (원)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EmployeeType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: '직원 유형',
                    border: OutlineInputBorder(),
                  ),
                  items: EmployeeType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type == EmployeeType.employee ? '정직원' : '알바'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('입사일'),
                  subtitle: Text(hireDate != null ? _formatDate(hireDate) : '선택되지 않음'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: hireDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        hireDate = date;
                      });
                    }
                  },
                ),
                if (!employee.isActive)
                  ListTile(
                    title: const Text('퇴사일'),
                    subtitle: Text(resignDate != null ? _formatDate(resignDate) : '선택되지 않음'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: resignDate ?? DateTime.now(),
                        firstDate: hireDate ?? DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          resignDate = date;
                        });
                      }
                    },
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
                    phoneController.text.trim().isEmpty ||
                    residentNumberController.text.trim().isEmpty ||
                    hourlyWageController.text.trim().isEmpty ||
                    hireDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모든 필드를 입력해주세요.')),
                  );
                  return;
                }

                try {
                  final hourlyWage = double.parse(hourlyWageController.text.trim());
                  
                  // 시급이 변경된 경우 이력 추가
                  if (hourlyWage != employee.hourlyWage) {
                    await _employeeService.addWageHistory(employee.id, employee.hourlyWage, hourlyWage);
                  }

                  final updatedEmployee = employee.copyWith(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    residentNumber: residentNumberController.text.trim(),
                    hourlyWage: hourlyWage,
                    hireDate: hireDate!,
                    resignDate: resignDate,
                    type: selectedType,
                    updatedAt: DateTime.now(),
                  );

                  await _employeeService.updateEmployee(updatedEmployee);
                  Navigator.of(context).pop();
                  _loadEmployees();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('직원 정보가 수정되었습니다.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('직원 수정에 실패했습니다: $e')),
                  );
                }
              },
              child: const Text('수정'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResignEmployeeDialog(Employee employee) {
    DateTime? resignDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('퇴사 처리'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${employee.name} 직원의 퇴사를 처리하시겠습니까?'),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('퇴사일'),
                subtitle: Text(resignDate != null ? _formatDate(resignDate) : '선택되지 않음'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: resignDate ?? DateTime.now(),
                    firstDate: employee.hireDate,
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      resignDate = date;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final updatedEmployee = employee.copyWith(
                    resignDate: resignDate,
                    updatedAt: DateTime.now(),
                  );

                  await _employeeService.updateEmployee(updatedEmployee);
                  Navigator.of(context).pop();
                  _loadEmployees();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('퇴사 처리가 완료되었습니다.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('퇴사 처리에 실패했습니다: $e')),
                  );
                }
              },
              child: const Text('퇴사 처리'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteEmployeeDialog(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('직원 삭제'),
        content: Text('정말로 "${employee.name}" 직원을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _employeeService.deleteEmployee(employee.id);
                Navigator.of(context).pop();
                _loadEmployees();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('직원이 삭제되었습니다.')),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('직원 삭제에 실패했습니다: $e')),
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

  String _formatDate(DateTime? date) {
    if (date == null) return '선택되지 않음';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
