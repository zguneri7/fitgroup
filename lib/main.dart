import 'package:flutter/material.dart';
import 'package:fitgroup/ui/screens/login/login_screen.dart';
import 'package:fitgroup/ui/screens/dashboard/dashboard_screen.dart';
import 'package:fitgroup/ui/screens/register/register_screen.dart';



void main() {
  runApp(const FitGroupApp());
}

class FitGroupApp extends StatelessWidget {
  const FitGroupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      routes: {
        "/": (context) => const LoginScreen(),
        "/register": (context) => const RegisterScreen(),
        "/dashboard": (context) => const DashboardScreen(),
      },
    );
  }
}
