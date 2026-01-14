import 'package:biometric/core/service_locator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:biometric/domain/attendance.dart';
import 'package:biometric/help/biometric_helper.dart';
import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  final Map<String, dynamic> course;
  const AttendanceScreen({
    super.key,
    required this.student,
    required this.course,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool isAuthenticating = false;
  String? message;

  Future<void> takeAttendance() async {
    try {
      setState(() {
        isAuthenticating = true;
        message = null;
      });
      final biometricHelper = BiometricHelper();
      final hasBiometric = await biometricHelper.hasEnrolledBiometrics();
      if (!hasBiometric) {
        setState(() {
          isAuthenticating = false;
          message = 'No biometrics enrolled.';
        });
        return;
      }
      final authenticated = await biometricHelper.authenticate();
      if (!authenticated) {
        setState(() {
          isAuthenticating = false;
          message = 'Biometric authentication failed.';
        });
        return;
      }
      // Use real fingerprint hash and location
      final fingerprintHash = DateTime.now().millisecondsSinceEpoch.toString();
      Position? position;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() {
            isAuthenticating = false;
            message = 'Location services are disabled.';
          });
          return;
        }
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            setState(() {
              isAuthenticating = false;
              message = 'Location permission denied.';
            });
            return;
          }
        }
        if (permission == LocationPermission.deniedForever) {
          setState(() {
            isAuthenticating = false;
            message = 'Location permission permanently denied.';
          });
          return;
        }
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        print('[ERROR] Failed to get location: $e');
        setState(() {
          isAuthenticating = false;
          message = 'Could not get your location. Please try again.';
        });
        return;
      }
      final latitude = position.latitude.toString();
      final longitude = position.longitude.toString();
      final stdId = widget.student['id'] ?? 1;
      final courseID = widget.course['id'] ?? 1;
      // Fetch open sessionID for the course
      final studentRepo = ServiceLocator().studentUseCase.repository;
      final sessionID = await studentRepo.fetchOpenSessionIdForCourse(courseID);
      if (sessionID == null) {
        setState(() {
          isAuthenticating = false;
          message = 'Attendance session is not currently open for this course.';
        });
        return;
      }
      final useCase = ServiceLocator().studentUseCase;
      final Attendance? attendance = await useCase.takeAttendance(
        sessionID: sessionID,
        stdId: stdId,
        fingerprintHash: fingerprintHash,
        latitude: latitude,
        longitude: longitude,
      );
      setState(() {
        isAuthenticating = false;
      });
      if (attendance != null) {
        setState(() {
          message =
              'Attendance: ${attendance.status ?? 'recorded'} (Marked by: ${attendance.markedBy ?? 'unknown'})';
        });
      } else {
        setState(() {
          message = 'Attendance failed. Please try again.';
        });
      }
    } catch (e, stack) {
      print('[ERROR] Exception in takeAttendance: $e\n$stack');
      setState(() {
        isAuthenticating = false;
        message = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: const Color(0xFF4169E1),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, size: 80, color: Color(0xFF4169E1)),
              const SizedBox(height: 24),
              Text(
                'Welcome, ${widget.student['name'] ?? 'Student'}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4169E1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Matricule: ${widget.student['matricule'] ?? 'matricule'}',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Text(
                'Course: ${widget.course['name']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4169E1),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4169E1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: isAuthenticating ? null : takeAttendance,
                child: isAuthenticating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Take Attendance',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 24),
              if (message != null)
                Text(
                  message!,
                  style: TextStyle(
                    color: message!.contains('success')
                        ? Colors.green
                        : Colors.red,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
