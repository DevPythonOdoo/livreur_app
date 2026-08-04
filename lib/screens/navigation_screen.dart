import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/livraison_provider.dart';
import '../widgets/app_theme.dart';

/// Couche trafic en temps réel : les serveurs publics Yandex (sans clé)
/// ont été arrêtés en 2025/2026 (`l=trf` → 404, domaine retiré). Pour
/// réactiver le trafic, une clé gratuite HERE ou TomTom est nécessaire.
/// Laissez la constante à `false` pour rester sans clé.
const bool kTrafficEnabled = false;

/// Modèle (non utilisé quand [kTrafficEnabled] est false) :
/// 'https://tile.here.com/v2/traffictiles/{scheme}/{z}/{x}/{y}/512/png?apiKey=...'
const String kTrafficUrlTemplate =
    'https://tile.maps.yandex.net/tiles?l=trf&x={x}&y={y}&z={z}&scale=1&lang=fr_FR';

/// Style d'affichage d'une carte (tuiles sans clé API).
class MapStyle {
  final String label;
  final IconData icon;
  final String url;
  final double maxZoom;
  final String attribution;
  const MapStyle({
    required this.label,
    required this.icon,
    required this.url,
    required this.maxZoom,
    required this.attribution,
  });
}

/// Vues de carte disponibles : basculables via le bouton en haut à droite.
const List<MapStyle> kMapStyles = [
  MapStyle(
    label: 'Rues',
    icon: Icons.map_rounded,
    url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    maxZoom: 19,
    attribution: '© OpenStreetMap · OSRM · Trafic © Yandex',
  ),
  MapStyle(
    label: 'Satellite',
    icon: Icons.satellite_alt_rounded,
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/'
        'World_Imagery/MapServer/tile/{z}/{y}/{x}',
    maxZoom: 19,
    attribution: '© Esri, Maxar, Earthstar Geographics',
  ),
  MapStyle(
    label: 'Topo',
    icon: Icons.terrain_rounded,
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/'
        'World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
    maxZoom: 19,
    attribution: '© Esri, OpenStreetMap contributors',
  ),
  MapStyle(
    label: 'Google',
    icon: Icons.public_rounded,
    url: 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
    maxZoom: 19,
    attribution: '© Google Maps',
  ),
];

/// Écran de navigation : positionne le livreur sur la carte, trace
/// l'itinéraire le plus court (OSRM) et affiche le trafic si une clé
/// HERE est configurée. Ne quitte jamais l'application.
class NavigationScreen extends StatefulWidget {
  final String adresse;
  final String ville;
  final int? livraisonId;
  final String? statut;
  final String? clientNom;
  const NavigationScreen({
    super.key,
    required this.adresse,
    required this.ville,
    this.livraisonId,
    this.statut,
    this.clientNom,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();

  LatLng? _driverPos;
  LatLng? _dest;
  List<LatLng> _route = [];
  double _distanceM = 0;
  int _durationS = 0;
  int _mapStyleIndex = 0;
  bool _loading = true;
  bool _loadingRoute = false;
  String? _locationError;
  String? _routeError;
  Timer? _posTimer;
  String? _statut;
  bool _actionBusy = false;

  @override
  void initState() {
    super.initState();
    _statut = widget.statut;
    _init();
    if (widget.livraisonId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStatut());
    }
  }

  Future<void> _refreshStatut() async {
    final id = widget.livraisonId;
    if (id == null) return;
    final prov = context.read<LivraisonProvider>();
    await prov.loadDetail(id);
    final liv = prov.selectedLivraison;
    if (liv != null && mounted && liv.statut != _statut) {
      setState(() => _statut = liv.statut);
    }
  }

  @override
  void dispose() {
    _posTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    await _initLocation();
    await _geocodeDest();
    if (_driverPos != null && _dest != null) {
      await _loadRoute();
    }
    if (mounted) setState(() => _loading = false);
    _posTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final pos = await _getPosition();
      if (pos != null && mounted) {
        setState(() => _driverPos = LatLng(pos.latitude, pos.longitude));
      }
    });
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
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _initLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          setState(() => _locationError = 'Activez votre localisation');
        }
        return;
      }
    } catch (_) {
      if (mounted) setState(() => _locationError = 'Erreur localisation');
      return;
    }
    final pos = await _getPosition();
    if (pos != null) {
      if (mounted) {
        setState(() => _driverPos = LatLng(pos.latitude, pos.longitude));
      }
    } else if (mounted) {
      setState(() => _locationError = 'Position non disponible');
    }
  }

  Future<void> _geocodeDest() async {
    final q = '${widget.adresse}, ${widget.ville}, Côte d\'Ivoire';
    try {
      final res = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/search?format=json&limit=1'
            '&q=${Uri.encodeQueryComponent(q)}'),
        headers: {'User-Agent': 'KingDelyRoute/1.0 (livreur_app)'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        if (data.isNotEmpty) {
          final lat = double.tryParse('${data[0]['lat']}');
          final lon = double.tryParse('${data[0]['lon']}');
          if (lat != null && lon != null) {
            if (mounted) setState(() => _dest = LatLng(lat, lon));
            return;
          }
        }
      }
      if (mounted) setState(() => _routeError = 'Adresse introuvable');
    } catch (_) {
      if (mounted) setState(() => _routeError = 'Hors connexion');
    }
  }

  /// Itinéraire le plus court via OSRM (gratuit, sans clé).
  Future<void> _loadRoute() async {
    final d = _driverPos!;
    final t = _dest!;
    setState(() {
      _loadingRoute = true;
      _routeError = null;
    });
    final url = 'https://router.project-osrm.org/route/v1/driving/'
        '${d.longitude},${d.latitude};${t.longitude},${t.latitude}'
        '?overview=full&geometries=geojson&alternatives=false';
    try {
      final res = await http.get(Uri.parse(url),
          headers: {'User-Agent': 'KingDelyRoute/1.0 (livreur_app)'});
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final r = routes.first as Map<String, dynamic>;
          final coords = (r['geometry']['coordinates'] as List)
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          if (mounted) {
            setState(() {
              _route = coords;
              _distanceM = (r['distance'] as num?)?.toDouble() ?? 0;
              _durationS = (r['duration'] as num?)?.toInt() ?? 0;
              _loadingRoute = false;
            });
            _fitRoute();
          }
          return;
        }
      }
      if (mounted) {
        setState(() {
          _routeError = 'Itinéraire introuvable';
          _loadingRoute = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _routeError = 'Itinéraire indisponible (hors connexion)';
          _loadingRoute = false;
        });
      }
    }
  }

  void _fitRoute() {
    final points = [..._route, if (_driverPos != null) _driverPos!];
    if (points.length < 2) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.fromLTRB(48, 80, 48, 160),
          ),
        );
      } catch (_) {}
    });
  }

  void _recenterOnDriver() {
    final d = _driverPos;
    if (d == null) return;
    _mapController.move(d, 17);
  }

  bool get _hasActions {
    final s = widget.livraisonId == null ? null : _statut;
    return s == 'preparation' ||
        s == 'prise_en_charge' ||
        s == 'en_cours' ||
        s == 'arrive_destination';
  }

  Future<void> _runAction(Future<bool> Function() apiCall,
      {required String doneMessage}) async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    final prov = context.read<LivraisonProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await apiCall();
    if (!mounted) return;
    setState(() => _actionBusy = false);
    if (ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(doneMessage,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ]),
          backgroundColor: AppColors.statusSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      await prov.loadDetail(widget.livraisonId!);
      final liv = prov.selectedLivraison;
      if (liv != null && mounted) setState(() => _statut = liv.statut);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            const Text('Erreur lors de la mise à jour',
                style: TextStyle(fontWeight: FontWeight.w500)),
          ]),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _startCourse() {
    final id = widget.livraisonId;
    if (id == null) return Future.value();
    final prov = context.read<LivraisonProvider>();
    return _runAction(
      () => prov.updateStatus(id, 'depart'),
      doneMessage: 'Départ enregistré',
    );
  }

  Future<void> _finishCourse() {
    final id = widget.livraisonId;
    if (id == null) return Future.value();
    final prov = context.read<LivraisonProvider>();
    return _runAction(
      () => prov.updateStatus(id, 'arrivee'),
      doneMessage: 'Arrivée enregistrée',
    );
  }

  Future<void> _abandonCourse() async {
    final id = widget.livraisonId;
    if (id == null) return;
    await Navigator.of(context).pushNamed('/report-failure', arguments: id);
    if (!mounted) return;
    setState(() => _actionBusy = false);
    await _refreshStatut();
  }

  Future<void> _openConfirmDelivery() async {
    final id = widget.livraisonId;
    if (id == null) return;
    await Navigator.of(context).pushNamed(
      '/confirm-delivery',
      arguments: {
        'id': id,
        'clientName': widget.clientNom ?? 'Client',
      },
    );
    if (!mounted) return;
    await _refreshStatut();
  }

  String _formatDistance(double m) {
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)} km';
    return '${m.round()} m';
  }

  String _formatDuration(int s) {
    final min = (s / 60).round();
    if (min < 60) return '$min min';
    final h = min ~/ 60;
    final m = min % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),
          if (_driverPos != null)
            Positioned(
              right: 12,
              bottom: 130,
              child: _mapButton(
                Icons.my_location_rounded,
                tooltip: 'Ma position',
                onTap: _recenterOnDriver,
              ),
            ),
          Positioned(
            right: 12,
            top: 8,
            child: _mapButton(
              kMapStyles[_mapStyleIndex].icon,
              tooltip: 'Vue : ${kMapStyles[_mapStyleIndex].label}',
              onTap: () => setState(() {
                _mapStyleIndex = (_mapStyleIndex + 1) % kMapStyles.length;
              }),
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                kMapStyles[_mapStyleIndex].attribution,
                style: const TextStyle(fontSize: 9, color: Colors.black54),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: _hasActions ? 72 : 0,
            child: _buildInfoCard(),
          ),
          if (_hasActions)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildActionBar(),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final dest = _dest;
    final driver = _driverPos;
    if (dest == null || driver == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_rounded,
                  size: 48, color: AppColors.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                _routeError ?? _locationError ?? 'Position indisponible',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _routeError = null;
                    _locationError = null;
                  });
                  _init();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: driver,
        initialZoom: 15,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: kMapStyles[_mapStyleIndex].url,
          userAgentPackageName: 'com.momile.livreur_app',
          maxZoom: kMapStyles[_mapStyleIndex].maxZoom,
          keepBuffer: 2,
          tileDisplay: const TileDisplay.fadeIn(),
        ),
        if (kTrafficEnabled)
          TileLayer(
            urlTemplate: kTrafficUrlTemplate,
            userAgentPackageName: 'com.momile.livreur_app',
            maxZoom: 18,
          ),
        if (_route.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _route,
                strokeWidth: 5,
                color: const Color(0xFF2563EB),
              ),
              Polyline(
                points: _route,
                strokeWidth: 2,
                color: Colors.white,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: driver,
              width: 26,
              height: 26,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            Marker(
              point: dest,
              width: 44,
              height: 44,
              child: const Icon(Icons.location_on_rounded,
                  size: 44, color: Color(0xFFEF4444)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    final s = _statut;
    final busy = _actionBusy;
    final Widget startBtn = Expanded(
      child: FilledButton.icon(
        onPressed: busy ? null : _startCourse,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: _actionBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.play_circle_rounded, size: 20),
        label: const Text('Démarrer la course',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
    final Widget arriveBtn = Expanded(
      child: FilledButton.icon(
        onPressed: _actionBusy ? null : _finishCourse,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: _actionBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.flag_rounded, size: 20),
        label: const Text('Terminer la course',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
    final Widget deliverBtn = Expanded(
      child: FilledButton.icon(
        onPressed: _actionBusy ? null : _openConfirmDelivery,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.statusSuccess,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.check_circle_rounded, size: 20),
        label: const Text('Confirmer la livraison',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
    final Widget cancelBtn = SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _actionBusy ? null : _abandonCourse,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          foregroundColor: AppColors.error,
        ),
        icon: const Icon(Icons.cancel_rounded, size: 20),
        label: Text(
          s == 'arrive_destination' ? 'Échec' : 'Annuler',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (s == 'en_cours' || s == 'arrive_destination') ...[
            cancelBtn,
            const SizedBox(width: 10),
          ],
          if (s == 'preparation' || s == 'prise_en_charge') startBtn,
          if (s == 'en_cours') arriveBtn,
          if (s == 'arrive_destination') deliverBtn,
        ],
      ),
    );
  }

  Widget _mapButton(IconData icon,
      {required String tooltip, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, size: 22, color: AppColors.onSurface),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final hasRoute = _route.length >= 2;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded,
                    size: 18, color: AppColors.primaryContainer),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.adresse,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.onSurface,
                            fontFamily: 'Inter'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(widget.ville,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              if (hasRoute) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccess.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 13, color: AppColors.statusSuccess),
                      const SizedBox(width: 4),
                      Text(_formatDuration(_durationS),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusSuccess)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.route_rounded,
                          size: 13, color: AppColors.blue),
                      const SizedBox(width: 4),
                      Text(_formatDistance(_distanceM),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blue)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (kTrafficEnabled)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.blueLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.traffic_rounded,
                      size: 15, color: AppColors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trafic en temps réel : vert = fluide, orange = ralenti, '
                      'rouge = embouteillage',
                      style: TextStyle(fontSize: 11, color: AppColors.blue),
                    ),
                  ),
                ],
            ),
          ),
          if (_loadingRoute)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(minHeight: 3),
            )
          else if (_routeError != null && _driverPos != null && _dest != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_routeError!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.statusFailed)),
            ),
        ],
      ),
    );
  }
}
