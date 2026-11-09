import 'package:flutter/material.dart';
import 'screens/branch_selection_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgriVisionApp());
}

class AgriVisionApp extends StatelessWidget {
  const AgriVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriVision AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const BranchSelectionScreen(),
    );
  }
}
