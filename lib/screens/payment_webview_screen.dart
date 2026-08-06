import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../providers/livraison_provider.dart';
import '../widgets/app_theme.dart';

/// Écran de paiement mobile money en WebView intégrée (sans quitter l'app).
///
/// Charge l'URL de paiement (checkout GeniusPay) dans une WebView interne.
/// Pendant l'affichage, il interroge le statut de paiement toutes les [pollInterval]
/// et, dès que la commande est marquée payée (webhook GeniusPay), notifie le
/// livreur puis referme l'écran avec un résultat de succès.
class PaymentWebviewScreen extends StatefulWidget {
  final String paymentUrl;
  final int livraisonId;

  const PaymentWebviewScreen({
    super.key,
    required this.paymentUrl,
    required this.livraisonId,
  });

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  static const Duration pollInterval = Duration(seconds: 4);

  InAppWebViewController? _webViewController;
  Timer? _pollTimer;
  bool _paymentConfirmed = false;
  bool _pageError = false;
  String _statusMessage = 'En attente du paiement du client…';
  bool _statusPaid = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(pollInterval, (_) => _checkPaymentStatus());
  }

  Future<void> _checkPaymentStatus() async {
    final prov = context.read<LivraisonProvider>();
    final status = await prov.fetchStatutPaiement(widget.livraisonId);
    if (status == null || !mounted) return;

    final statutCommande = status['commande_statut_paiement'];
    final paiement = status['paiement'];
    final statutPaiement = paiement is Map ? paiement['statut'] : null;

    // Payée si la commande est payée, ou si le dernier paiement est payé.
    final isPaid =
        statutCommande == 'payee' || statutPaiement == 'paye';

    if (isPaid && !_paymentConfirmed) {
      _paymentConfirmed = true;
      _pollTimer?.cancel();
      setState(() {
        _statusPaid = true;
        _statusMessage = 'Paiement confirmé ✓';
        _pageError = false;
      });
      // Laisse la WebView afficher l'état puis confirme via un overlay.
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) await _confirmPayment();
    }
  }

  Future<void> _confirmPayment() async {
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _closePayment() {
    if (_paymentConfirmed) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _paymentConfirmed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_paymentConfirmed) _closePayment();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paiement Mobile Money'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _closePayment,
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Container(
                  width: double.infinity,
                  color: _statusPaid
                      ? AppColors.statusSuccess.withValues(alpha: 0.12)
                      : AppColors.surfaceContainerHighest,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        _statusPaid
                            ? Icons.check_circle_rounded
                            : Icons.hourglass_top_rounded,
                        color: _statusPaid
                            ? AppColors.statusSuccess
                            : AppColors.statusPending,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusPaid
                              ? _statusMessage
                              : 'Le client paie avec son téléphone…\n'
                                  'Ne quittez pas cet écran.',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _pageError
                      ? _buildErrorState()
                      : InAppWebView(
                          initialUrlRequest: URLRequest(
                            url: WebUri(widget.paymentUrl),
                          ),
                          initialSettings: InAppWebViewSettings(
                            javaScriptEnabled: true,
                            domStorageEnabled: true,
                            supportMultipleWindows: true,
                            useWideViewPort: true,
                            mediaPlaybackRequiresUserGesture: false,
                          ),
                          onWebViewCreated: (controller) {
                            _webViewController = controller;
                          },
                          onReceivedError: (controller, request, error) {
                            if (mounted) {
                              setState(() => _pageError = true);
                            }
                          },
                        ),
                ),
              ],
            ),
            if (_paymentConfirmed)
              Positioned.fill(
                child: Container(
                  color: AppColors.surface.withValues(alpha: 0.85),
                  child: Center(
                    child: Card(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.statusSuccess,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Paiement confirmé !',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Le client a payé. Livraison terminée.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 20),
                            const CircularProgressIndicator(
                              color: AppColors.statusSuccess,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 56, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 12),
          const Text('Impossible de charger la page de paiement',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text(
            'Vérifiez la connexion, ou demandez au client de payer '
            'autrement (espèces).',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () {
                  setState(() => _pageError = false);
                  _webViewController?.reload();
                },
                child: const Text('Réessayer'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _closePayment,
                child: const Text('Fermer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}