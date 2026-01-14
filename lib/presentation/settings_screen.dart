import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biometric/presentation/login.dart';
import 'package:provider/provider.dart';
import 'package:biometric/main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(height * 0.10),
        child: Container(
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
          child: SafeArea(
            child: Container(
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: width * 0.04),
                  Builder(
                    builder: (context) {
                      final ModalRoute<Object?>? parentRoute = ModalRoute.of(
                        context,
                      );
                      File? profileImage;
                      if (parentRoute != null &&
                          parentRoute.settings.arguments is Map) {
                        final args = parentRoute.settings.arguments as Map;
                        if (args['profileImage'] is File) {
                          profileImage = args['profileImage'] as File;
                        }
                      }
                      return CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: width * 0.06,
                        backgroundImage: profileImage != null
                            ? FileImage(profileImage)
                            : null,
                        child: profileImage == null
                            ? Icon(
                                Icons.settings,
                                color: isDark ? Colors.grey[900] : Colors.white,
                                size: width * 0.08,
                              )
                            : null,
                      );
                    },
                  ),
                  SizedBox(width: width * 0.04),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.06,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      SizedBox(height: height * 0.005),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(width: width * 0.04),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.06,
          vertical: height * 0.03,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account',
              style: TextStyle(
                fontSize: width * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: height * 0.02),
            ListTile(
              leading: Icon(Icons.person, color: Color(0xFF4169E1)),
              title: Text('Profile'),
              trailing: Icon(Icons.arrow_forward_ios, size: width * 0.04),
              onTap: () {},
            ),
            Divider(),
            Text(
              'Preferences',
              style: TextStyle(
                fontSize: width * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: height * 0.02),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return SwitchListTile(
                  secondary: Icon(Icons.palette, color: Color(0xFF4169E1)),
                  title: Text('Dark Mode'),
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (val) {
                    themeProvider.toggleTheme(val);
                  },
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications, color: Color(0xFF4169E1)),
              title: Text('Notifications'),
              trailing: Icon(Icons.arrow_forward_ios, size: width * 0.04),
              onTap: () {},
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
