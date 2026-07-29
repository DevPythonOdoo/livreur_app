import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ReceiptService {
  Future<bool> generateTicket({
    required String commandeNumero,
    required String clientNom,
    required String adresse,
    required String ville,
    required double montantTtc,
    required String paiement,
    DateTime? dateLivraison,
  }) async {
    final pdf = pw.Document();
    final date = dateLivraison ?? DateTime.now();
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('KING DELY',
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 2)),
            pw.SizedBox(height: 4),
            pw.Text('Ticket de livraison',
                style: pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey600)),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 6),
            _row('N° commande', commandeNumero),
            _row('Client', clientNom),
            _row('Date', formattedDate),
            _row('Adresse', adresse),
            _row('Ville', ville),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 6),
            _row('Total TTC', '${montantTtc.toStringAsFixed(0)} FCFA',
                bold: true, size: 14),
            _row('Paiement', paiement),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 1, height: 2),
            pw.SizedBox(height: 8),
            pw.Text('Merci pour votre confiance !',
                style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic)),
            pw.SizedBox(height: 4),
            pw.Text('KingDely - Livraison Express',
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey400)),
          ],
        ),
      ),
    );

    final pdfBytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ticket_$commandeNumero.pdf');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Ticket de livraison $commandeNumero',
      text: 'Ticket de livraison - KingDely',
    );
    return true;
  }

  pw.Widget _row(String label, String value,
      {bool bold = false, double size = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: size - 1,
                  color: PdfColors.grey700,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: size,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: bold ? PdfColors.black : PdfColors.grey900)),
        ],
      ),
    );
  }
}