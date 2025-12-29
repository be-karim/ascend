import 'package:flutter/material.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/screens/onboarding_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    ProviderScope(child: const AscendApp(),),);
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
