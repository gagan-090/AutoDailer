// lib/main.dart - UPDATE TO INCLUDE FOLLOW-UP PROVIDER
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme_config.dart';
import 'providers/auth_provider.dart';
import 'providers/lead_provider.dart';
import 'providers/call_provider.dart';
import 'providers/follow_up_provider.dart'; // Add this import
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TeleCRMApp());
}

class TeleCRMApp extends StatelessWidget {
  const TeleCRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LeadProvider()),
        ChangeNotifierProvider(create: (_) => CallProvider()),
        ChangeNotifierProvider(create: (_) => FollowUpProvider()), // Add this line
      ],
      child: MaterialApp(
        title: 'TeleCRM',
        theme: ThemeConfig.lightTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}