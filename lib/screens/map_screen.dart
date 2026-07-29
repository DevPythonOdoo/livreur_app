import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/livraison_provider.dart';
import '../models/livraison.dart';
import '../widgets/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const Map<String, Map<String, dynamic>> _zones = {
    'Cocody': {
      'coords': [5.3720, -3.9800],
      'color': Color(0xFF2A5CFF),
      'icon': Icons.location_city_rounded,
    },
    'Abobo': {
      'coords': [5.4167, -4.0167],
      'color': Color(0xFF7C3AED),
      'icon': Icons.location_city_rounded,
    },
    'Yopougon': {
      'coords': [5.3333, -4.0667],
      'color': Color(0xFF059669),
      'icon': Icons.location_city_rounded,
    },
    'Marcory': {
      'coords': [5.3000, -3.9833],
      'color': Color(0xFFF59E0B),
      'icon': Icons.location_city_rounded,
    },
    'Treichville': {
      'coords': [5.3000, -4.0000],
      'color': Color(0xFFDC2626),
      'icon': Icons.location_city_rounded,
    },
    'Plateau': {
      'coords': [5.3333, -4.0167],
      'color': Color(0xFF0891B2),
      'icon': Icons.account_balance_rounded,
    },
    'Koumassi': {
      'coords': [5.2833, -3.9833],
      'color': Color(0xFFD97706),
      'icon': Icons.location_city_rounded,
    },
    'Port-Bouët': {
      'coords': [5.2500, -3.9000],
      'color': Color(0xFF6366F1),
      'icon': Icons.location_city_rounded,
    },
    'Adjamé': {
      'coords': [5.3500, -4.0167],
      'color': Color(0xFFEC4899),
      'icon': Icons.location_city_rounded,
    },
  };

  String? _currentZone;
  String? _locationError;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() { _loadingLocation = false; _locationError = 'Activez votre localisation'; });
        return;
      }
    } catch (_) {
      if (mounted) { setState(() { _loadingLocation = false; _locationError = 'Erreur localisation'; }); }
      return;
    }

    LocationPermission? permission;
    try {
      permission = await Geolocator.checkPermission();
    } catch (_) {
      if (mounted) { setState(() { _loadingLocation = false; _locationError = 'Erreur permission'; }); }
      return;
    }

    if (permission == LocationPermission.denied) {
      try {
        permission = await Geolocator.requestPermission();
      } catch (_) {
        if (mounted) { setState(() { _loadingLocation = false; _locationError = 'Erreur demande permission'; }); }
        return;
      }
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() { _loadingLocation = false; _locationError = 'Permission refusée'; });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() { _loadingLocation = false; _locationError = 'Activez dans les paramètres'; });
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 30),
        ),
      );
      if (mounted) setState(() => _currentZone = _nearestZone(pos.latitude, pos.longitude));
    } on TimeoutException {
      if (mounted) setState(() => _locationError = 'Position non disponible (délai)');
    } catch (_) {
      if (mounted) setState(() => _locationError = 'Position non disponible');
    }
    if (mounted) setState(() => _loadingLocation = false);
  }

  String? _nearestZone(double lat, double lng) {
    String? nearest;
    double minDist = double.infinity;
    for (final entry in _zones.entries) {
      final zLat = (entry.value['coords'] as List)[0] as double;
      final zLng = (entry.value['coords'] as List)[1] as double;
      final dist = (lat - zLat) * (lat - zLat) + (lng - zLng) * (lng - zLng);
      if (dist < minDist) {
        minDist = dist;
        nearest = entry.key;
      }
    }
    return nearest;
  }

  String _detectZone(Livraison liv) {
    final check = '${liv.ville} ${liv.adresse} ${liv.adresseComplete}'.toLowerCase();
    for (final name in _zones.keys) {
      if (check.contains(name.toLowerCase())) return name;
    }
    return 'Autre';
  }

  @override
  Widget build(BuildContext context) {
    final enCours = context.watch<LivraisonProvider>().livraisons
        .where((l) => l.statut == 'en_cours').toList();
    final grouped = <String, List<Livraison>>{};
    for (final l in enCours) {
      final z = _detectZone(l);
      grouped.putIfAbsent(z, () => []).add(l);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Carte des livraisons',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            onPressed: _initLocation,
            tooltip: 'Ma position',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_locationError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.error.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(_locationError!,
                      style: const TextStyle(fontSize: 12, color: AppColors.error)),
                ],
              ),
            ),
          Expanded(
            child: enCours.isEmpty && !_loadingLocation
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_rounded, size: 48, color: AppColors.outlineVariant),
                        const SizedBox(height: 12),
                        const Text('Aucune livraison en cours',
                            style: TextStyle(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _buildLocationCard(enCours.length),
                      const SizedBox(height: 16),
                      ..._zones.entries.map((entry) {
                        final list = grouped[entry.key] ?? [];
                        return _buildZoneSection(entry.key, entry.value, list);
                      }),
                      if (grouped['Autre'] != null)
                        _buildZoneSection('Autre', {
                          'color': AppColors.onSurfaceVariant,
                          'icon': Icons.help_outline_rounded,
                        }, grouped['Autre']!),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(int count) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _loadingLocation
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.navigation_rounded,
                      size: 20, color: AppColors.primaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_loadingLocation
                      ? 'Localisation...'
                      : _currentZone != null
                          ? 'Vous êtes à $_currentZone'
                          : 'Position inconnue',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface)),
                  Text(
                    '$count livraison${count > 1 ? 's' : ''} en cours',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (!_loadingLocation && _currentZone != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccess.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 12, color: AppColors.statusSuccess),
                    const SizedBox(width: 4),
                    const Text('Connecté',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.statusSuccess,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneSection(String name, Map<String, dynamic> zoneData, List<Livraison> deliveries) {
    final color = (zoneData['color'] as Color?) ?? AppColors.onSurfaceVariant;
    final icon = (zoneData['icon'] as IconData?) ?? Icons.location_on_rounded;
    final isCurrentZone = _currentZone == name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: deliveries.isNotEmpty
                      ? BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5))
                      : BorderSide.none,
                ),
              ),
              child: InkWell(
                onTap: deliveries.isEmpty ? null
                    : () => _showZoneDeliveries(name, color, deliveries),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface)),
                              if (isCurrentZone) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('ICI',
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryContainer)),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${deliveries.length} livraison${deliveries.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    if (deliveries.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${deliveries.length}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color)),
                      ),
                  ],
                ),
              ),
            ),
            if (deliveries.isNotEmpty)
              ...deliveries.take(3).map((l) => _buildMiniDelivery(l, color)),
            if (deliveries.length > 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: InkWell(
                  onTap: () => _showZoneDeliveries(name, color, deliveries),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('+${deliveries.length - 3} autres',
                          style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w500)),
                      Icon(Icons.chevron_right, size: 16, color: color),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniDelivery(Livraison liv, Color color) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/delivery-detail', arguments: liv.id),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Container(
              width: 3, height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(liv.clientNom,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: AppColors.onSurface)),
                  Text(liv.adresse,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text('${liv.commandeMontantTtc.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: AppColors.onSurface)),
          ],
        ),
      ),
    );
  }

  void _showZoneDeliveries(String name, Color color, List<Livraison> deliveries) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(width: 8),
                  Text('${deliveries.length}',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: color,
                          fontSize: 13)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: deliveries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final l = deliveries[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Text(l.clientNom.isNotEmpty ? l.clientNom[0].toUpperCase() : '?',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color)),
                    ),
                    title: Text(l.clientNom,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(l.adresse,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    trailing: Text(
                      '${l.commandeMontantTtc.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.onSurface),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/delivery-detail', arguments: l.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
