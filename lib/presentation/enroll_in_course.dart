import 'package:flutter/material.dart';
import 'package:biometric/data/course_repository.dart';
import 'package:biometric/data/enrollment_repository.dart';
import 'package:biometric/domain/course.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnrollInCoursePage extends StatefulWidget {
  const EnrollInCoursePage({Key? key, int? studentId, required Color accent})
    : super(key: key);

  @override
  State<EnrollInCoursePage> createState() => _EnrollInCoursePageState();
}

class _EnrollInCoursePageState extends State<EnrollInCoursePage> {
  late Future<List<Course>> _coursesFuture;
  late Future<Map<int, String>> _teacherNamesFuture;
  int? _studentId;
  bool _enrolling = false;
  int? _enrolledCourseId;

  @override
  void initState() {
    super.initState();
    _loadStudentId();
    // Show all courses for enrollment, not just enrolled ones
    _coursesFuture = CourseRepository().fetchCourses();
    _teacherNamesFuture = CourseRepository().fetchTeacherNames();
  }

  Future<void> _loadStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentId = prefs.getInt('student_id');
    });
  }

  Future<void> _enroll(int courseId) async {
    if (_studentId == null) return;
    setState(() {
      _enrolling = true;
      _enrolledCourseId = courseId;
    });
    final result = await EnrollmentRepository().enrollStudent(
      _studentId!,
      courseId,
    );
    setState(() {
      _enrolling = false;
    });
    String message;
    Color color;
    if (result == null) {
      message = 'Enrolled successfully!';
      color = Colors.green;
    } else if (result.toLowerCase().contains('already enrolled')) {
      message = 'Already enrolled in this course.';
      color = Colors.orange;
    } else {
      message = result;
      color = Colors.red;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enroll in Course')),
      body: FutureBuilder<List<Course>>(
        future: _coursesFuture,
        builder: (context, courseSnapshot) {
          if (courseSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (courseSnapshot.hasError) {
            return Center(child: Text('Error loading courses'));
          } else if (!courseSnapshot.hasData || courseSnapshot.data!.isEmpty) {
            return const Center(child: Text('No courses available.'));
          }
          final courses = courseSnapshot.data!;
          return FutureBuilder<Map<int, String>>(
            future: _teacherNamesFuture,
            builder: (context, teacherSnapshot) {
              final teacherNames = teacherSnapshot.data ?? {};
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final course = courses[index];
                  final teacherName = course.teacherId != null
                      ? teacherNames[course.teacherId] ?? 'Unknown'
                      : 'Unknown';
                  return ListTile(
                    title: Text(course.name),
                    subtitle: Text('Instructor: $teacherName'),
                    trailing: _enrolling && _enrolledCourseId == course.id
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : ElevatedButton(
                            onPressed: _studentId == null
                                ? null
                                : () => _enroll(course.id),
                            child: const Text('Enroll'),
                          ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
