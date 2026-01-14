import 'package:biometric/domain/course.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EnrollmentRepository {
  static const String baseUrl =
      'https://biometric-attendance-backend-acwj.onrender.com';

  Future<List<Course>> fetchCoursesForStudent(int stdId) async {
    final url = Uri.parse('$baseUrl/enrollments/student/$stdId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['courses'] ?? data) as List;
        return list.map((e) => Course.fromJson(e)).toList();
      } else {
        print(
          '[EnrollmentRepository] fetchCoursesForStudent failed: \\nStatus: \\${response.statusCode}\\nBody: \\${response.body}',
        );
      }
    } catch (e, stack) {
      print('[EnrollmentRepository] fetchCoursesForStudent error: $e\\n$stack');
    }
    return [];
  }

  Future<List<int>> fetchStudentsInCourse(int courseId) async {
    final url = Uri.parse('$baseUrl/enrollments/course/$courseId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['students'] ?? data) as List;
        return list.map((e) => e as int).toList();
      } else {
        print(
          '[EnrollmentRepository] fetchStudentsInCourse failed: \\nStatus: \\${response.statusCode}\\nBody: \\${response.body}',
        );
      }
    } catch (e, stack) {
      print('[EnrollmentRepository] fetchStudentsInCourse error: $e\\n$stack');
    }
    return [];
  }

  Future<String?> enrollStudent(int stdId, int courseId) async {
    final url = Uri.parse('$baseUrl/enrollments');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'stdId': stdId, 'courseID': courseId}),
      );
      if (response.statusCode == 201) {
        return null; // Success
      } else {
        print(
          '[EnrollmentRepository] enrollStudent failed: Status: \\${response.statusCode} Body: \\${response.body}',
        );
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['message'] != null) {
            return data['message'].toString();
          }
        } catch (_) {}
        return 'Enrollment failed.';
      }
    } catch (e, stack) {
      print('[EnrollmentRepository] enrollStudent error: $e\n$stack');
      return 'Enrollment failed.';
    }
  }
}
