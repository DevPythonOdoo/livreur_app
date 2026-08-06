import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

/// Envoie périodiquement la position GPS du livreur au backend
/// (endpoint /livreurs/position/) pour le suivi temps réel sur le dashboard.
class LocationSender {
  static final LocationSender _instance = LocationSender._();
  factory LocationSender() => _instance;
  LocationSender._();

  final ApiService _api = ApiService();
  Timer? _timer;
  bool _running = false;

  bool get isRunning => _running;

  /// Démarre l'envoi périodique de la position (toutes les 15 secondes).
  void start({Duration interval = const Duration(seconds: 15)}) {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(interval, (_) => _sendOnce());
  }

  /// Arrête l'envoi périodique (déconnexion, échec d'auth...).
  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _sendOnce() async {
    try {
      final pos = await _getPosition();
      if (pos == null) return;
      await _api.post('/livreurs/position/', {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      });
    } catch (_) {
      // Erreur réseau silencieuse : le prochain tick réessaiera.
    }
  }

  Future<Position?> _getPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
