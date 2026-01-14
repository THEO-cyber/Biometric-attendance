import 'package:biometric/data/student_repository.dart';
import 'package:biometric/domain/attendance.dart';
import 'package:biometric/domain/student.dart';

class StudentUseCase {
  final StudentRepository repository;
  StudentUseCase(this.repository);

  Future<Student?> login(String email, String password) {
    return repository.login(email, password);
  }

  Future<bool> register(
    String name,
    String email,
    String matricule,
    String password,
  ) {
    return repository.register(name, email, matricule, password);
  }

  Future<Attendance?> takeAttendance({
    required int sessionID,
    required int stdId,
    required String fingerprintHash,
    required String latitude,
    required String longitude,
  }) {
    return repository.takeAttendance(
      sessionID: sessionID,
      stdId: stdId,
      fingerprintHash: fingerprintHash,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<List<Attendance>> fetchAttendanceStatus(int stdId) {
    return repository.fetchAttendanceStatus(stdId);
  }
}
