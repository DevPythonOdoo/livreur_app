import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/livraison.dart';

/// Service de notifications locales. Surveille les nouvelles livraisons
/// par polling et affiche des notifications système.
class NotificationService {
  static final NotificationService instance = NotificationService();

  int _lastCount = 0;
  Timer? _pollTimer;
  BuildContext? _context;
  final FlutterLocalNotificationsPlugin _notif = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationService() {
    _initAsync();
  }

  Future<void> _initAsync() async {
    const android = AndroidInitializationSettings('ic_notification');
    const ios = DarwinInitializationSettings();
    await _notif.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );
    await _createChannel();
    _initialized = true;
  }

  /// Demande la permission d'afficher des notifications sur Android.
  Future<bool> requestPermission() async {
    final android = _notif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  Future<void> _createChannel() async {
    final android = _notif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      // Delete old channel then recreate to force Android to pick up new sound settings
      try {
        await android.deleteNotificationChannel('delivery_channel');
      } catch (_) {}
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          'delivery_alert',
          'Nouvelles livraisons',
          description: 'Alertes sonores pour les nouvelles livraisons',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          ledColor: Color(0xFF2563EB),
        ),
      );
    }
  }

  void _onTap(NotificationResponse response) {
    final ctx = _context;
    if (ctx != null && ctx.mounted) {
      final id = int.tryParse(response.payload ?? '');
      if (id != null) {
        Navigator.of(ctx).pushNamed('/delivery-detail', arguments: id);
      }
    }
  }

  /// Affiche une notification locale avec [id], [title] et [body].
  Future<void> showNotification(int id, String title, String body) async {
    if (!_initialized) return;
    final android = AndroidNotificationDetails(
      'delivery_alert',
      'Nouvelles livraisons',
      channelDescription: 'Notifications de nouvelles livraisons',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      playSound: true,
      enableVibration: true,
      channelShowBadge: true,
    );
    final ios = const DarwinNotificationDetails();
    final details = NotificationDetails(android: android, iOS: ios);
    await _notif.show(id, title, body, details, payload: '$id');
  }

  /// Démarre le polling toutes les 5s pour détecter les nouvelles livraisons.
  void startPolling(BuildContext context, Future<List<Livraison>> Function() fetcher) {
    _context = context;
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final livraisons = await fetcher();
        final active = livraisons.where((l) => l.isActive).toList();
        if (active.length > _lastCount && _lastCount > 0) {
          final newDeliveries = active.take(active.length - _lastCount);
          for (final liv in newDeliveries) {
            showNotification(liv.id, 'Nouvelle commande',
                '${liv.clientNom} · ${liv.ville}');
            _showSnackBar(liv);
          }
        }
        _lastCount = active.length;
      } catch (_) {}
    });
  }

  /// Arrête le polling des livraisons.
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _showSnackBar(Livraison liv) {
    final ctx = _context;
    if (ctx == null || !ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_active_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nouvelle commande !',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${liv.clientNom} · ${liv.ville}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () =>
              Navigator.of(ctx).pushNamed('/delivery-detail', arguments: liv.id),
        ),
      ),
    );
    HapticFeedback.heavyImpact();
  }
}
