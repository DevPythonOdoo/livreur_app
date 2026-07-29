import 'dart:io';
import 'dart:async';

/// Erreur applicative avec un message adapté à l'utilisateur.
class AppError {
  final String userMessage;

  AppError._(this.userMessage);

  @override
  String toString() => userMessage;
}

/// Analyse une erreur technique et retourne un [AppError] lisible
/// par l'utilisateur (problème réseau, serveur, authentification, etc.).
AppError sanitizeError(dynamic error) {
  final tech = error.toString();
  debugLog(tech);

  if (error is FormatException &&
      (tech.contains('<!DOCTYPE HTML') ||
       tech.contains('<!DOCTYPE html'))) {
    return AppError._(
      'Erreur de communication avec le serveur. '
      'Vérifiez que le serveur est correctement configuré.',
    );
  }
  if (error is SocketException || tech.contains('SocketException')) {
    return AppError._(
      'Impossible de contacter le serveur. Vérifiez votre connexion réseau.',
    );
  }
  if (error is TimeoutException ||
      tech.contains('timed out') ||
      tech.contains('TimeoutException')) {
    return AppError._(
      'Le serveur ne répond pas. Vérifiez votre connexion et réessayez.',
    );
  }
  if (tech.contains('Connection refused') ||
      tech.contains('ConnectionRefused')) {
    return AppError._(
      'Le serveur est inaccessible. Réessayez plus tard.',
    );
  }
  if (tech.contains('HandshakeException') ||
      tech.contains('TLS') ||
      tech.contains('certificate')) {
    return AppError._(
      'Erreur de sécurité de la connexion. Contactez l\'administrateur.',
    );
  }
  if (tech.contains('HostNotFoundException') ||
      tech.contains('host not found') ||
      tech.contains('No address associated')) {
    return AppError._(
      'Adresse du serveur incorrecte. Contactez l\'administrateur.',
    );
  }
  if (tech.contains('HTTP 401') || tech.contains('Unauthorized')) {
    return AppError._(
      'Session expirée. Veuillez vous reconnecter.',
    );
  }
  if (tech.contains('HTTP 500') || tech.contains('ServerException')) {
    return AppError._(
      'Erreur serveur. Réessayez plus tard.',
    );
  }
  if (tech.contains('HTTP 429') || tech.contains('Too Many Requests')) {
    return AppError._(
      'Trop de requêtes. Patientez avant de réessayer.',
    );
  }
  return AppError._(
    'Une erreur est survenue. Veuillez réessayer.',
  );
}

/// Affiche un message de débogage formaté dans la console.
void debugLog(String message) {
  // ignore: avoid_print
  print('[MomileDebug] $message');
}
