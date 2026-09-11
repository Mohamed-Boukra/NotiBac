import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NotiBacApp());
}

class NotiBacApp extends StatelessWidget {
  const NotiBacApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NotiBac',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          primary: Colors.orange,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
