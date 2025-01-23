import 'package:flutter/material.dart';
import 'screens/broadcaster_screen.dart';

class AudioBroadcasterApp extends StatelessWidget {
  const AudioBroadcasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const BroadcasterScreen(),
    );
  }
}
