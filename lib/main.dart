import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hisab_app/src/features/login_screen.dart';
import 'package:hisab_app/src/features/main_screen.dart';

import 'core/widgets/auth_check.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Fluid Architect',
      theme: ThemeData.dark(),
      home: const AuthCheck(),
    );
  }
}
