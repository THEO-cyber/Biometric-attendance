import 'package:biometric/data/course_repository.dart';
import 'package:biometric/data/enrollment_repository.dart';
import 'package:biometric/domain/course.dart';
import 'package:flutter/material.dart';

class EnrollInCoursePage extends StatefulWidget {
  final Color accent;
  final int? studentId;
  const EnrollInCoursePage({
    Key? key,
    required this.accent,
    required this.studentId,
  }) : super(key: key);

  @override
  State<EnrollInCoursePage> createState() => _EnrollInCoursePageState();
}

class _EnrollInCoursePageState extends State<EnrollInCoursePage> {
  Course? selectedCourse;
  bool enrolling = false;

  @override
  Widget build(BuildContext context) {
    final courseRepo = CourseRepository();
    final enrollRepo = EnrollmentRepository();
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          MediaQuery.of(context).size.height * 0.10,
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4169E1), Color(0xFF5A8DEE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x334169E1),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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
                    child: Icon(
                      Icons.school,
                      color: Color(0xFF4169E1),
                      size: MediaQuery.of(context).size.width * 0.08,
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Enroll in a Course',
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
                        'Select and enroll in available courses',
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
      ),
      body: FutureBuilder<List<Course>>(
        future: courseRepo.fetchCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load courses.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          List<Course> courses = snapshot.data ?? [];
          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: widget.accent, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'No courses are available yet.',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DropdownButtonFormField<Course>(
                  value: selectedCourse,
                  items: courses
                      .map(
                        (course) => DropdownMenuItem(
                          value: course,
                          child: Text(course.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => selectedCourse = value),
                  decoration: const InputDecoration(
                    labelText: 'Course',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: enrolling || selectedCourse == null
                        ? null
                        : () async {
                            setState(() => enrolling = true);
                            final result = await enrollRepo.enrollStudent(
                              widget.studentId ?? 0,
                              selectedCourse!.id,
                            );
                            setState(() => enrolling = false);
                            String message;
                            Color color;
                            if (result == null) {
                              if (!mounted) return;
                              message =
                                  'Enrolled in \'${selectedCourse!.name}\' successfully!';
                              color = Colors.green;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: color,
                                ),
                              );
                              Navigator.pop(context);
                            } else if (result.toLowerCase().contains(
                              'already enrolled',
                            )) {
                              message = 'Already enrolled in this course.';
                              color = const Color.fromARGB(255, 199, 120, 3);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: color,
                                ),
                              );
                            } else {
                              message = result;
                              color = Colors.red;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: color,
                                ),
                              );
                            }
                          },
                    child: enrolling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enroll'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
