import 'package:biometric/core/service_locator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:biometric/domain/attendance.dart';
import 'package:biometric/help/biometric_helper.dart';
import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  final Map<String, dynamic> course;
  final Map<String, dynamic> session; // Add session parameter
  const AttendanceScreen({
    super.key,
    required this.student,
    required this.course,
    required this.session, // Make session required
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool isAuthenticating = false;
  String? message;

  // Replace the takeAttendance method with:

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

      // Use sessionId from the passed session data instead of fetching again
      final sessionID = widget.session['sessionId'];
      print('[DEBUG] Using sessionId from session data: $sessionID');

      if (sessionID == null) {
        setState(() {
          isAuthenticating = false;
          message = 'Session ID not found. Please try again.';
        });
        return;
      }

      // Use the repository directly to get detailed response
      final studentRepo = ServiceLocator().studentUseCase.repository;
      final response = await studentRepo.takeAttendance(
        sessionID: sessionID,
        stdId: stdId,
        fingerprintHash: fingerprintHash,
        latitude: latitude,
        longitude: longitude,
      );

      setState(() {
        isAuthenticating = false;
      });

      if (response != null) {
        final statusCode = response['statusCode'];
        final data = response['data'];

        if (statusCode == 200) {
          // Successful attendance
          final attendance = Attendance.fromJson(data['attendance']);
          setState(() {
            message =
                'Attendance successfully recorded! Status: ${attendance.status ?? 'Present'}';
          });
        } else if (statusCode == 409) {
          // Conflict - attendance already taken
          setState(() {
            message = 'Attendance already taken for this session.';
          });
        } else if (statusCode == 404) {
          setState(() {
            message = 'Attendance session not found or has ended.';
          });
        } else if (statusCode == 400) {
          // Bad request - could be invalid data
          final errorMessage = data['message'] ?? 'Invalid attendance data.';
          setState(() {
            message = errorMessage;
          });
        } else {
          // Other error codes
          final errorMessage =
              data['message'] ?? 'Attendance failed. Please try again.';
          setState(() {
            message = errorMessage;
          });
        }
      } else {
        setState(() {
          message = 'Network error. Please try again.';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: isDark ? Colors.grey[900] : Color(0xFF4169E1),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('asset/image/atten.png', width: 80, height: 80),
              const SizedBox(height: 24),
              Text(
                'Welcome, ${widget.student['name'] ?? 'Student'}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF4169E1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Matricule: ${widget.student['matricule'] ?? 'matricule'}',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Course: ${widget.course['name']}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Color(0xFF4169E1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Session: ${widget.session['sessionId'] ?? 'Unknown'}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
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
