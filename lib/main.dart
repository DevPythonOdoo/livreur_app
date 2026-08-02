import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/livraison_provider.dart';
import 'widgets/app_theme.dart';
import 'widgets/connectivity.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/phone_login_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/delivery_detail_screen.dart';
import 'screens/confirm_delivery_screen.dart';
import 'screens/report_failure_screen.dart';
import 'screens/map_view_screen.dart';
import 'screens/navigation_screen.dart';
import 'screens/history_screen.dart';
import 'screens/planning_screen.dart';
import 'screens/disconnect_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_screen.dart';
import 'screens/about_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr', null);
  Intl.defaultLocale = 'fr';
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LivraisonProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: const KingDelyRouteApp(),
    ),
  );
}

class KingDelyRouteApp extends StatelessWidget {
  const KingDelyRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KingDely Route',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/delivery-detail':
            final id = settings.arguments as int;
            return MaterialPageRoute(
              builder: (_) => DeliveryDetailScreen(livraisonId: id),
            );
          case '/confirm-delivery':
            final args = settings.arguments as Map<String, dynamic>;
            final id = args['id'] as int;
            final clientName = args['clientName'] as String? ?? '';
            return MaterialPageRoute(
              builder: (_) =>
                  ConfirmDeliveryScreen(livraisonId: id, clientName: clientName),
            );
          case '/report-failure':
            final id = settings.arguments as int;
            return MaterialPageRoute(
              builder: (_) => ReportFailureScreen(livraisonId: id),
            );
          case '/map-view':
            final args = settings.arguments as MapViewArgs;
            return MaterialPageRoute(
              builder: (_) =>
                  MapViewScreen(adresse: args.adresse, ville: args.ville),
            );
          case '/navigation':
            final args = settings.arguments as MapViewArgs;
            return MaterialPageRoute(
              builder: (_) =>
                  NavigationScreen(adresse: args.adresse, ville: args.ville),
            );
          case '/phone-login':
            return MaterialPageRoute(
              builder: (_) => const PhoneLoginScreen(),
            );
          case '/otp-verification':
            final telephone = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(telephone: telephone),
            );
          case '/change-password':
            return MaterialPageRoute(
              builder: (_) => const ChangePasswordScreen(),
            );
          case '/history':
            return MaterialPageRoute(
              builder: (_) => const HistoryScreen(),
            );
          case '/planning':
            return MaterialPageRoute(
              builder: (_) => const PlanningScreen(),
            );
          case '/disconnect':
            return MaterialPageRoute(
              builder: (_) => const DisconnectScreen(),
            );
          case '/settings':
            return MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
            );
          case '/help':
            return MaterialPageRoute(
              builder: (_) => const HelpScreen(),
            );
          case '/about':
            return MaterialPageRoute(
              builder: (_) => const AboutScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );
        }
      },
    );
  }
}
