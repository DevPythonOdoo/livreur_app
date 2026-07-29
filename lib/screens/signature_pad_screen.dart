import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../widgets/app_theme.dart';

class SignaturePadScreen extends StatefulWidget {
  final void Function(Uint8List? pngBytes) onSign;

  const SignaturePadScreen({super.key, required this.onSign});

  @override
  State<SignaturePadScreen> createState() => _SignaturePadScreenState();
}

class _SignaturePadScreenState extends State<SignaturePadScreen> {
  final _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
    exportPenColor: Colors.black,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_controller.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Veuillez signer'),
            backgroundColor: AppColors.secondary),
      );
      return;
    }
    final navigator = Navigator.of(context);
    final png = await _controller.toPngBytes();
    if (png != null) {
      widget.onSign(png);
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signature'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.clear(),
            tooltip: 'Effacer',
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _confirm,
            tooltip: 'Confirmer',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(Spacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Signature(
                  controller: _controller,
                  height: 300,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.lg),
            child:             Text('Signez ci-dessus',
                style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
