import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// État de la vérification d'authentification au démarrage.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Provider gérant l'authentification du livreur.
/// Mémorise l'état de connexion, le changement de mot de passe obligatoire
/// et la persistance du nom d'utilisateur ("Se souvenir de moi").
class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  AuthStatus _authStatus = AuthStatus.unknown;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _mustChangePassword = false;
  String? _error;
  bool _rememberMe = false;
  String? _savedUsername;

  AuthStatus get authStatus => _authStatus;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get mustChangePassword => _mustChangePassword;
  String? get error => _error;
  bool get rememberMe => _rememberMe;
  String? get savedUsername => _savedUsername;

  static const String _rememberKey = 'remember_me';
  static const String _usernameKey = 'saved_username';

  /// Charge depuis SharedPreferences le choix "Se souvenir de moi".
  Future<void> loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool(_rememberKey) ?? false;
    _savedUsername = prefs.getString(_usernameKey);
    notifyListeners();
  }

  /// Persiste le choix "Se souvenir de moi" et le nom d'utilisateur.
  Future<void> setRememberMe(bool value, String username) async {
    _rememberMe = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, value);
    if (value) {
      _savedUsername = username;
      await prefs.setString(_usernameKey, username);
    } else {
      _savedUsername = null;
      await prefs.remove(_usernameKey);
    }
    notifyListeners();
  }

  /// Demande un code OTP pour le numéro de téléphone donné.
  /// Retourne vrai si la demande a réussi.
  Future<bool> requestOtp(String telephone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final res = await _api.requestOtp(telephone);
    if (res['status'] == 200) {
      _isLoading = false;
      notifyListeners();
      return true;
    }

    final body = res['body'];
    if (body is Map) {
      _error = body['detail'] as String? ?? 'Erreur lors de l\'envoi du code';
    } else if (res['error'] != null) {
      _error = res['error'] as String;
    } else {
      _error = 'Erreur lors de l\'envoi du code';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Vérifie un code OTP et connecte le livreur.
  /// Retourne vrai si le code est correct.
  Future<bool> verifyOtp(String telephone, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final res = await _api.verifyOtp(telephone, code);
    if (res['status'] == 200) {
      _isAuthenticated = true;
      _authStatus = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    final body = res['body'];
    if (body is Map) {
      _error = body['detail'] as String? ?? 'Code incorrect';
    } else if (res['error'] != null) {
      _error = res['error'] as String;
    } else {
      _error = 'Code incorrect';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Vérifie si un token JWT existe et si le mot de passe doit être changé.
  Future<void> checkAuth() async {
    final has = await _api.hasToken();
    if (has) {
      _isAuthenticated = true;
      _authStatus = AuthStatus.authenticated;
      await _checkMustChangePassword();
    } else {
      _authStatus = AuthStatus.unauthenticated;
    }
    // Abonne le callback d'échec d'auth
    ApiService.onAuthFailure = () {
      logout();
    };
    notifyListeners();
  }

  /// Tente de connecter le livreur avec [username] et [password].
  /// Retourne vrai en cas de succès. En cas d'échec, remplit [error].
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final res = await _api.login(username, password);
    if (res['status'] == 200) {
      _isAuthenticated = true;
      _authStatus = AuthStatus.authenticated;
      _isLoading = false;
      _mustChangePassword = false;
      notifyListeners();
      await _checkMustChangePassword();
      return true;
    }

    final body = res['body'];
    if (body is Map) {
      final detail = body['detail'];
      if (detail is String && detail.isNotEmpty) {
        _error = detail;
      } else if (body.containsKey('username')) {
        final msgs = body['username'] as List;
        _error = msgs.isNotEmpty ? msgs.first.toString() : 'Identifiant invalide';
      } else if (body.containsKey('password')) {
        final msgs = body['password'] as List;
        _error = msgs.isNotEmpty ? msgs.first.toString() : 'Mot de passe invalide';
      } else {
        for (final key in body.keys) {
          final val = body[key];
          if (val is List && val.isNotEmpty) {
            _error = val.first.toString();
            break;
          }
        }
        _error ??= 'Identifiants incorrects. Vérifiez votre saisie.';
      }
    } else if (res['error'] != null) {
      _error = res['error'] as String;
    } else {
      _error = 'Identifiants incorrects. Vérifiez votre saisie.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Vérifie auprès du serveur si le changement de mot de passe est obligatoire.
  Future<void> _checkMustChangePassword() async {
    final res = await _api.get('/livreurs/me/');
    if (res['status'] == 200) {
      final body = res['body'] as Map;
      _mustChangePassword = body['must_change_password'] == true;
      notifyListeners();
    }
  }

  /// Change le mot de passe du livreur.
  /// [currentPassword] : mot de passe actuel.
  /// [newPassword] : nouveau mot de passe.
  /// Retourne vrai si le changement a réussi.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final res = await _api.post('/livreurs/changer_mdp/', {
      'ancien_mot_de_passe': currentPassword,
      'nouveau_mot_de_passe': newPassword,
      'confirmer_mot_de_passe': newPassword,
    });

    if (res['status'] == 200) {
      final body = res['body'];
      if (body is Map && body.containsKey('access')) {
        await _api.saveTokens(body['access'], body['refresh']);
      }
      _mustChangePassword = false;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    final body = res['body'];
    if (body is Map) {
      if (body.containsKey('error')) {
        _error = body['error'] as String;
      } else if (body.containsKey('ancien_mot_de_passe')) {
        final msgs = body['ancien_mot_de_passe'] as List;
        _error = msgs.isNotEmpty ? msgs.first.toString() : 'Ancien mot de passe incorrect';
      } else if (body.containsKey('nouveau_mot_de_passe')) {
        final msgs = body['nouveau_mot_de_passe'] as List;
        _error = msgs.isNotEmpty ? msgs.first.toString() : 'Nouveau mot de passe invalide';
      } else {
        for (final key in body.keys) {
          final val = body[key];
          if (val is List && val.isNotEmpty) {
            _error = val.first.toString();
            break;
          }
        }
        _error ??= 'Erreur lors du changement de mot de passe';
      }
    } else if (res['error'] != null) {
      _error = res['error'] as String;
    } else {
      _error = 'Erreur lors du changement de mot de passe';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Déconnecte le livreur : efface les tokens et réinitialise l'état.
  Future<void> logout() async {
    await _api.clearTokens();
    _isAuthenticated = false;
    _authStatus = AuthStatus.unauthenticated;
    _mustChangePassword = false;
    _error = null;
    notifyListeners();
  }
}
