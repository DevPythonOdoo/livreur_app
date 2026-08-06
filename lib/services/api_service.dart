import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/error_handler.dart';

/// Service HTTP centralisé pour les appels vers l'API KingDely.
/// Gère l'authentification JWT, le rafraîchissement des tokens,
/// les requêtes GET, POST et multipart.
class ApiService {
  static const String defaultBaseUrl = 'http://192.168.8.53:8000/api';
  static const String _tokenKey = 'jwt_token';
  static const String _refreshKey = 'jwt_refresh';

  String? _token;
  String? _refreshToken;

  /// Callback appelé quand l'authentification échoue (refresh invalide).
  /// Le provider d'auth doit s'abonner pour forcer la déconnexion.
  static void Function()? onAuthFailure;

  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  static const int _networkErrorStatus = 0;

  String get baseUrl => defaultBaseUrl;

  /// Construit l'URL complète pour un chemin média relatif.
  /// Exemple : '/media/livreurs/...' -> 'http://server/media/livreurs/...'
  String mediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final serverBase = defaultBaseUrl.replaceAll('/api', '');
    return '$serverBase$path';
  }

  /// Persiste les tokens JWT (access et refresh) en mémoire et SharedPreferences.
  Future<void> saveTokens(String access, String refresh) async {
    _token = access;
    _refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, access);
    await prefs.setString(_refreshKey, refresh);
  }

  /// Charge les tokens JWT depuis SharedPreferences.
  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _refreshToken = prefs.getString(_refreshKey);
  }

  /// Vérifie si un token JWT existe (chargé depuis le disque).
  Future<bool> hasToken() async {
    await loadTokens();
    return _token != null;
  }

  /// Efface les tokens JWT (déconnexion).
  Future<void> clearTokens() async {
    _token = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
  }

  /// Construit les en-têtes JSON avec le token d'authentification.
  Future<Map<String, String>> _headers() async {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  /// Construit les en-têtes multipart avec le token d'authentification.
  Future<Map<String, String>> _multipartHeaders() async {
    return {
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<dynamic> _refreshAccessToken() async {
    if (_refreshToken == null) return null;
    final url = baseUrl;
    try {
      final res = await http
          .post(
            Uri.parse('$url/auth/refresh/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': _refreshToken}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // Si rotation activée, la réponse contient un nouveau refresh token
        final newRefresh = data['refresh'] as String? ?? _refreshToken!;
        await saveTokens(data['access'], newRefresh);
        return data['access'];
      }
      // Refresh rejeté (token expiré ou blacklisté) → auth failure
      if (res.statusCode == 401) {
        await clearTokens();
        onAuthFailure?.call();
      }
    } catch (e) {
      debugLog('Refresh token failed: $e');
    }
    return null;
  }

  /// Demande un code OTP pour le numéro de téléphone.
  Future<Map<String, dynamic>> requestOtp(String telephone) async {
    final url = baseUrl;
    try {
      final res = await http
          .post(
            Uri.parse('$url/auth/request-otp/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'telephone': telephone}),
          )
          .timeout(const Duration(seconds: 10));
      return {'status': res.statusCode, 'body': jsonDecode(res.body)};
    } catch (e) {
      final appError = sanitizeError(e);
      return {'status': _networkErrorStatus, 'error': appError.userMessage};
    }
  }

  /// Vérifie un code OTP et sauvegarde les tokens JWT en cas de succès.
  Future<Map<String, dynamic>> verifyOtp(
      String telephone, String code) async {
    final url = baseUrl;
    try {
      final res = await http
          .post(
            Uri.parse('$url/auth/verify-otp/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'telephone': telephone, 'code': code}),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await saveTokens(data['access'], data['refresh']);
      }
      return {'status': res.statusCode, 'body': data};
    } catch (e) {
      final appError = sanitizeError(e);
      return {'status': _networkErrorStatus, 'error': appError.userMessage};
    }
  }

  /// Authentifie le livreur et sauvegarde les tokens JWT en cas de succès.
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = baseUrl;
    try {
      final res = await http
          .post(
            Uri.parse('$url/auth/login/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await saveTokens(data['access'], data['refresh']);
      }
      return {'status': res.statusCode, 'body': data};
    } catch (e) {
      final appError = sanitizeError(e);
      return {'status': _networkErrorStatus, 'error': appError.userMessage};
    }
  }

  /// Effectue une requête GET vers [endpoint] avec gestion du refresh token.
  Future<Map<String, dynamic>> get(String endpoint) async {
    final url = baseUrl;
    try {
      var res = await http
          .get(
            Uri.parse('$url$endpoint'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 401 && _refreshToken != null) {
        final newToken = await _refreshAccessToken();
        if (newToken != null) {
          res = await http
              .get(
                Uri.parse('$url$endpoint'),
                headers: await _headers(),
              )
              .timeout(const Duration(seconds: 10));
        }
      }
      return {'status': res.statusCode, 'body': jsonDecode(res.body)};
    } catch (e) {
      final appError = sanitizeError(e);
      return {'status': _networkErrorStatus, 'error': appError.userMessage};
    }
  }

  /// Effectue une requête POST vers [endpoint] avec [data] en JSON.
  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    final url = baseUrl;
    try {
      var res = await http
          .post(
            Uri.parse('$url$endpoint'),
            headers: await _headers(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 401 && _refreshToken != null) {
        final newToken = await _refreshAccessToken();
        if (newToken != null) {
          res = await http
              .post(
                Uri.parse('$url$endpoint'),
                headers: await _headers(),
                body: jsonEncode(data),
              )
              .timeout(const Duration(seconds: 10));
        }
      }
      return {'status': res.statusCode, 'body': jsonDecode(res.body)};
    } catch (e) {
      final appError = sanitizeError(e);
      return {'status': _networkErrorStatus, 'error': appError.userMessage};
    }
  }

  /// Effectue une requête POST multipart avec [fields] et [files].
  Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    List<MapEntry<String, File>>? files,
  }) async {
    final url = baseUrl;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$url$endpoint'),
      );
      request.headers.addAll(await _multipartHeaders());
      if (fields != null) request.fields.addAll(fields);
      if (files != null) {
        for (final f in files) {
          request.files.add(
            await http.MultipartFile.fromPath(f.key, f.value.path),
          );
        }
      }

      var streamed = await request.send().timeout(const Duration(seconds: 15));
      var res = await http.Response.fromStream(streamed);

      if (res.statusCode == 401 && _refreshToken != null) {
        final newToken = await _refreshAccessToken();
        if (newToken != null) {
          request.headers['Authorization'] = 'Bearer $_token';
          streamed = await request.send().timeout(const Duration(seconds: 15));
          res = await http.Response.fromStream(streamed);
        }
      }
      return {'status': res.statusCode, 'body': jsonDecode(res.body)};
    } catch (e) {
      final appError = sanitizeError(e);
      return {'status': _networkErrorStatus, 'error': appError.userMessage};
    }
  }
}
