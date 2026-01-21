import 'package:biometric/domain/course.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EnrollmentRepository {
  static const String baseUrl =
     'https://biometric-attendance-backend-acwj.onrender.com';
  // ...existing code...
 // static const String baseUrl = 'http://192.168.3.103:3000';
  // ...existing code...
  Future<List<Course>> fetchCoursesForStudent(int stdId) async {
    print(
      '[DEBUG] [EnrollmentRepository] fetchCoursesForStudent called with stdId=$stdId',
    );
    final url = Uri.parse('$baseUrl/enrollments/student/$stdId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['courses'] ?? data) as List;
        List<Course> courses = [];
        for (var e in list) {
          final course = Course.fromJson(e);
          String? teacherName;
          if (course.teacherId != null) {
            // Try /teachers/:id first, fallback to /users/:id
            final teacherUrl = Uri.parse(
              '$baseUrl/teachers/${course.teacherId}',
            );
            final teacherResp = await http.get(teacherUrl);
            if (teacherResp.statusCode == 200) {
              final teacherData = jsonDecode(teacherResp.body);
              teacherName =
                  teacherData['name'] ??
                  teacherData['fullName'] ??
                  teacherData['username'];
            } else {
              // Try /users/:id as fallback
              final userUrl = Uri.parse('$baseUrl/users/${course.teacherId}');
              final userResp = await http.get(userUrl);
              if (userResp.statusCode == 200) {
                final userData = jsonDecode(userResp.body);
                teacherName =
                    userData['name'] ??
                    userData['fullName'] ??
                    userData['username'];
              }
            }
          }
          courses.add(
            Course(
              id: course.id,
              name: course.name,
              teacherId: course.teacherId,
              teacherName: teacherName,
            ),
          );
        }
        return courses;
      } else {
        print(
          '[EnrollmentRepository] fetchCoursesForStudent failed: \nStatus: ${response.statusCode}\nBody: ${response.body}',
        );
      }
    } catch (e, stack) {
      print('[EnrollmentRepository] fetchCoursesForStudent error: $e\n$stack');
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
