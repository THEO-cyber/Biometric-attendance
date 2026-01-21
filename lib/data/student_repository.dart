import 'package:biometric/domain/attendance.dart';
import 'package:biometric/domain/student.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentRepository {
  Future<int?> fetchOpenSessionIdForCourse(int courseID) async {
    final url = Uri.parse(
      '$baseUrl/attendance/course/$courseID/attendance-sessions/open',
    );
    final response = await http.get(url);
    print('Open session response: \\${response.statusCode} \\${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['session'] != null && data['session']['sessionId'] != null) {
        return data['session']['sessionId'] as int;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchOpenSessionForCourse(int courseID) async {
    final url = Uri.parse(
      '$baseUrl/attendance/course/$courseID/attendance-sessions/open',
    );
    final response = await http.get(url);
    print('Open session response: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    }
    return null;
  }

  static const String baseUrl =
      'https://biometric-attendance-backend-acwj.onrender.com';
  // ...existing code...
  //static const String baseUrl = 'http://192.168.3.103:3000';
  // ...existing code...
  Future<Student?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/students/loginn');
    final payload = {'email': email, 'password': password};
    print('LOGIN REQUEST PAYLOAD: ' + jsonEncode(payload));
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    print('LOGIN RESPONSE: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Student.fromJson(data['student']);
    }
    return null;
  }

  Future<bool> register(
    String name,
    String email,
    String matricule,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/students/registerr');
    final payload = {
      'name': name,
      'email': email,
      'matricule': matricule,
      'password': password,
    };
    print('REGISTER REQUEST PAYLOAD: ' + jsonEncode(payload));
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    print('REGISTER RESPONSE: ${response.statusCode} ${response.body}');
    return response.statusCode == 201;
  }

  Future<Map<String, dynamic>?> takeAttendance({
    required int sessionID,
    required int stdId,
    required String fingerprintHash,
    required String latitude,
    required String longitude,
  }) async {
    final url = Uri.parse(
      '$baseUrl/attendance/attendance-sessions/$sessionID/attendance',
    );
    final requestBody = {
      'stdId': stdId,
      'fingerprinthash': fingerprintHash,
      'latitude': latitude,
      'longitude': longitude,
    };
    print('Sending attendance: ' + jsonEncode(requestBody));
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );
    print('Attendance response: ${response.statusCode} ${response.body}');

    final data = jsonDecode(response.body);

    // Return response data with status code for better error handling
    return {
      'statusCode': response.statusCode,
      'data': data,
      'success': response.statusCode == 200,
    };
  }

  Future<List<Attendance>> fetchAttendanceStatus(int stdId) async {
    final url = Uri.parse('$baseUrl/attendance?stdId=$stdId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map<Attendance>((item) => Attendance.fromJson(item))
            .toList();
      } else if (data['attendance'] is List) {
        return (data['attendance'] as List)
            .map<Attendance>((item) => Attendance.fromJson(item))
            .toList();
      }
    }
    return [];
  }
}
