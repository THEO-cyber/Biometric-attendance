import 'package:biometric/data/student_repository.dart';
import 'package:biometric/presentation/attendance_reocord.dart';
import 'package:biometric/presentation/enroll_in_course.dart';
import 'package:water_drop_nav_bar/water_drop_nav_bar.dart';
import 'package:biometric/main.dart';
// import 'package:water_drop_nav_bar/water_drop_nav_bar.dart';
import 'package:biometric/presentation/attendance.dart';
import 'package:biometric/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biometric/domain/course.dart';
import 'package:biometric/data/enrollment_repository.dart';

class NewLandingScreen extends StatefulWidget {
  const NewLandingScreen({super.key});

  @override
  State<NewLandingScreen> createState() => _NewLandingScreenState();
}

class _NewLandingScreenState extends State<NewLandingScreen> {
  void _showTakeAttendanceDialog(BuildContext context, Color accent) {
    final enrollRepo = EnrollmentRepository();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FutureBuilder<List<Course>>(
          future: enrollRepo.fetchCoursesForStudent(studentId ?? 0),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            List<Course> enrolledCourses = snapshot.data!;
            Course? selectedCourse;
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('Take Attendance'),
                  content: enrolledCourses.isEmpty
                      ? const Text('You are not enrolled in any courses.')
                      : DropdownButtonFormField<Course>(
                          value: selectedCourse,
                          items: enrolledCourses
                              .map(
                                (course) => DropdownMenuItem(
                                  value: course,
                                  child: Text(course.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedCourse = value),
                          decoration: const InputDecoration(
                            labelText: 'Course',
                            border: OutlineInputBorder(),
                          ),
                        ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: selectedCourse == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              _showConfirmAttendanceDialog(context, accent, {
                                'id': selectedCourse!.id,
                                'name': selectedCourse!.name,
                              });
                            },
                      child: const Text('Next'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // No local nav bar item list; define inline in widget
  int _selectedIndex = 0;
  // Removed unused _selectedCourse
  File? _profileImage;
  // Removed unused _courses field

  String? studentName;
  String? studentMatricule;
  String? studentEmail;
  int? studentId;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadStudentInfo();
  }

  Future<void> _loadStudentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      studentName = prefs.getString('student_name') ?? 'Student';
      studentMatricule = prefs.getString('student_matricule');
      studentEmail = prefs.getString('student_email');
      studentId = prefs.getInt('student_id');
      print(
        '[DEBUG] Loaded student info: name=$studentName, matricule=$studentMatricule, email=$studentEmail, id=$studentId',
      );
    });
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', pickedFile.path);
    }
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

  @override
  Widget build(BuildContext context) {
    final Color accent = const Color(0xFF4169E1); // Royal Blue
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          extendBody: true,
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              // Home
              isWide
                  ? Row(
                      children: [
                        Expanded(child: _buildHeader(accent)),
                        Expanded(child: _buildHomeContent(context, accent)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildHeader(accent),
                        Expanded(child: _buildHomeContent(context, accent)),
                      ],
                    ),
              // Attendance Records
              AttendanceRecordsScreen(studentId: studentId ?? 0),
              // Profile
              _buildProfileContent(accent),
              // Settings
              const SettingsScreen(),
            ],
          ),
          bottomNavigationBar: WaterDropNavBar(
            backgroundColor: isDark ? Colors.grey[900]! : accent,
            waterDropColor: Colors.white,
            inactiveIconColor: Colors.white70,
            iconSize: 28,
            selectedIndex: _selectedIndex,
            onItemSelected: (i) {
              setState(() {
                _selectedIndex = i;
              });
            },
            barItems: [
              BarItem(
                filledIcon: Icons.home,
                outlinedIcon: Icons.home_outlined,
              ),
              BarItem(
                filledIcon: Icons.list_alt,
                outlinedIcon: Icons.list_alt_outlined,
              ),
              BarItem(
                filledIcon: Icons.person,
                outlinedIcon: Icons.person_outline,
              ),
              BarItem(
                filledIcon: Icons.settings,
                outlinedIcon: Icons.settings_outlined,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomeContent(BuildContext context, Color accent) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? size.width * 0.15 : 24,
        vertical: isWide ? 48 : 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fingerprint, color: accent, size: isWide ? 60 : 40),
              SizedBox(width: isWide ? 20 : 10),
              Text(
                'HIMS Attendance',
                style: TextStyle(
                  color: accent,
                  fontSize: isWide ? 38 : 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Secure, fast, and easy attendance with biometrics.',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black54,
                fontSize: isWide ? 22 : 16,
              ),
            ),
          ),
          SizedBox(height: isWide ? 48 : 32),
          Row(
            children: [
              Expanded(
                child: _featureCard(
                  icon: Icons.fingerprint,
                  title: 'Take Attendance',
                  color: accent,
                  onTap: () => _showTakeAttendanceDialog(context, accent),
                  fontSize: isWide ? 22 : 17,
                  iconSize: isWide ? 48 : 38,
                ),
              ),
              SizedBox(width: isWide ? 32 : 18),
              Expanded(
                child: _featureCard(
                  icon: Icons.assignment_turned_in,
                  title: 'View Status',
                  color: accent,
                  onTap: () => setState(() => _selectedIndex = 1),
                  fontSize: isWide ? 22 : 17,
                  iconSize: isWide ? 48 : 38,
                ),
              ),
            ],
          ),
          SizedBox(height: isWide ? 32 : 18),
          Row(
            children: [
              Expanded(
                child: _featureCard(
                  icon: Icons.school,
                  title: 'Enroll in Course',
                  color: accent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EnrollInCoursePage(
                        accent: accent,
                        studentId: studentId,
                      ),
                    ),
                  ),
                  fontSize: isWide ? 22 : 17,
                  iconSize: isWide ? 48 : 38,
                ),
              ),
            ],
          ),
          SizedBox(height: isWide ? 48 : 36),
        ],
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    double fontSize = 17,
    double iconSize = 38,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        color: isDark ? Colors.grey[850] : Colors.white,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: iconSize + 10, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[900] : color.withAlpha(30),
                ),
                padding: EdgeInsets.all(iconSize / 2),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: isDark ? Colors.white : color,
                ),
              ),
              SizedBox(height: iconSize / 2),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmAttendanceDialog(
    BuildContext context,
    Color accent,
    Map<String, dynamic> course,
  ) {
    print(
      '[DEBUG] Confirming attendance for course: ${course['name']} (id: ${course['id']})',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('You are about to take attendance for'),
          content: Text(
            course['name'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                // Check if attendance session is open
                final studentRepo = StudentRepository();
                final sessionId = await studentRepo.fetchOpenSessionIdForCourse(
                  course['id'],
                );
                if (sessionId == null) {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Attendance Not Open'),
                      content: const Text(
                        'Attendance for this course is not open.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                _showBiometricAttendanceScreen(context, course);
              },
              child: const Text('Take Attendance'),
            ),
          ],
        );
      },
    );
  }

  void _showBiometricAttendanceScreen(
    BuildContext context,
    Map<String, dynamic> course,
  ) {
    print(
      '[DEBUG] Launching AttendanceScreen with studentId=$studentId, course=' +
          course['name'] +
          ' (id: ' +
          course['id'].toString() +
          ')',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceScreen(
          student: {
            'id': studentId,
            'name': studentName ?? 'Student',
            'matricule': studentMatricule ?? 'matricule',
            'email': studentEmail ?? '',
          },
          course: course,
        ),
      ),
    );
  }

  // _showStatusDialog removed; replaced by AttendanceRecordsScreen

  Widget _buildHeader(Color accent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final screenHeight = MediaQuery.of(context).size.height;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Color(0xFF4169E1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x334169E1),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.06,
            vertical: screenHeight * 0.04,
          ),
          child: Container(
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: width * 0.06,
                  child: Icon(
                    Icons.fingerprint,
                    color: isDark ? Colors.grey[900] : Colors.white,
                    size: width * 0.08,
                  ),
                ),
                SizedBox(width: width * 0.04),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'HIMS Attendance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.06,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileContent(Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: isDark
          ? BoxDecoration(color: Colors.grey[900])
          : BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB3C6E7), Color(0xFFE3EAFD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
      child: Center(
        child: Card(
          elevation: 18,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(36),
          ),
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          shadowColor: accent.withAlpha(80),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: accent,
                      child: Icon(Icons.person, size: 48, color: Colors.white),
                    ),
                  ],
                ),

                SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                ),
                SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                ),
                const SizedBox(height: 22),
                Text(
                  studentName ?? 'Student',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  studentMatricule ?? 'matricule',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.grey[900],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 28),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: ListTile(
                    leading: const Icon(Icons.school, color: Colors.black),
                    title: Text(
                      'Student Matricule',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    subtitle: Text(
                      (studentMatricule != null && studentMatricule!.isNotEmpty)
                          ? studentMatricule!
                          : (studentEmail ?? ''),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: ListTile(
                    leading: Icon(Icons.class_, color: Colors.black),
                    title: Text(
                      'Department',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    subtitle: Text(
                      'Software Engineering',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tap the edit icon to change your profile image',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('student_name');
                      await prefs.remove('student_matricule');
                      await prefs.remove('student_email');
                      await prefs.remove('student_id');
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const MyApp()),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
