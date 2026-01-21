import 'package:biometric/core/service_locator.dart';
import 'package:biometric/domain/student.dart';
import 'package:biometric/presentation/new_landing.dart';
import 'package:biometric/presentation/register.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> login() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    final useCase = ServiceLocator().studentUseCase;
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    print('Attempting login with:');
    print('Matricule (sent as email): $email');
    print('Password: $password');
    final Student? student = await useCase.login(email, password);
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
    if (student != null) {
      print('Login successful for $email');
      // Store student info for landing/profile
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('student_name', student.name);
      await prefs.setString('student_matricule', student.matricule);
      await prefs.setString('student_email', email);
      await prefs.setInt('student_id', student.stdId);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NewLandingScreen()),
      );
    } else {
      print('Login failed for $email');
      setState(() {
        errorMessage = 'Invalid matricule or password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            color: isDark ? Colors.grey[850] : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white : Color(0xFF4169E1),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Icon(
                      Icons.lock,
                      size: 48,
                      color: isDark ? Colors.grey[900] : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Color(0xFF4169E1),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: emailController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.badge,
                        color: isDark ? Colors.white : Color(0xFF4169E1),
                      ),
                      labelText: 'Matricule',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white : Color(0xFF4169E1),
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: isDark ? Colors.white : Color(0xFF4169E1),
                      ),
                      labelText: 'Password',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white : Color(0xFF4169E1),
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: isDark ? Colors.white : Color(0xFF4169E1),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: isDark ? Colors.red[200] : Colors.red,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Don't have an account? Register",
                      style: TextStyle(
                        color: isDark ? Colors.white : Color(0xFF4169E1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
