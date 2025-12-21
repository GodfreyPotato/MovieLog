import 'package:flutter/material.dart';
import 'package:movie_log/screens/homescreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: MovieLogApp(), debugShowCheckedModeBanner: false));
}

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({super.key});

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  @override
  Widget build(BuildContext context) {
    return Homescreen();
  }
}
