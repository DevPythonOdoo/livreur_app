import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/livraison_provider.dart';
import '../models/livraison.dart';
import 'signature_pad_screen.dart';
import 'payment_webview_screen.dart';
import '../widgets/app_theme.dart';

class ConfirmDeliveryScreen extends StatefulWidget {
  final int livraisonId;
  final String clientName;
  const ConfirmDeliveryScreen({
    super.key,
    required this.livraisonId,
    this.clientName = '',
  });

  @override
  State<ConfirmDeliveryScreen> createState() => _ConfirmDeliveryScreenState();
}

class _ConfirmDeliveryScreenState extends State<ConfirmDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  final _picker = ImagePicker();
  File? _photoFile;
  Uint8List? _signatureBytes;
  int _tempsAttente = 0;
  bool _isLoading = false;
  bool _isClient = true;
  String? _moyenPaiement;
  bool _montantInitialise = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.clientName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LivraisonProvider>().loadDetail(widget.livraisonId);
      _showIdentityDialog();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _montantCtrl.dispose();
    super.dispose();
  }

  Future<void> _showIdentityDialog() async {
    final nom = widget.clientName.trim();
    if (nom.isEmpty) return;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: AppColors.primaryContainer),
            SizedBox(width: 10),
            Expanded(child: Text('Confirmer l\'identité',
                style: TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('M./Mme $nom est-il :',
                style: const TextStyle(fontSize: 15, color: AppColors.onSurface)),
            const SizedBox(height: Spacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, 'client'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.person_rounded),
                label: const Text('Le client lui-même',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: Spacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx, 'autre'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: AppColors.onSurface,
                  side: const BorderSide(color: AppColors.outlineVariant),
                ),
                icon: const Icon(Icons.groups_rounded),
                label: const Text('Une autre personne',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == 'client') {
      _nameCtrl.text = nom;
      _isClient = true;
    } else if (result == 'autre') {
      _nameCtrl.text = '';
      _isClient = false;
      _focusNameField();
    }
  }

  void _focusNameField() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _photoFile = File(picked.path));
    }
  }

  void _openSignaturePad() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignaturePadScreen(
          onSign: (bytes) {
            setState(() => _signatureBytes = bytes);
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = context.read<LivraisonProvider>();
    final livraison = prov.selectedLivraison;
    final aPayer = livraison?.aPayerALivraison ?? false;

    if (aPayer && (_moyenPaiement == null || _moyenPaiement!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez le moyen de paiement du client'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await prov.confirmDelivery(
      id: widget.livraisonId,
      confirmedByName: _nameCtrl.text.trim(),
      tempsAttente: _tempsAttente,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      moyenPaiement: aPayer ? _moyenPaiement : null,
      montantPaye: aPayer ? (double.tryParse(_montantCtrl.text) ?? 0) : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        final data = result['data'];
        String? paymentUrl;
        final estMobileMoney = aPayer && _moyenPaiement != 'espece';
        if (data is Map) {
          paymentUrl = data['payment_url'] as String?;
        }
        if (estMobileMoney && paymentUrl != null && paymentUrl.isNotEmpty) {
          // Paiement mobile money : ouvre la WebView intégrée (sans quitter
          // l'app), qui notifie le livreur quand le paiement est confirmé.
          final url = paymentUrl;
          final paid = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => PaymentWebviewScreen(
                paymentUrl: url,
                livraisonId: widget.livraisonId,
              ),
            ),
          );
          if (paid == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Paiement confirmé, livraison terminée !'),
                backgroundColor: AppColors.statusSuccess,
              ),
            );
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
          return;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Livraison confirmée avec succès!'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['data']?.toString() ?? 'Erreur'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildPaymentSection(Livraison livraison) {
    final moyens = livraison.moyensPaiement.isNotEmpty
        ? livraison.moyensPaiement
        : <PaiementMoyen>[
            PaiementMoyen(code: 'espece', label: 'Espèces'),
            PaiementMoyen(code: 'wave', label: 'Wave Money'),
            PaiementMoyen(code: 'orange_money', label: 'Orange Money'),
            PaiementMoyen(code: 'mtn_money', label: 'MTN Money'),
          ];

    return Card(
      color: AppColors.statusSuccess.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.statusSuccess.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payments_rounded, color: AppColors.statusSuccess),
                SizedBox(width: 8),
                Text('Paiement à la livraison',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Total à encaisser : ${livraison.commandeMontantTtc.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: Spacing.md),
            TextFormField(
              controller: _montantCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Montant encaissé *',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (v) {
                final val = double.tryParse(v ?? '');
                return (val == null || val <= 0) ? 'Montant invalide' : null;
              },
            ),
            const SizedBox(height: Spacing.md),
            const Text('Moyen de paiement choisi par le client',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: Spacing.sm),
            ...moyens.map((m) => RadioListTile<String>(
                  value: m.code,
                  groupValue: _moyenPaiement,
                  onChanged: (v) => setState(() => _moyenPaiement = v),
                  title: Text(m.label),
                  activeColor: AppColors.statusSuccess,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),
            const SizedBox(height: Spacing.xs),
            const Text(
              'Wave / Orange Money / MTN Money : paiement initié via GeniusPay, l\'application s\'ouvre après confirmation.',
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(Spacing.sm),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.check_circle_rounded,
                              size: 22, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        const Text('Confirmer la livraison',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: Spacing.lg),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.marginMobile, Spacing.xl, Spacing.marginMobile, Spacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: InkWell(
                        onTap: _openSignaturePad,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          height: _signatureBytes != null ? 180 : 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.surface,
                          ),
                          child: _signatureBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(_signatureBytes!,
                                      fit: BoxFit.contain),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(Spacing.md),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryContainer.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.draw_outlined,
                                          size: 32, color: AppColors.primaryContainer),
                                    ),
                                    const SizedBox(height: Spacing.md),
                                    const Text('Appuyez pour signer',
                                        style: TextStyle(
                                            color: AppColors.onSurface,
                                            fontWeight: FontWeight.w500)),
                                    const Text('Signature du client',
                                        style: TextStyle(
                                            fontSize: 12, color: AppColors.onSurfaceVariant)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nom du confirmateur *',
                        hintText: _isClient ? widget.clientName : 'Nom de la personne',
                        prefixIcon: const Icon(Icons.person),
                        suffixIcon: _nameCtrl.text != widget.clientName
                            ? IconButton(
                                icon: const Icon(Icons.refresh_rounded,
                                    color: AppColors.primaryContainer),
                                onPressed: () {
                                  setState(() {
                                    _nameCtrl.text = widget.clientName;
                                    _isClient = true;
                                  });
                                },
                              )
                            : null,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: Spacing.lg),
                    TextFormField(
                      initialValue: '0',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Temps d'attente (min)",
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                      onChanged: (v) => _tempsAttente = int.tryParse(v) ?? 0,
                    ),
                    const SizedBox(height: Spacing.lg),
                    Consumer<LivraisonProvider>(
                      builder: (context, prov, _) {
                        final livraison = prov.selectedLivraison;
                        if (livraison == null || !livraison.aPayerALivraison) {
                          return const SizedBox.shrink();
                        }
                        if (!_montantInitialise) {
                          _montantCtrl.text =
                              livraison.commandeMontantTtc
                                  .toStringAsFixed(2)
                                  .replaceAll('.00', '');
                          _montantInitialise = true;
                        }
                        return _buildPaymentSection(livraison);
                      },
                    ),
                    const SizedBox(height: Spacing.lg),
                    if (_photoFile != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_photoFile!,
                            height: 180, width: double.infinity, fit: BoxFit.cover),
                      ),
                    Card(
                      child: InkWell(
                        onTap: _pickPhoto,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(Spacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _photoFile != null
                                      ? Icons.camera_alt
                                      : Icons.add_a_photo,
                                  size: 28, color: AppColors.secondary),
                              ),
                              const SizedBox(height: Spacing.sm),
                              Text(
                                _photoFile != null
                                    ? 'Reprendre photo'
                                    : 'Ajouter photo (POD)',
                                style: const TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optionnel)',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 48),
                          child: Icon(Icons.notes),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xxl),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.statusSuccess,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle),
                        label: Text(
                            _isLoading ? 'Confirmation...' : 'Confirmer la livraison'),
                      ),
                    ),
                    const SizedBox(height: Spacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
