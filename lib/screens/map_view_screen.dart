import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../widgets/app_theme.dart';

class MapViewArgs {
  final String adresse;
  final String ville;
  final int? livraisonId;
  final String? statut;
  final String? clientNom;
  const MapViewArgs({
    required this.adresse,
    required this.ville,
    this.livraisonId,
    this.statut,
    this.clientNom,
  });
}

/// Carte embarquée (OpenStreetMap) de l'adresse de livraison.
/// Ne quitte jamais l'application : aucun lancement d'app ou de lien externe.
class MapViewScreen extends StatefulWidget {
  final String adresse;
  final String ville;
  const MapViewScreen({super.key, required this.adresse, required this.ville});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final MapController _mapController = MapController();
  LatLng? _dest;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _geocode();
  }

  Future<void> _geocode() async {
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
            setState(() {
              _dest = LatLng(lat, lon);
              _loading = false;
            });
            return;
          }
        }
      }
      setState(() {
        _error = 'Adresse introuvable sur la carte';
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Carte indisponible (hors connexion)';
        _loading = false;
      });
    }
  }

  void _copyAddress() {
    final adr = '${widget.adresse}, ${widget.ville}, Côte d\'Ivoire';
    // ignore: depend_on_referenced_packages
    Clipboard.setData(ClipboardData(text: adr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Adresse copiée'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
      _dest = null;
    });
    _geocode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adresse de livraison'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),
          if (_dest != null)
            Positioned(
              right: 12,
              bottom: 12,
              child: Column(
                children: [
                  _mapButton(Icons.add_rounded, () {
                    final z = _mapController.camera.zoom + 1;
                    if (z <= 18) _mapController.move(_dest!, z);
                  }),
                  const SizedBox(height: 8),
                  _mapButton(Icons.remove_rounded, () {
                    final z = _mapController.camera.zoom - 1;
                    if (z >= 3) _mapController.move(_dest!, z);
                  }),
                ],
              ),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _buildAddressCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_dest == null) {
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
                _error ?? 'Position indisponible',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _retry,
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
        initialCenter: _dest!,
        initialZoom: 16,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.momile.livreur_app',
          maxZoom: 18,
          keepBuffer: 2,
          tileDisplay: const TileDisplay.fadeIn(),
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _dest!,
              width: 44,
              height: 44,
              child: const Icon(Icons.location_on_rounded,
                  size: 44, color: Color(0xFFEF4444)),
            ),
          ],
        ),
        const SimpleAttributionWidget(
          source: Text('© OpenStreetMap'),
        ),
      ],
    );
  }

  Widget _mapButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 22, color: AppColors.onSurface),
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_on_rounded,
                  size: 20, color: AppColors.primaryContainer),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 2),
                  Text(widget.ville,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copier l\'adresse',
              icon: const Icon(Icons.content_copy_rounded,
                  size: 20, color: AppColors.onSurfaceVariant),
              onPressed: _copyAddress,
            ),
          ],
        ),
      ),
    );
  }
}
