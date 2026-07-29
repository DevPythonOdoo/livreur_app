import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_theme.dart';
import 'main_shell.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';

class DeliveryRiderScreen extends StatefulWidget {
  const DeliveryRiderScreen({super.key});

  @override
  State<DeliveryRiderScreen> createState() => _DeliveryRiderScreenState();
}

class _DeliveryRiderScreenState extends State<DeliveryRiderScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), _onContinue);
  }

  void _onContinue() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    Widget destination;
    if (auth.isAuthenticated) {
      destination = auth.mustChangePassword
          ? const ChangePasswordScreen()
          : const MainShell();
    } else {
      destination = const LoginScreen();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.3),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: const Icon(Icons.delivery_dining_rounded,
                    size: 40, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'KingDely Route',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Allons livrer nos colis !',
                style: TextStyle(
                  color: AppColors.blue.withValues(alpha: 0.6),
                  fontSize: 16,
                  letterSpacing: 2,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.orange.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
