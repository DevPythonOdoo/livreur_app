import 'dart:math';
import 'package:flutter/material.dart';
import 'package:livreur_app/screens/phone_login_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_logo.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRememberMe();
    });
  }

  Future<void> _loadRememberMe() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.loadRememberMe();
    if (!mounted) return;
    if (auth.savedUsername != null) {
      _usernameCtrl.text = auth.savedUsername!;
      setState(() => _rememberMe = auth.rememberMe);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (_rememberMe) {
      await auth.setRememberMe(true, _usernameCtrl.text.trim());
    } else {
      await auth.setRememberMe(false, '');
    }
    final ok = await auth.login(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (ok && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 120,
                    child: AnimatedBuilder(
                      animation: _bgController,
                      builder: (_, __) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.translate(
                              offset: Offset(
                                sin(_bgController.value * pi * 2) * 20,
                                cos(_bgController.value * pi * 2) * 10,
                              ),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.orangeLight,
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: Offset(
                                cos(_bgController.value * pi * 2) * 25,
                                sin(_bgController.value * pi * 2) * 15,
                              ),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.blueLight,
                                ),
                              ),
                            ),
                            const AppLogo(size: 72, showText: false),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bienvenue sur KingDely Route',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Connectez-vous pour commencer votre tournée',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurface.withValues(alpha: 0.6),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blue.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                              TextFormField(
                                controller: _usernameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Identifiant Livreur',
                                  hintText: 'Entrez votre identifiant',
                                  prefixIcon:
                                      Icon(Icons.person_outline_rounded),
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Identifiant requis'
                                        : null,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe',
                                  hintText: 'Entrez votre mot de passe',
                                  prefixIcon:
                                      const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined),
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty
                                        ? 'Mot de passe requis'
                                        : null,
                                onFieldSubmitted: (_) => _login(),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  SizedBox(
                                    height: 40,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppColors.primaryContainer,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      onChanged: (v) =>
                                          setState(() => _rememberMe = v ?? false),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => _rememberMe = !_rememberMe),
                                    child: const Text(
                                      'Se souvenir de moi',
                                      style: TextStyle(
                                          color: AppColors.onSurfaceVariant,
                                          fontSize: 13,
                                          fontFamily: 'Inter'),
                                    ),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    'Mot de passe oublié ?',
                                    style: TextStyle(
                                      color: AppColors.primaryContainer,
                                      fontSize: 13,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Consumer<AuthProvider>(
                                builder: (_, auth, __) {
                                  if (auth.error == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    margin:
                                        const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorContainer
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.error
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.error_outline_rounded,
                                            color: AppColors.error,
                                            size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            auth.error!,
                                            style: const TextStyle(
                                                color: AppColors.error,
                                                fontSize: 13,
                                                fontFamily: 'Inter',
                                                height: 1.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              Consumer<AuthProvider>(
                                builder: (_, auth, __) => SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: FilledButton(
                                    onPressed:
                                        auth.isLoading ? null : _login,
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          AppColors.primaryContainer,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(24)),
                                    ),
                                    child: auth.isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white))
                                        : const Text(
                                            'SE CONNECTER',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                fontFamily: 'Inter',
                                                letterSpacing: 0.5),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PhoneLoginScreen()),
                      );
                    },
                    icon: const Icon(Icons.phone_android_rounded,
                        size: 18, color: AppColors.primaryContainer),
                    label: const Text(
                      'Connexion par téléphone',
                      style: TextStyle(
                        color: AppColors.primaryContainer,
                        fontFamily: 'Inter',
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Version 2.4.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurface.withValues(alpha: 0.3),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
