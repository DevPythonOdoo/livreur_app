import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'app_theme.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  StreamSubscription? _subscription;
  Timer? _httpCheckTimer;
  bool _httpCheckInProgress = false;

  static const String _checkUrl = 'http://192.168.8.53:8000';
  static const Duration _httpTimeout = Duration(seconds: 4);
  static const Duration _httpCheckInterval = Duration(seconds: 20);

  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
      _startPeriodicHttpCheck();
    });
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    final hasNetwork = !results.contains(ConnectivityResult.none);
    if (hasNetwork) {
      await _verifyWithHttp();
    } else {
      final httpOk = await _tryHttp();
      _isOnline = httpOk;
      notifyListeners();
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      final hasNetwork = !results.contains(ConnectivityResult.none);
      if (hasNetwork) {
        await _verifyWithHttp();
      } else {
        final httpOk = await _tryHttp();
        if (httpOk != _isOnline) {
          _isOnline = httpOk;
          notifyListeners();
        }
      }
    });
  }

  Future<bool> _tryHttp() async {
    if (_httpCheckInProgress) return _isOnline;
    _httpCheckInProgress = true;
    try {
      final client = HttpClient();
      client.connectionTimeout = _httpTimeout;
      final request = await client.getUrl(Uri.parse(_checkUrl));
      await request.close();
      client.close();
      return true;
    } catch (_) {
      return false;
    } finally {
      _httpCheckInProgress = false;
    }
  }

  Future<void> _verifyWithHttp() async {
    final httpOk = await _tryHttp();
    if (httpOk != _isOnline) {
      _isOnline = httpOk;
      notifyListeners();
    }
  }

  void _startPeriodicHttpCheck() {
    _httpCheckTimer = Timer.periodic(_httpCheckInterval, (_) async {
      final httpOk = await _tryHttp();
      if (httpOk != _isOnline) {
        _isOnline = httpOk;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _httpCheckTimer?.cancel();
    super.dispose();
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: AppColors.error,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'Aucune connexion Internet. Certaines fonctionnalités sont indisponibles.',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class NoConnectionScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  const NoConnectionScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded,
                    size: 64, color: AppColors.error),
              ),
              const SizedBox(height: 28),
              const Text('Pas de connexion',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold,
                      color: AppColors.onSurface)),
              const SizedBox(height: 12),
              Text(
                'Cette application nécessite une connexion Internet '
                'pour fonctionner. Veuillez vérifier votre réseau.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.onSurfaceVariant, height: 1.4, fontSize: 15),
              ),
              const SizedBox(height: 32),
              if (onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
