import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pretzel_apk/auth/auth_gate.dart';
import 'package:pretzel_apk/core/theme_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load();

  // Add this debug print to see your bucket URL
  print('Storage bucket: ${FirebaseStorage.instance.bucket}');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, themeMode, child) {
        return AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 500,
          ), // Smooth transition duration
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Pretzel App',
            theme: ThemeData(
              fontFamily: 'Poppins',
              textTheme: const TextTheme(
                displayLarge: TextStyle(fontFamily: 'Poppins'),
                displayMedium: TextStyle(fontFamily: 'Poppins'),
                displaySmall: TextStyle(fontFamily: 'Poppins'),
                headlineLarge: TextStyle(fontFamily: 'Poppins'),
                headlineMedium: TextStyle(fontFamily: 'Poppins'),
                headlineSmall: TextStyle(fontFamily: 'Poppins'),
                titleLarge: TextStyle(fontFamily: 'Poppins'),
                titleMedium: TextStyle(fontFamily: 'Poppins'),
                titleSmall: TextStyle(fontFamily: 'Poppins'),
                bodyLarge: TextStyle(fontFamily: 'Poppins'),
                bodyMedium: TextStyle(fontFamily: 'Poppins'),
                bodySmall: TextStyle(fontFamily: 'Poppins'),
                labelLarge: TextStyle(fontFamily: 'Poppins'),
                labelMedium: TextStyle(fontFamily: 'Poppins'),
                labelSmall: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
            darkTheme: ThemeManager.darkTheme,
            themeMode: themeMode,
            home: const AuthGate(), // Ensure this is the entry point
          ),
        );
      },
    );
  }
}
