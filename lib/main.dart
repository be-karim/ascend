import 'package:flutter/material.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/screens/onboarding_screen.dart';

void main() {
  runApp(const AscendApp());
}

class AscendApp extends StatelessWidget {
  const AscendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASCEND',
      debugShowCheckedModeBanner: false,
      theme: AscendTheme.theme,
      home: const OnboardingScreen(),
    );
  }
}
