import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/screens/auth_wrapper.dart';
import 'src/screens/about_page.dart';
import 'src/screens/security_settings_screen.dart';
import 'src/screens/backup_restore_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ganesh Auto Parts',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/about': (context) => const AboutPage(),
        '/security': (context) => const SecuritySettingsScreen(),
        '/backup': (context) => const BackupRestoreScreen(),
      },
    );
  }
}
