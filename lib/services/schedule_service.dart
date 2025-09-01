import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule.dart';
import '../models/employee.dart';
import '../models/branch.dart';
import 'employee_service.dart';
import 'branch_service.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EmployeeService _employeeService = EmployeeService();
  final BranchService _branchService = BranchService();

  // 주간 스케줄 조회
  Future<List<Schedule>> getWeeklySchedules(String branchId, DateTime weekStart) async {
    try {
      final weekEnd = weekStart.add(const Duration(days: 6));
      final snapshot = await _firestore
          .collection('schedules')
          .where('branchId', isEqualTo: branchId)
          .where('workDate', isGreaterThanOrEqualTo: weekStart)
          .where('workDate', isLessThanOrEqualTo: weekEnd)
          .orderBy('workDate')
          .orderBy('startTime')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Schedule.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('주간 스케줄을 불러오는데 실패했습니다: $e');
    }
  }

  // 최근 10주 스케줄 조회
  Future<List<WeeklySchedule>> getRecentWeeklySchedules(String branchId) async {
    try {
      final tenWeeksAgo = DateTime.now().subtract(const Duration(days: 70));
      final snapshot = await _firestore
          .collection('weekly_schedules')
          .where('branchId', isEqualTo: branchId)
          .where('weekStartDate', isGreaterThanOrEqualTo: tenWeeksAgo)
          .orderBy('weekStartDate', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return WeeklySchedule.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('최근 스케줄을 불러오는데 실패했습니다: $e');
    }
  }

  // 스케줄 추가
  Future<void> addSchedule(Schedule schedule) async {
    try {
      await _firestore.collection('schedules').add(schedule.toMap());
    } catch (e) {
      throw Exception('스케줄 추가에 실패했습니다: $e');
    }
  }

  // 주간 스케줄 추가
  Future<void> addWeeklySchedule(WeeklySchedule weeklySchedule) async {
    try {
      await _firestore.collection('weekly_schedules').add(weeklySchedule.toMap());
    } catch (e) {
      throw Exception('주간 스케줄 추가에 실패했습니다: $e');
    }
  }

  // 스케줄 수정
  Future<void> updateSchedule(Schedule schedule) async {
    try {
      await _firestore
          .collection('schedules')
          .doc(schedule.id)
          .update(schedule.toMap());
    } catch (e) {
      throw Exception('스케줄 수정에 실패했습니다: $e');
    }
  }

  // 스케줄 삭제
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _firestore.collection('schedules').doc(scheduleId).delete();
    } catch (e) {
      throw Exception('스케줄 삭제에 실패했습니다: $e');
    }
  }

  // 스케줄 텍스트 파싱 및 검증
  Future<Schedule?> parseScheduleText(String text, String branchId, DateTime workDate) async {
    try {
      // 예시: "유진 9.5-17(0.5)"
      final regex = RegExp(r'^(\S+)\s+(\d+\.?\d*)-(\d+\.?\d*)(?:\((\d+\.?\d*)\))?$');
      final match = regex.firstMatch(text.trim());
      
      if (match == null) {
        throw Exception('스케줄 형식이 올바르지 않습니다. 예시: "유진 9.5-17(0.5)"');
      }

      final employeeName = match.group(1)!;
      final startTimeStr = match.group(2)!;
      final endTimeStr = match.group(3)!;
      final breakHoursStr = match.group(4);

      // 직원 확인
      final employee = await _employeeService.getEmployeeByName(employeeName);
      if (employee == null) {
        throw Exception('직원 "$employeeName"을 찾을 수 없습니다.');
      }

      // 지점 확인
      final branch = await _branchService.getBranchById(branchId);
      if (branch == null) {
        throw Exception('지점을 찾을 수 없습니다.');
      }

      // 시간 파싱
      final startHour = double.parse(startTimeStr);
      final endHour = double.parse(endTimeStr);
      final breakHours = breakHoursStr != null ? double.parse(breakHoursStr) : 0.0;

      // 시간 검증
      if (startHour >= endHour) {
        throw Exception('시작 시간이 종료 시간보다 늦을 수 없습니다.');
      }

      if (startHour < 0 || startHour > 24 || endHour < 0 || endHour > 24) {
        throw Exception('시간은 0-24 사이의 값이어야 합니다.');
      }

      // DateTime으로 변환
      final startTime = DateTime(
        workDate.year,
        workDate.month,
        workDate.day,
        startHour.floor(),
        ((startHour % 1) * 60).round(),
      );

      final endTime = DateTime(
        workDate.year,
        workDate.month,
        workDate.day,
        endHour.floor(),
        ((endHour % 1) * 60).round(),
      );

      // 근무 시간 계산
      final workHours = endTime.difference(startTime).inMinutes / 60.0 - breakHours;

      if (workHours < 0) {
        throw Exception('휴게 시간이 근무 시간보다 클 수 없습니다.');
      }

      return Schedule(
        id: '',
        employeeId: employee.id,
        employeeName: employee.name,
        workDate: workDate,
        startTime: startTime,
        endTime: endTime,
        workHours: workHours,
        breakHours: breakHours,
        branchId: branchId,
        branchName: branch.name,
        hourlyWage: employee.hourlyWage,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('스케줄 파싱에 실패했습니다: $e');
    }
  }

  // 직원별 월별 리포트
  Future<Map<String, dynamic>> getEmployeeMonthlyReport(String employeeId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('schedules')
          .where('employeeId', isEqualTo: employeeId)
          .where('workDate', isGreaterThanOrEqualTo: startDate)
          .where('workDate', isLessThanOrEqualTo: endDate)
          .orderBy('workDate')
          .get();

      final schedules = snapshot.docs.map((doc) {
        final data = doc.data();
        return Schedule.fromMap({...data, 'id': doc.id});
      }).toList();

      double totalWorkHours = 0;
      double totalBreakHours = 0;
      double totalPay = 0;
      int totalWorkDays = schedules.length;

      for (final schedule in schedules) {
        totalWorkHours += schedule.workHours;
        totalBreakHours += schedule.breakHours;
        totalPay += schedule.totalPay;
      }

      return {
        'schedules': schedules,
        'totalWorkHours': totalWorkHours,
        'totalBreakHours': totalBreakHours,
        'totalPay': totalPay,
        'totalWorkDays': totalWorkDays,
        'averageWorkHoursPerDay': totalWorkDays > 0 ? totalWorkHours / totalWorkDays : 0,
      };
    } catch (e) {
      throw Exception('직원별 리포트 생성에 실패했습니다: $e');
    }
  }

  // 지점별 월별 리포트
  Future<Map<String, dynamic>> getBranchMonthlyReport(String branchId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('schedules')
          .where('branchId', isEqualTo: branchId)
          .where('workDate', isGreaterThanOrEqualTo: startDate)
          .where('workDate', isLessThanOrEqualTo: endDate)
          .orderBy('workDate')
          .get();

      final schedules = snapshot.docs.map((doc) {
        final data = doc.data();
        return Schedule.fromMap({...data, 'id': doc.id});
      }).toList();

      // 직원별로 그룹화
      final Map<String, List<Schedule>> employeeSchedules = {};
      for (final schedule in schedules) {
        if (!employeeSchedules.containsKey(schedule.employeeId)) {
          employeeSchedules[schedule.employeeId] = [];
        }
        employeeSchedules[schedule.employeeId]!.add(schedule);
      }

      // 직원별 통계 계산
      final List<Map<String, dynamic>> employeeStats = [];
      double totalWorkHours = 0;
      double totalPay = 0;

      for (final entry in employeeSchedules.entries) {
        final employeeSchedulesList = entry.value;
        double employeeWorkHours = 0;
        double employeePay = 0;

        for (final schedule in employeeSchedulesList) {
          employeeWorkHours += schedule.workHours;
          employeePay += schedule.totalPay;
        }

        totalWorkHours += employeeWorkHours;
        totalPay += employeePay;

        employeeStats.add({
          'employeeId': entry.key,
          'employeeName': employeeSchedulesList.first.employeeName,
          'workHours': employeeWorkHours,
          'pay': employeePay,
          'workDays': employeeSchedulesList.length,
        });
      }

      return {
        'schedules': schedules,
        'employeeStats': employeeStats,
        'totalWorkHours': totalWorkHours,
        'totalPay': totalPay,
        'totalWorkDays': schedules.length,
        'uniqueEmployees': employeeSchedules.length,
      };
    } catch (e) {
      throw Exception('지점별 리포트 생성에 실패했습니다: $e');
    }
  }
}
