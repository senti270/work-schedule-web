import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../models/branch.dart';
import '../models/employee.dart';
import '../services/schedule_service.dart';
import '../services/branch_service.dart';
import '../services/employee_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  final BranchService _branchService = BranchService();
  final EmployeeService _employeeService = EmployeeService();

  List<Branch> _branches = [];
  List<Employee> _employees = [];
  Branch? _selectedBranch;
  Employee? _selectedEmployee;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _reportType = 'employee'; // 'employee' or 'branch'
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final branches = await _branchService.getBranches();
      final employees = await _employeeService.getActiveEmployees();
      
      setState(() {
        _branches = branches;
        _employees = employees;
        _selectedBranch = branches.isNotEmpty ? branches.first : null;
        _selectedEmployee = employees.isNotEmpty ? employees.first : null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _generateReport() async {
    if (_reportType == 'employee' && _selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('직원을 선택해주세요.')),
      );
      return;
    }

    if (_reportType == 'branch' && _selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지점을 선택해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> reportData;
      
      if (_reportType == 'employee') {
        reportData = await _scheduleService.getEmployeeMonthlyReport(
          _selectedEmployee!.id,
          _startDate,
          _endDate,
        );
      } else {
        reportData = await _scheduleService.getBranchMonthlyReport(
          _selectedBranch!.id,
          _startDate,
          _endDate,
        );
      }

      setState(() {
        _reportData = reportData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('리포트 생성에 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('리포트'),
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 리포트 설정 섹션
          _buildReportSettings(),
          
          // 리포트 결과
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildReportResult(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSettings() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '리포트 설정',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // 리포트 유형 선택
            Row(
              children: [
                const Text('리포트 유형: '),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _reportType,
                  items: const [
                    DropdownMenuItem(value: 'employee', child: Text('직원별')),
                    DropdownMenuItem(value: 'branch', child: Text('지점별')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _reportType = value!;
                      _reportData = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 직원/지점 선택
            if (_reportType == 'employee')
              Row(
                children: [
                  const Text('직원: '),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<Employee>(
                      value: _selectedEmployee,
                      isExpanded: true,
                      items: _employees.map((employee) {
                        return DropdownMenuItem(
                          value: employee,
                          child: Text(employee.name),
                        );
                      }).toList(),
                      onChanged: (Employee? employee) {
                        setState(() {
                          _selectedEmployee = employee;
                          _reportData = null;
                        });
                      },
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Text('지점: '),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<Branch>(
                      value: _selectedBranch,
                      isExpanded: true,
                      items: _branches.map((branch) {
                        return DropdownMenuItem(
                          value: branch,
                          child: Text(branch.name),
                        );
                      }).toList(),
                      onChanged: (Branch? branch) {
                        setState(() {
                          _selectedBranch = branch;
                          _reportData = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            
            // 기간 선택
            Row(
              children: [
                const Text('기간: '),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: _endDate,
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                          _reportData = null;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_formatDate(_startDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('~'),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                          _reportData = null;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_formatDate(_endDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 리포트 생성 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generateReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[800],
                  foregroundColor: Colors.white,
                ),
                child: const Text('리포트 생성'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportResult() {
    if (_reportData == null) {
      return const Center(
        child: Text(
          '리포트를 생성해주세요.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 리포트 헤더
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _reportType == 'employee' 
                        ? '${_selectedEmployee!.name} 직원 리포트'
                        : '${_selectedBranch!.name} 지점 리포트',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('기간: ${_formatDate(_startDate)} ~ ${_formatDate(_endDate)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 요약 통계
          _buildSummaryStatistics(),
          const SizedBox(height: 16),
          
          // 상세 스케줄 목록
          _buildScheduleList(),
        ],
      ),
    );
  }

  Widget _buildSummaryStatistics() {
    final data = _reportData!;
    
    if (_reportType == 'employee') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '요약 통계',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildStatRow('총 근무일수', '${data['totalWorkDays']}일'),
              _buildStatRow('총 근무시간', '${data['totalWorkHours'].toStringAsFixed(1)}시간'),
              _buildStatRow('총 휴게시간', '${data['totalBreakHours'].toStringAsFixed(1)}시간'),
              _buildStatRow('일평균 근무시간', '${data['averageWorkHoursPerDay'].toStringAsFixed(1)}시간'),
              _buildStatRow('총 급여', '${data['totalPay'].toStringAsFixed(0)}원'),
            ],
          ),
        ),
      );
    } else {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '요약 통계',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildStatRow('총 근무일수', '${data['totalWorkDays']}일'),
              _buildStatRow('총 근무시간', '${data['totalWorkHours'].toStringAsFixed(1)}시간'),
              _buildStatRow('총 급여', '${data['totalPay'].toStringAsFixed(0)}원'),
              _buildStatRow('근무 직원 수', '${data['uniqueEmployees']}명'),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    final schedules = _reportData!['schedules'] as List<Schedule>;
    
    if (_reportType == 'branch') {
      final employeeStats = _reportData!['employeeStats'] as List<Map<String, dynamic>>;
      
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '직원별 통계',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('직원명')),
                    DataColumn(label: Text('근무일수')),
                    DataColumn(label: Text('총 근무시간')),
                    DataColumn(label: Text('총 급여')),
                  ],
                  rows: employeeStats.map((stat) {
                    return DataRow(
                      cells: [
                        DataCell(Text(stat['employeeName'])),
                        DataCell(Text(stat['workDays'].toString())),
                        DataCell(Text(stat['workHours'].toStringAsFixed(1))),
                        DataCell(Text('${stat['pay'].toStringAsFixed(0)}원')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '근무 스케줄 상세',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  return ListTile(
                    title: Text(_formatDate(schedule.workDate)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_formatTime(schedule.startTime)} ~ ${_formatTime(schedule.endTime)}'),
                        Text('근무시간: ${schedule.workHours.toStringAsFixed(1)}시간, 휴게시간: ${schedule.breakHours.toStringAsFixed(1)}시간'),
                      ],
                    ),
                    trailing: Text(
                      '${schedule.totalPay.toStringAsFixed(0)}원',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
