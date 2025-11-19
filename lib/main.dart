import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/screens/home_page.dart';
import 'src/screens/about_page.dart';

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
        '/': (context) => const HomePage(),
        '/about': (context) => const AboutPage(),
      },
    );
  }
}
