import 'package:biometric/domain/course.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CourseRepository {
  Future<Map<int, String>> fetchTeacherNames() async {
    final url = Uri.parse('$baseUrl/teachers');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['teachers'] ?? data['data'] ?? data) as List;
        return {
          for (var t in list)
            if (t['teacherId'] != null && t['name'] != null)
              (t['teacherId'] as int): t['name'] as String,
        };
      }
    } catch (e, stack) {
      print('[CourseRepository] fetchTeacherNames error: $e\n$stack');
    }
    return {};
  }

  static const String baseUrl =
      'https://biometric-attendance-backend-acwj.onrender.com';
  // ...existing code...
  //static const String baseUrl = 'http://192.168.3.103:3000';
  // ...existing code...
  Future<List<Course>> fetchCourses({
    int? page,
    int? pageSize,
    int? teacherId,
  }) async {
    final params = <String, String>{};
    if (page != null) params['page'] = page.toString();
    if (pageSize != null) params['pageSize'] = pageSize.toString();
    if (teacherId != null) params['teacherID'] = teacherId.toString();
    final url = Uri.parse('$baseUrl/courses').replace(queryParameters: params);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['courses'] ?? data['data'] ?? data) as List;
        print('[CourseRepository] Raw course list: $list');
        return list
            .where(
              (e) =>
                  e != null &&
                  e is Map &&
                  ((e['id'] != null) || (e['courseID'] != null)),
            )
            .map((e) => Course.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        print(
          '[CourseRepository] fetchCourses failed: Status: \\${response.statusCode} Body: \\${response.body}',
        );
      }
    } catch (e, stack) {
      print('[CourseRepository] fetchCourses error: $e\\n$stack');
    }
    return [];
  }
}
