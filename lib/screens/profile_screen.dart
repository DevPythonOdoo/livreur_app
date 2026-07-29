import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final res = await ApiService().get('/livreurs/me/');
    if (!mounted) return;
    if (res['status'] == 200) {
      _profile = res['body'];
      _prenomCtrl.text = _profile?['prenom'] ?? '';
      _nomCtrl.text = _profile?['nom'] ?? '';
      _telCtrl.text = _profile?['telephone'] ?? '';
    }
    _isLoading = false;
    if (mounted) setState(() {});
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      final res = await ApiService().postMultipart(
        '/livreurs/me/',
        fields: {'_method': 'PATCH'},
        files: [MapEntry('photo_profil', File(picked.path))],
      );
      if (res['status'] == 200) {
        await _loadProfile();
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final res = await ApiService().post('/livreurs/me/', {
      '_method': 'PATCH',
      'nom': _nomCtrl.text.trim(),
      'prenom': _prenomCtrl.text.trim(),
      'telephone': _telCtrl.text.trim(),
    });
    if (res['status'] == 200) {
      await _loadProfile();
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profil mis à jour'),
            backgroundColor: AppColors.statusSuccess),
      );
    }
  }

  Future<void> _toggleDisponibilite(bool value) async {
    await ApiService().post('/livreurs/me/', {
      '_method': 'PATCH',
      'statut': value ? 'disponible' : 'occupe',
    });
    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Profil',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontFamily: 'Inter')),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
        body: const Center(
            child: CircularProgressIndicator(
                color: AppColors.primaryContainer)),
      );
    }

    final photoUrl = _profile?['photo_profil'] as String?;
    final prenom = _profile?['prenom'] as String? ?? '';
    final nom = _profile?['nom'] as String? ?? '';
    final email = _profile?['email'] as String? ?? '';
    final telephone = _profile?['telephone'] as String? ?? '';
    final vehicule = _profile?['vehicule'] as String? ?? '';
    final plaque = _profile?['plaque_immatriculation'] as String? ?? '';
    final dispo = _profile?['statut'] == 'disponible';
    final membreDepuis = _profile?['date_creation'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.orange,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded,
                    color: Colors.white),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.close : Icons.edit_outlined,
                  color: Colors.white,
                ),
                onPressed: () =>
                    setState(() => _isEditing = !_isEditing),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Spacer(),
                    GestureDetector(
                      onTap: _isEditing ? _pickPhoto : null,
                      child: GradientCircleAvatar(
                        radius: 44,
                        imageUrl: photoUrl != null
                            ? ApiService().mediaUrl(photoUrl)
                            : null,
                        initials:
                            '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}',
                        showOnlineDot: dispo,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$prenom $nom',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter')),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.verified_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ],
                    ),
                    Text(
                      'Livreur',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontFamily: 'Inter'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          // Performance card
          SliverToBoxAdapter(
            child: _buildPerformanceCard(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.marginMobile, 16, Spacing.marginMobile, 0),
              child: Column(
                children: [
                  if (_isEditing) _buildEditForm(),
                  _buildSectionAccent('Disponibilite'),
                  _buildDisponibiliteToggle(dispo),
                  const SizedBox(height: 16),
                  _buildSectionAccent('Informations personnelles'),
                  _buildInfoSection(
                      email, telephone, vehicule, plaque),
                  const SizedBox(height: 16),
                  _buildSectionAccent('Securite'),
                  _buildSecuriteSection(),
                  const SizedBox(height: 16),
                  _buildSectionAccent('Compte'),
                  _buildDeconnexionSection(),
                  if (membreDepuis.isNotEmpty)
                    _buildMembreDepuis(membreDepuis),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
    final noteRaw = _profile?['note_moyenne'];
    String noteValue;
    if (noteRaw is num) {
      noteValue = noteRaw.toStringAsFixed(1);
    } else if (noteRaw is String) {
      final parsed = double.tryParse(noteRaw);
      noteValue = parsed != null ? parsed.toStringAsFixed(1) : noteRaw;
    } else {
      noteValue = '-';
    }
    final totalRaw = _profile?['total_livraisons'];
    final totalStr =
        totalRaw is num ? totalRaw.toString() : totalRaw is String ? totalRaw : '0';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.marginMobile, 16, Spacing.marginMobile, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Performance',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.blue,
                        fontFamily: 'Inter')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(totalStr,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.orange,
                              fontFamily: 'Inter',
                              letterSpacing: -0.01)),
                      Text('Livraisons',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                              fontFamily: 'Inter')),
                    ],
                  ),
                ),
                Container(
                    width: 1,
                    height: 40,
                    color: AppColors.outlineVariant),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(noteValue,
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.statusPending,
                                  fontFamily: 'Inter',
                                  letterSpacing: -0.01)),
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded,
                              color: AppColors.statusPending, size: 20),
                        ],
                      ),
                      Text('Note',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                              fontFamily: 'Inter')),
                    ],
                  ),
                ),
                Container(
                    width: 1,
                    height: 40,
                    color: AppColors.outlineVariant),
                Expanded(
                  child: Column(
                    children: [
                      Text('+12%',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.statusSuccess,
                              fontFamily: 'Inter',
                              letterSpacing: -0.01)),
                      Text('Tendance',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                              fontFamily: 'Inter')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionAccent(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue,
                  fontFamily: 'Inter')),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Modifier le profil',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                    fontFamily: 'Inter')),
            const SizedBox(height: 16),
            TextFormField(
              controller: _prenomCtrl,
              decoration: const InputDecoration(labelText: 'Prénom'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nomCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telCtrl,
              decoration: const InputDecoration(labelText: 'Téléphone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check, size: 20),
                label: const Text('Enregistrer',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontFamily: 'Inter')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String email, String tel,
      String vehicule, String plaque) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoItem(Icons.email_outlined, 'Email', email),
          const Divider(height: 24),
          _infoItem(Icons.phone_outlined, 'Telephone', tel),
          if (vehicule.isNotEmpty || plaque.isNotEmpty) ...[
            const Divider(height: 24),
            if (vehicule.isNotEmpty)
              _infoItem(
                  Icons.directions_car_outlined, 'Vehicule', vehicule),
            if (vehicule.isNotEmpty && plaque.isNotEmpty)
              const SizedBox(height: 8),
            if (plaque.isNotEmpty)
              _infoItem(Icons.confirmation_number_outlined,
                  'Plaque', plaque),
          ],
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryContainer),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurface.withValues(alpha: 0.5),
                    fontFamily: 'Inter')),
            const SizedBox(height: 2),
            Text(
              value.isNotEmpty ? value : 'Non renseigné',
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: value.isNotEmpty
                      ? AppColors.onSurface
                      : AppColors.onSurface.withValues(alpha: 0.3),
                  fontFamily: 'Inter'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisponibiliteToggle(bool dispo) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (dispo ? AppColors.stateOnline : AppColors.stateOffline)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  dispo ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  size: 20,
                  color: dispo
                      ? AppColors.stateOnline
                      : AppColors.stateOffline,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Disponibilité',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                          fontFamily: 'Inter')),
                  Text(
                    dispo ? 'Vous êtes en ligne' : 'Vous êtes hors ligne',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurface.withValues(alpha: 0.5),
                        fontFamily: 'Inter'),
                  ),
                ],
              ),
            ],
          ),
          Switch.adaptive(
            value: dispo,
            activeColor: AppColors.stateOnline,
            onChanged: _toggleDisponibilite,
          ),
        ],
      ),
    );
  }

  Widget _buildSecuriteSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/change-password'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.orangeLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      size: 20, color: AppColors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mot de passe',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blue,
                              fontFamily: 'Inter')),
                      Text('Changer votre mot de passe',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                              fontFamily: 'Inter')),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.onSurface.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeconnexionSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final confirm =
                await Navigator.pushNamed(context, '/disconnect');
            if (confirm == true && mounted) {
              widget.onLogout?.call();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.statusFailed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      size: 20, color: AppColors.statusFailed),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Deconnexion',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.statusFailed,
                              fontFamily: 'Inter')),
                      Text('Se deconnecter de l\'application',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                              fontFamily: 'Inter')),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.onSurface.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMembreDepuis(String date) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today,
                size: 14,
                color: AppColors.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text('Membre depuis le $date',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurface.withValues(alpha: 0.5),
                    fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }
}
