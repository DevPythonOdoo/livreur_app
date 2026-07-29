// cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de cache en mémoire avec persistance SharedPreferences
/// et expiration configurable (TTL).
class CacheService {
  static final CacheService _instance = CacheService._();
  factory CacheService() => _instance;
  CacheService._();

  final Map<String, _CacheEntry> _memory = {};
  static const _defaultTtl = Duration(seconds: 10);

  /// Stocke [data] avec une clé et une durée de vie optionnelle [ttl].
  Future<void> set(String key, dynamic data, {Duration? ttl}) async {
    final expiry = DateTime.now().add(ttl ?? _defaultTtl);
    _memory[key] = _CacheEntry(data, expiry);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'cache_$key', jsonEncode({'data': data, 'expiry': expiry.toIso8601String()}));
  }

  /// Récupère une entrée du cache si elle n'a pas expiré.
  dynamic get(String key) {
    final entry = _memory[key];
    if (entry != null && !entry.isExpired) return entry.data;
    return null;
  }

  /// Restaure une entrée depuis SharedPreferences vers la mémoire.
  Future<void> loadFromDisk(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cache_$key');
    if (raw == null) return;
    try {
      final parsed = jsonDecode(raw);
      final expiry = DateTime.parse(parsed['expiry']);
      if (expiry.isAfter(DateTime.now())) {
        _memory[key] = _CacheEntry(parsed['data'], expiry);
      }
    } catch (_) {}
  }

  /// Vide le cache en mémoire et dans SharedPreferences.
  Future<void> clear() async {
    _memory.clear();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_'));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  /// Vérifie si une clé est encore dans le cache et non expirée.
  bool isFresh(String key) {
    final entry = _memory[key];
    return entry != null && !entry.isExpired;
  }
}

/// Entrée individuelle du cache avec données et date d'expiration.
class _CacheEntry {
  final dynamic data;
  final DateTime expiry;
  _CacheEntry(this.data, this.expiry);
  bool get isExpired => DateTime.now().isAfter(expiry);
}
