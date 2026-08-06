import 'dart:async';
import 'package:flutter/material.dart';
import '../models/livraison.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

/// Provider gérant le chargement, le filtrage et la mise à jour
/// des livraisons, ainsi que les statistiques associées.
/// Rafraîchit automatiquement les données toutes les 8s.
class LivraisonProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final CacheService _cache = CacheService();
  List<Livraison> _livraisons = [];
  Livraison? _selectedLivraison;
  DeliveryStats? _stats;
  bool _isLoading = false;
  String? _error;
  String _filter = '';
  Timer? _refreshTimer;
  Timer? _agendaRefreshTimer;

  // Données de l'agenda / planification
  Map<String, List<Livraison>> _planningDeliveries = {};
  Map<String, int> _planningCounts = {};
  DateTime _selectedAgendaDate = DateTime.now();
  bool _isPlanningLoading = false;
  String? _planningError;

  List<Livraison> get livraisons {
    if (_filter.isEmpty) return _livraisons;
    if (_filter == 'retard') {
      return _livraisons.where((l) => l.enRetard).toList();
    }
    return _livraisons.where((l) => l.statut == _filter).toList();
  }
  Livraison? get selectedLivraison => _selectedLivraison;
  DeliveryStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filter => _filter;

  /// Retourne les livraisons d'une date spécifique (format YYYY-MM-DD).
  List<Livraison> getDeliveriesForDate(DateTime date) {
    final key = _fmtDate(date);
    return _planningDeliveries[key] ?? [];
  }

  /// Retourne le nombre de livraisons pour une date.
  int getCountForDate(DateTime date) {
    final key = _fmtDate(date);
    return _planningCounts[key] ?? 0;
  }

  /// Retourne le nombre de livraisons pour une date avec un statut donné.
  int getCountForDateWithStatus(DateTime date, String statut) {
    final key = _fmtDate(date);
    final deliveries = _planningDeliveries[key];
    if (deliveries == null) return 0;
    return deliveries.where((d) => d.statut == statut).length;
  }

  /// Liste des dates disponibles dans le cache de planification.
  Set<String> get planningDates => _planningDeliveries.keys.toSet();

  DateTime get selectedAgendaDate => _selectedAgendaDate;
  bool get isPlanningLoading => _isPlanningLoading;
  String? get planningError => _planningError;

  /// Formate une date en chaîne YYYY-MM-DD.
  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}'
      '-${d.month.toString().padLeft(2, '0')}'
      '-${d.day.toString().padLeft(2, '0')}';

  /// Extrait la clé YYYY-MM-DD d'une chaîne ISO (ex: "2026-06-19T10:30:00+00:00").
  String _extractDateKey(String isoDate) =>
      isoDate.length >= 10 ? isoDate.substring(0, 10) : isoDate;

  /// Applique un filtre par statut sur la liste des livraisons.
  void setFilter(String f) { _filter = f; notifyListeners(); }

  /// Définit la date sélectionnée dans l'agenda.
  void selectAgendaDate(DateTime date) {
    _selectedAgendaDate = date;
    notifyListeners();
  }

  /// Démarre le rafraîchissement automatique toutes les 8s.
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _silentRefresh();
    });
  }

  /// Arrête le rafraîchissement automatique.
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _silentRefresh() async {
    final res = await _api.get('/livraisons/');
    if (res['status'] == 200) {
      final body = res['body'];
      List items;
      if (body is Map) {
        items = body['results'] as List;
      } else if (body is List) {
        items = body;
      } else {
        items = [];
      }
      final parsed = items
          .map((j) => Livraison.fromJson(j as Map<String, dynamic>))
          .toList();
      parsed.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
      // N'informe l'UI que si les données ont réellement changé
      // (évite de rebuilder tous les écrans à chaque tick de 8 s).
      if (!_sameDeliveries(_livraisons, parsed)) {
        _livraisons = parsed;
        notifyListeners();
      } else {
        _livraisons = parsed;
      }
      _cache.set('livraisons', items, ttl: const Duration(seconds: 10));
      _silentStatsRefresh();
    }
  }

  Future<void> _silentStatsRefresh() async {
    final res = await _api.get('/livraisons/stats/');
    if (res['status'] == 200) {
      final stats = DeliveryStats.fromJson(res['body']);
      if (!_sameStats(_stats, stats)) {
        _stats = stats;
        notifyListeners();
      } else {
        _stats = stats;
      }
      _cache.set('stats', res['body'], ttl: const Duration(seconds: 5));
    }
  }

  /// True si deux listes triées de livraisons sont identiques (id, statut, date).
  bool _sameDeliveries(List<Livraison> a, List<Livraison> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].statut != b[i].statut ||
          a[i].dateCreation != b[i].dateCreation) {
        return false;
      }
    }
    return true;
  }

  /// True si deux statistiques ont les mêmes valeurs affichées.
  bool _sameStats(DeliveryStats? a, DeliveryStats? b) {
    if (a == null || b == null) return a == b;
    return a.aujourdHui == b.aujourdHui &&
        a.enCours == b.enCours &&
        a.livrees == b.livrees &&
        a.echecs == b.echecs &&
        a.enRetard == b.enRetard;
  }

  /// Charge la liste des livraisons depuis le cache puis l'API.
  Future<void> loadLivraisons() async {
    _error = null;

    final cached = _cache.get('livraisons');
    if (cached != null) {
      _livraisons = (cached as List)
          .map((j) => Livraison.fromJson(j as Map<String, dynamic>))
          .toList();
      _livraisons.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
      notifyListeners();
    }

    _isLoading = true;
    notifyListeners();

    final res = await _api.get('/livraisons/');
    if (res['status'] == 200) {
      final body = res['body'];
      List items;
      if (body is Map) {
        items = body['results'] as List;
      } else if (body is List) {
        items = body;
      } else {
        items = [];
      }
      _livraisons = items
          .map((j) => Livraison.fromJson(j as Map<String, dynamic>))
          .toList();
      _livraisons.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
      _cache.set('livraisons', items, ttl: const Duration(seconds: 10));
    } else if (cached == null) {
      _error = res['error'] as String? ?? 'Erreur de chargement';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Charge le détail d'une livraison par son [id] (cache puis API).
  Future<void> loadDetail(int id) async {
    _error = null;

    final cached = _cache.get('detail_$id');
    if (cached != null) {
      _selectedLivraison = Livraison.fromJson(cached as Map<String, dynamic>);
      notifyListeners();
    }

    _isLoading = true;
    notifyListeners();

    final res = await _api.get('/livraisons/$id/');
    if (res['status'] == 200) {
      _selectedLivraison = Livraison.fromJson(res['body']);
      _cache.set('detail_$id', res['body'], ttl: const Duration(seconds: 10));
    } else if (cached == null) {
      _error = res['error'] as String? ?? 'Erreur de chargement';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Charge les statistiques depuis le cache puis l'API.
  Future<void> loadStats() async {
    final cached = _cache.get('stats');
    if (cached != null) {
      _stats = DeliveryStats.fromJson(cached as Map<String, dynamic>);
      notifyListeners();
    }

    final res = await _api.get('/livraisons/stats/');
    if (res['status'] == 200) {
      _stats = DeliveryStats.fromJson(res['body']);
      _cache.set('stats', res['body'], ttl: const Duration(seconds: 5));
      notifyListeners();
    } else if (cached == null && res['error'] != null) {
      _error = res['error'] as String?;
      notifyListeners();
    }
  }

  /// Met à jour le statut d'une livraison (ex: prise_en_charge, depart, arrivee).
  Future<bool> updateStatus(int id, String action) async {
    final res = await _api.post('/livraisons/$id/$action/', {});
    if (res['status'] == 200) {
      _cache.clear();
      loadLivraisons();
      loadStats();
      return true;
    }
    return false;
  }

  /// Confirme la livraison avec le nom du client, le temps d'attente, des notes
  /// et, si la commande est à payer à la livraison, le moyen de paiement choisi
  /// par le client (espece, wave, orange_money, mtn_money) et le montant encaissé.
  Future<Map<String, dynamic>> confirmDelivery({
    required int id,
    required String confirmedByName,
    int tempsAttente = 0,
    String? notes,
    String? moyenPaiement,
    double? montantPaye,
  }) async {
    final res = await _api.post('/livraisons/$id/livrer/', {
      'confirmed_by_name': confirmedByName,
      'temps_attente': tempsAttente,
      if (notes != null) 'notes': notes,
      if (moyenPaiement != null && moyenPaiement.isNotEmpty)
        'moyen_paiement': moyenPaiement,
      if (montantPaye != null && montantPaye > 0)
        'montant_paye': montantPaye.toStringAsFixed(2),
    });
    if (res['status'] == 200) {
      _cache.clear();
      loadLivraisons();
      loadStats();
      return {'success': true, 'data': res['body']};
    }
    return {
      'success': false,
      'data': res['error'] as String? ?? 'Erreur lors de la confirmation',
    };
  }

  /// Signale un échec de livraison avec un motif et des notes optionnelles.
  Future<Map<String, dynamic>> reportFailure({
    required int id,
    required String motif,
    String? notes,
  }) async {
    final res = await _api.post('/livraisons/$id/echec/', {
      'motif_echec': motif,
      if (notes != null) 'notes': notes,
    });
    if (res['status'] == 200) {
      _cache.clear();
      loadLivraisons();
      loadStats();
      return {'success': true, 'data': res['body']};
    }
    return {
      'success': false,
      'data': res['error'] as String? ?? 'Erreur lors du signalement',
    };
  }

  /// Charge les livraisons pour une plage de dates (pour l'agenda).
  Future<void> loadPlanning(DateTime start, DateTime end) async {
    _isPlanningLoading = true;
    _planningError = null;
    notifyListeners();

    final startStr = _fmtDate(start);
    final endStr = _fmtDate(end);
    final res = await _api.get(
      '/livraisons/?date_min=$startStr&date_max=$endStr',
    );

    if (res['status'] == 200) {
      final body = res['body'];
      List items;
      if (body is Map) {
        items = body['results'] as List;
      } else if (body is List) {
        items = body;
      } else {
        items = [];
      }

      final parsed =
          items.map((j) => Livraison.fromJson(j as Map<String, dynamic>)).toList();

      // Grouper par date
      final Map<String, List<Livraison>> grouped = {};
      final Map<String, int> counts = {};
      for (final l in parsed) {
        final dateKey = _extractDateKey(l.dateCreation);
        grouped.putIfAbsent(dateKey, () => []).add(l);
        counts[dateKey] = (counts[dateKey] ?? 0) + 1;
      }

      _planningDeliveries = grouped;
      _planningCounts = counts;
      _planningError = null;
    } else {
      _planningError = res['error'] as String? ?? 'Erreur de chargement';
    }

    _isPlanningLoading = false;
    notifyListeners();
  }

  /// Charge l'historique complet des livraisons (pour l'agenda).
  Future<void> loadAllDeliveries() async {
    _isPlanningLoading = true;
    _planningError = null;
    notifyListeners();

    final res = await _api.get('/livraisons/?all=true');

    if (res['status'] == 200) {
      final body = res['body'];
      List items;
      if (body is Map) {
        items = body['results'] as List;
      } else if (body is List) {
        items = body;
      } else {
        items = [];
      }

      final parsed =
          items.map((j) => Livraison.fromJson(j as Map<String, dynamic>)).toList();

      final Map<String, List<Livraison>> grouped = {};
      final Map<String, int> counts = {};
      for (final l in parsed) {
        final dateKey = _extractDateKey(l.dateCreation);
        grouped.putIfAbsent(dateKey, () => []).add(l);
        counts[dateKey] = (counts[dateKey] ?? 0) + 1;
      }

      _planningDeliveries = grouped;
      _planningCounts = counts;
      _planningError = null;
    } else {
      _planningError = res['error'] as String? ?? 'Erreur de chargement';
    }

    _isPlanningLoading = false;
    notifyListeners();
  }

  /// Interroge le statut de paiement de la commande (léger, pour le polling
  /// pendant le paiement mobile money). Retourne le body JSON si succès.
  Future<Map<String, dynamic>?> fetchStatutPaiement(int livraisonId) async {
    final res = await _api.get('/livraisons/$livraisonId/statut_paiement/');
    if (res['status'] == 200 && res['body'] is Map) {
      return res['body'] as Map<String, dynamic>;
    }
    return null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _agendaRefreshTimer?.cancel();
    super.dispose();
  }
}
