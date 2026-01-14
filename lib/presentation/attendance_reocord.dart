import 'dart:convert';
import 'dart:io';

import 'package:biometric/data/enrollment_repository.dart';
import 'package:biometric/data/student_repository.dart';
import 'package:biometric/domain/attendance.dart';
import 'package:biometric/domain/course.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceRecordsScreen extends StatefulWidget {
  final int studentId;
  const AttendanceRecordsScreen({super.key, required this.studentId});

  @override
  State<AttendanceRecordsScreen> createState() =>
      _AttendanceRecordsScreenState();
}

class _AttendanceRecordsScreenState extends State<AttendanceRecordsScreen> {
  File? _profileImage;
  List<Course> courses = [];
  Map<int, String> courseIdToName = {};
  Future<List<Course>> get _coursesFuture =>
      EnrollmentRepository().fetchCoursesForStudent(widget.studentId);

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_path');
    if (path != null && File(path).existsSync()) {
      setState(() {
        _profileImage = File(path);
      });
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PreferredSize(
      preferredSize: Size.fromHeight(MediaQuery.of(context).size.height * 0.10),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : const Color(0xFF4169E1),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black54 : const Color(0x334169E1)),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Container(
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: MediaQuery.of(context).size.width * 0.06,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : null,
                  child: _profileImage == null
                      ? Icon(
                          Icons.fingerprint,
                          color: isDark ? Colors.grey[900] : Colors.white,
                          size: MediaQuery.of(context).size.width * 0.08,
                        )
                      : null,
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Attendance Records',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.06,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.005,
                    ),
                    Text(
                      'View and filter your attendance history',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(width: MediaQuery.of(context).size.width * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int? selectedCourseId;
  String? selectedStatus;
  DateTime? selectedDate;
  int page = 1;
  final int pageSize = 10;
  bool isLoading = false;
  List<Attendance> records = [];
  int totalRecords = 0;
  String? error;
  // String? debugRawResponse;

  // Removed duplicate initState; initialization is handled above.

  Future<void> fetchRecords() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      // Build query params
      Map<String, String> params = {
        'stdId': widget.studentId.toString(),
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };
      if (selectedCourseId != null) {
        params['courseID'] = selectedCourseId.toString();
      }
      if (selectedStatus != null && selectedStatus!.isNotEmpty) {
        params['status'] = selectedStatus!;
      }
      // Add date filter if selectedDate is set
      if (selectedDate != null) {
        // Format as yyyy-MM-dd
        final dateStr =
            '${selectedDate!.year.toString().padLeft(4, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
        params['date'] = dateStr;
      }

      final url = Uri.parse(
        '${StudentRepository.baseUrl}/attendance',
      ).replace(queryParameters: params);
      final response = await http.get(url);
      print('DEBUG: Raw GET /attendance response: ' + response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] as List?) ?? [];
        print('DEBUG: Raw attendance record maps:');
        for (var e in list) {
          print(e);
        }
        final parsedRecords = list.map((e) => Attendance.fromJson(e)).toList();
        print('DEBUG: Parsed attendance records:');
        for (var att in parsedRecords) {
          print(
            '  attId: \\${att.attId}, courseID: \\${att.courseID}, status: \\${att.status}, markedAt: \\${att.markedAt}',
          );
        }
        setState(() {
          records = parsedRecords;
          totalRecords = data['total'] ?? records.length;
        });
      } else {
        setState(() {
          error = 'Failed to load records.';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildFilters() {
    return FutureBuilder<List<Course>>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load courses'));
        }
        final enrolledCourses = snapshot.data ?? [];
        courses = enrolledCourses;
        courseIdToName = {for (var c in courses) c.id: c.name};
        Course? selectedCourse = selectedCourseId == null
            ? null
            : courses.firstWhere(
                (c) => c.id == selectedCourseId,
                orElse: () => Course(id: -1, name: '', teacherId: null),
              );
        if (selectedCourse != null && selectedCourse.id == -1) {
          selectedCourse = null;
        }
        final screenWidth = MediaQuery.of(context).size.width;
        final dropdownWidth = (screenWidth * 0.45).clamp(160.0, 350.0);
        final isWide = screenWidth > 500;
        final filterWidgets = [
          SizedBox(
            width: dropdownWidth,
            child: DropdownButtonFormField<Course>(
              value: selectedCourse,
              hint: const Text('Course'),
              items: [
                DropdownMenuItem<Course>(
                  value: null,
                  child: Text('All Courses'),
                ),
                ...courses.map(
                  (course) => DropdownMenuItem<Course>(
                    value: course,
                    child: Text(course.name),
                  ),
                ),
              ],
              onChanged: (Course? value) {
                setState(() {
                  selectedCourseId = value?.id;
                  page = 1;
                });
                fetchRecords();
              },
              decoration: const InputDecoration(
                labelText: 'Course',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 16, height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range, color: Color(0xFF4169E1)),
            label: Text(
              selectedDate == null
                  ? 'Date'
                  : selectedDate!.toIso8601String().split('T')[0],
            ),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  selectedDate = picked;
                  page = 1;
                });
                fetchRecords();
              }
            },
          ),
          if (selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              onPressed: () {
                setState(() {
                  selectedDate = null;
                  page = 1;
                });
                fetchRecords();
              },
            ),
        ];
        return isWide
            ? Row(children: filterWidgets)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: filterWidgets,
              );
      },
    );
  }

  Widget buildTable() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Text(error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (records.isEmpty) {
      return const Center(child: Text('No attendance records found.'));
    }
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final att = records[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        // Use courseTitle if available, else fallback to courseID
        String courseName = att.courseTitle ?? 'Course ${att.courseID}';
        // Status: show 'Present' if valid is true, else 'Absent'
        String status = (att.valid == true) ? 'Present' : 'Absent';
        // Marked at: always use createdAt
        String markedAtRaw = att.createdAt ?? '';
        String markedAt = 'Unknown';
        if (markedAtRaw.isNotEmpty) {
          try {
            final dt = DateTime.parse(markedAtRaw);
            markedAt =
                '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          } catch (e) {
            markedAt = markedAtRaw;
          }
        }
        return Card(
          color: isDark ? Colors.grey[850] : Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          elevation: 3,
          child: ListTile(
            title: Text(
              courseName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('Status: $status'), Text('Marked at: $markedAt')],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFilters(),
            const SizedBox(height: 16),
            Expanded(child: buildTable()),
          ],
        ),
      ),
    );
  }
}
