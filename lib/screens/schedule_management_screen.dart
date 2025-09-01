import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../models/branch.dart';
import '../models/employee.dart';
import '../services/schedule_service.dart';
import '../services/branch_service.dart';
import '../services/employee_service.dart';
import '../services/auth_service.dart';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  final BranchService _branchService = BranchService();
  final EmployeeService _employeeService = EmployeeService();
  final AuthService _authService = AuthService();

  List<Branch> _branches = [];
  List<Employee> _employees = [];
  Branch? _selectedBranch;
  DateTime _selectedWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  List<Schedule> _weeklySchedules = [];
  List<WeeklySchedule> _recentWeeklySchedules = [];
  bool _isLoading = true;

  // 주간 스케줄 입력을 위한 컨트롤러들
  final List<List<TextEditingController>> _scheduleControllers = List.generate(
    7,
    (dayIndex) => List.generate(5, (employeeIndex) => TextEditingController()),
  );

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    for (var dayControllers in _scheduleControllers) {
      for (var controller in dayControllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final branches = await _branchService.getBranches();
      final employees = await _employeeService.getActiveEmployees();
      
      setState(() {
        _branches = branches;
        _employees = employees;
        _selectedBranch = branches.isNotEmpty ? branches.first : null;
        _isLoading = false;
      });

      if (_selectedBranch != null) {
        await _loadWeeklySchedules();
        await _loadRecentWeeklySchedules();
      }
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

  Future<void> _loadWeeklySchedules() async {
    if (_selectedBranch == null) return;

    try {
      final schedules = await _scheduleService.getWeeklySchedules(
        _selectedBranch!.id,
        _selectedWeekStart,
      );
      setState(() {
        _weeklySchedules = schedules;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('주간 스케줄 로드 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _loadRecentWeeklySchedules() async {
    if (_selectedBranch == null) return;

    try {
      final weeklySchedules = await _scheduleService.getRecentWeeklySchedules(_selectedBranch!.id);
      setState(() {
        _recentWeeklySchedules = weeklySchedules;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('최근 스케줄 로드 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스케줄 관리'),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveWeeklySchedule,
            tooltip: '주간 스케줄 저장',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildScheduleContent(),
    );
  }

  Widget _buildScheduleContent() {
    return Column(
      children: [
        // 지점 선택 및 주간 네비게이션
        _buildHeaderSection(),
        
        // 주간 스케줄 그리드
        Expanded(
          child: _buildScheduleGrid(),
        ),
        
        // 요약 테이블
        _buildSummaryTable(),
        
        // 최근 10주 스케줄
        _buildRecentSchedules(),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 지점 선택
            Row(
              children: [
                const Text('지점: ', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      });
                      if (branch != null) {
                        _loadWeeklySchedules();
                        _loadRecentWeeklySchedules();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 주간 네비게이션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
                    });
                    _loadWeeklySchedules();
                  },
                ),
                Text(
                  '${_formatDate(_selectedWeekStart)} ~ ${_formatDate(_selectedWeekStart.add(const Duration(days: 6)))}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
                    });
                    _loadWeeklySchedules();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleGrid() {
    if (_selectedBranch == null) {
      return const Center(
        child: Text('지점을 선택해주세요.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 헤더 행
          Row(
            children: [
              const SizedBox(width: 100), // 직원 이름 공간
              ...List.generate(7, (dayIndex) {
                final date = _selectedWeekStart.add(Duration(days: dayIndex));
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      color: Colors.grey[100],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getDayName(dayIndex),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${date.month}/${date.day}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          
          // 직원별 스케줄 입력 행
          ...List.generate(_employees.length, (employeeIndex) {
            final employee = _employees[employeeIndex];
            return Row(
              children: [
                // 직원 이름
                Container(
                  width: 100,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    color: Colors.blue[50],
                  ),
                  child: Text(
                    employee.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // 각 요일별 스케줄 입력
                ...List.generate(7, (dayIndex) {
                  final date = _selectedWeekStart.add(Duration(days: dayIndex));
                  final existingSchedule = _weeklySchedules.firstWhere(
                    (schedule) => schedule.employeeId == employee.id && 
                                 schedule.workDate.day == date.day,
                    orElse: () => Schedule(
                      id: '',
                      employeeId: employee.id,
                      employeeName: employee.name,
                      workDate: date,
                      startTime: date,
                      endTime: date,
                      workHours: 0,
                      breakHours: 0,
                      branchId: _selectedBranch!.id,
                      branchName: _selectedBranch!.name,
                      hourlyWage: employee.hourlyWage,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );

                  return Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: _scheduleControllers[dayIndex][employeeIndex],
                        decoration: InputDecoration(
                          hintText: '예: 9.5-17(0.5)',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(4),
                        ),
                        style: const TextStyle(fontSize: 12),
                        onChanged: (value) {
                          _updateScheduleSummary();
                        },
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryTable() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '주간 요약',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // 요약 테이블
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('직원명')),
                  ...List.generate(7, (dayIndex) {
                    final date = _selectedWeekStart.add(Duration(days: dayIndex));
                    return DataColumn(label: Text('${date.month}/${date.day}'));
                  }),
                  const DataColumn(label: Text('총 근무시간')),
                  const DataColumn(label: Text('총 급여')),
                ],
                rows: _employees.map((employee) {
                  final employeeSchedules = _weeklySchedules
                      .where((schedule) => schedule.employeeId == employee.id)
                      .toList();
                  
                  double totalWorkHours = 0;
                  double totalPay = 0;
                  
                  final dayData = List.generate(7, (dayIndex) {
                    final date = _selectedWeekStart.add(Duration(days: dayIndex));
                    final schedule = employeeSchedules.firstWhere(
                      (s) => s.workDate.day == date.day,
                      orElse: () => Schedule(
                        id: '',
                        employeeId: employee.id,
                        employeeName: employee.name,
                        workDate: date,
                        startTime: date,
                        endTime: date,
                        workHours: 0,
                        breakHours: 0,
                        branchId: _selectedBranch!.id,
                        branchName: _selectedBranch!.name,
                        hourlyWage: employee.hourlyWage,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );
                    
                    totalWorkHours += schedule.workHours;
                    totalPay += schedule.totalPay;
                    
                    return DataCell(Text(schedule.workHours > 0 ? schedule.workHours.toStringAsFixed(1) : ''));
                  });
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(employee.name)),
                      ...dayData,
                      DataCell(Text(totalWorkHours.toStringAsFixed(1))),
                      DataCell(Text('${totalPay.toStringAsFixed(0)}원')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSchedules() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '최근 10주 스케줄',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (_recentWeeklySchedules.isEmpty)
              const Text('최근 스케줄이 없습니다.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentWeeklySchedules.length,
                itemBuilder: (context, index) {
                  final weeklySchedule = _recentWeeklySchedules[index];
                  return ListTile(
                    title: Text('${_formatDate(weeklySchedule.weekStartDate)} ~ ${_formatDate(weeklySchedule.weekStartDate.add(const Duration(days: 6)))}'),
                    subtitle: Text('${weeklySchedule.schedules.length}개 스케줄'),
                    trailing: Text('${_formatDate(weeklySchedule.createdAt)}'),
                    onTap: () {
                      _loadWeeklySchedule(weeklySchedule);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _updateScheduleSummary() {
    // 실시간으로 요약 테이블 업데이트
    setState(() {
      // 여기서 입력된 데이터를 파싱하여 요약 정보를 업데이트
    });
  }

  Future<void> _saveWeeklySchedule() async {
    if (_selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지점을 선택해주세요.')),
      );
      return;
    }

    try {
      final List<Schedule> schedules = [];
      
      // 입력된 스케줄 데이터 파싱
      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        final date = _selectedWeekStart.add(Duration(days: dayIndex));
        
        for (int employeeIndex = 0; employeeIndex < _employees.length; employeeIndex++) {
          final employee = _employees[employeeIndex];
          final scheduleText = _scheduleControllers[dayIndex][employeeIndex].text.trim();
          
          if (scheduleText.isNotEmpty) {
            try {
              final schedule = await _scheduleService.parseScheduleText(
                scheduleText,
                _selectedBranch!.id,
                date,
              );
              
              if (schedule != null) {
                schedules.add(schedule);
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${employee.name}의 ${_getDayName(dayIndex)} 스케줄 오류: $e')),
              );
              return;
            }
          }
        }
      }

      // 스케줄 저장
      for (final schedule in schedules) {
        await _scheduleService.addSchedule(schedule);
      }

      // 주간 스케줄 저장
      final weeklySchedule = WeeklySchedule(
        id: '',
        branchId: _selectedBranch!.id,
        branchName: _selectedBranch!.name,
        weekStartDate: _selectedWeekStart,
        schedules: schedules,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _scheduleService.addWeeklySchedule(weeklySchedule);

      // 데이터 새로고침
      await _loadWeeklySchedules();
      await _loadRecentWeeklySchedules();

      // 입력 필드 초기화
      for (var dayControllers in _scheduleControllers) {
        for (var controller in dayControllers) {
          controller.clear();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주간 스케줄이 저장되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('스케줄 저장에 실패했습니다: $e')),
      );
    }
  }

  void _loadWeeklySchedule(WeeklySchedule weeklySchedule) {
    setState(() {
      _selectedWeekStart = weeklySchedule.weekStartDate;
      _weeklySchedules = weeklySchedule.schedules;
    });
    
    // 입력 필드에 기존 스케줄 데이터 표시
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final date = _selectedWeekStart.add(Duration(days: dayIndex));
      
      for (int employeeIndex = 0; employeeIndex < _employees.length; employeeIndex++) {
        final employee = _employees[employeeIndex];
        final schedule = weeklySchedule.schedules.firstWhere(
          (s) => s.employeeId == employee.id && s.workDate.day == date.day,
          orElse: () => Schedule(
            id: '',
            employeeId: employee.id,
            employeeName: employee.name,
            workDate: date,
            startTime: date,
            endTime: date,
            workHours: 0,
            breakHours: 0,
            branchId: _selectedBranch!.id,
            branchName: _selectedBranch!.name,
            hourlyWage: employee.hourlyWage,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        
        if (schedule.workHours > 0) {
          final startHour = schedule.startTime.hour + schedule.startTime.minute / 60.0;
          final endHour = schedule.endTime.hour + schedule.endTime.minute / 60.0;
          final breakText = schedule.breakHours > 0 ? '(${schedule.breakHours})' : '';
          _scheduleControllers[dayIndex][employeeIndex].text = 
              '${employee.name} ${startHour.toStringAsFixed(1)}-${endHour.toStringAsFixed(1)}$breakText';
        } else {
          _scheduleControllers[dayIndex][employeeIndex].clear();
        }
      }
    }
  }

  String _getDayName(int dayIndex) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[dayIndex];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
