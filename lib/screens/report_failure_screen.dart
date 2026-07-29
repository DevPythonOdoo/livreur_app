import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/livraison_provider.dart';
import '../widgets/app_theme.dart';

final _motifs = [
  'client_absent',
  'adresse_introuvable',
  'refus_client',
  'produit_endommage',
  'retard',
  'autre',
];

final _motifLabels = {
  'client_absent': 'Client absent',
  'adresse_introuvable': 'Adresse introuvable',
  'refus_client': 'Refus du client',
  'produit_endommage': 'Produit endommagé',
  'retard': 'Retard excessif',
  'autre': 'Autre',
};

final _motifIcons = {
  'client_absent': Icons.person_off,
  'adresse_introuvable': Icons.explore_off,
  'refus_client': Icons.thumb_down,
  'produit_endommage': Icons.inventory_2,
  'retard': Icons.timer_off,
  'autre': Icons.more_horiz,
};

class ReportFailureScreen extends StatefulWidget {
  final int livraisonId;
  const ReportFailureScreen({super.key, required this.livraisonId});

  @override
  State<ReportFailureScreen> createState() => _ReportFailureScreenState();
}

class _ReportFailureScreenState extends State<ReportFailureScreen> {
  String? _selectedMotif;
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedMotif == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un motif'),
          backgroundColor: AppColors.secondary,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final prov = context.read<LivraisonProvider>();
    final result = await prov.reportFailure(
      id: widget.livraisonId,
      motif: _selectedMotif!,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec enregistré'),
            backgroundColor: AppColors.secondary,
          ),
        );
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result['data']}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
                          child: const Icon(Icons.cancel_rounded,
                              size: 22, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        const Text('Signaler un échec',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(Spacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.cancel_rounded,
                                    size: 20, color: AppColors.error),
                              ),
                              const SizedBox(width: 10),
                              const Text('Motif de l\'échec',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface)),
                            ],
                          ),
                          const SizedBox(height: Spacing.lg),
                          Wrap(
                            spacing: Spacing.sm,
                            runSpacing: Spacing.sm,
                            children: _motifs.map((m) => ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_motifIcons[m]!,
                                      size: 18,
                                      color: _selectedMotif == m
                                          ? Colors.white
                                          : AppColors.onSurfaceVariant),
                                  const SizedBox(width: Spacing.sm),
                                  Text(_motifLabels[m]!),
                                ],
                              ),
                              selected: _selectedMotif == m,
                              selectedColor: AppColors.error,
                              backgroundColor: AppColors.error.withValues(alpha: 0.06),
                              labelStyle: TextStyle(
                                color: _selectedMotif == m
                                    ? Colors.white
                                    : AppColors.onSurface,
                              ),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              onSelected: (v) => setState(() => _selectedMotif = v ? m : null),
                            )).toList(),
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
                        ],
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
                        backgroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cancel),
                      label:
                          Text(_isLoading ? 'Enregistrement...' : "Signaler l'échec"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
