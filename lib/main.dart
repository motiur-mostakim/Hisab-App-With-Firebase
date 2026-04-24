import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hisab_app/core/services/notification_service.dart';

import 'core/widgets/auth_check.dart';
import 'firebase_options.dart';

// Global theme notifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initNotification();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Hisab App',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            colorSchemeSeed: const Color(0xFF60DCB2),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0C0C1F), // আপনার আগের ডার্ক কালার
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF111125),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            colorSchemeSeed: const Color(0xFF60DCB2),
          ),
          themeMode: currentMode,
          home: const AuthCheck(),
        );
      },
    );
  }
}
