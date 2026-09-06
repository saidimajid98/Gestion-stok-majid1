import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../models/facture.dart';
import '../models/bon_livraison.dart';
import '../models/bon_sortie.dart';
import '../models/parametres.dart';

// Couleurs reprises du thème de l'application pour des documents cohérents.
const _ink = PdfColor.fromInt(0xFF1F2A28);
const _inkSoft = PdfColor.fromInt(0xFF5B6663);
const _accent = PdfColor.fromInt(0xFFB5502F);
const _line = PdfColor.fromInt(0xFFD7D3C7);

class PdfService {
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  static String _money(double n, String devise) =>
      '${NumberFormat('#,##0.00', 'fr_FR').format(n)} $devise';

  static pw.Widget _entete(ParametresEntreprise p, String type, String numero, DateTime date) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(p.nom.isEmpty ? 'Votre entreprise' : p.nom,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _ink)),
          pw.SizedBox(height: 4),
          if (p.adresse.isNotEmpty) pw.Text(p.adresse, style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
          if (p.telephone.isNotEmpty) pw.Text(p.telephone, style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
          if (p.ice.isNotEmpty) pw.Text('ICE : ${p.ice}', style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(type, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _accent)),
          pw.SizedBox(height: 4),
          pw.Text(numero, style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
          pw.Text(_dateFmt.format(date), style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
        ]),
      ],
    );
  }

  static pw.Widget _ligneTableHeader(List<String> colonnes) {
    return pw.Container(
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 1))),
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(children: colonnes
          .asMap()
          .entries
          .map((e) => pw.Expanded(
                flex: e.key == 0 ? 3 : 1,
                child: pw.Text(e.value,
                    textAlign: e.key == 0 ? pw.TextAlign.left : pw.TextAlign.right,
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _inkSoft)),
              ))
          .toList()),
    );
  }

  static pw.Widget _ligneRow(List<String> valeurs) {
    return pw.Container(
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5))),
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(children: valeurs
          .asMap()
          .entries
          .map((e) => pw.Expanded(
                flex: e.key == 0 ? 3 : 1,
                child: pw.Text(e.value, textAlign: e.key == 0 ? pw.TextAlign.left : pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9)),
              ))
          .toList()),
    );
  }

  // ================= FACTURE =================
  static Future<void> imprimerFacture(Facture f, ParametresEntreprise params) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _entete(params, 'Facture', f.numero, f.date),
        pw.SizedBox(height: 20),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('FACTURÉ À', style: const pw.TextStyle(fontSize: 8, color: _inkSoft)),
            pw.Text(f.clientNom, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('STATUT', style: const pw.TextStyle(fontSize: 8, color: _inkSoft)),
            pw.Text(f.statut == 'payee' ? 'Payée' : 'Impayée', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ]),
        ]),
        pw.SizedBox(height: 18),
        _ligneTableHeader(['Désignation', 'Qté', 'P.U.', 'Total']),
        ...f.lignes.map((l) => _ligneRow([
              l.designation,
              l.quantite.toStringAsFixed(2),
              _money(l.prixUnitaire, params.devise),
              _money(l.total, params.devise),
            ])),
        pw.SizedBox(height: 16),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 220,
            child: pw.Column(children: [
              _totalRow('Total HT', _money(f.totalHt, params.devise)),
              _totalRow('TVA (${f.tva.toStringAsFixed(0)}%)', _money(f.totalTva, params.devise)),
              pw.Divider(color: _line),
              _totalRow('Total TTC', _money(f.totalTtc, params.devise), gras: true),
            ]),
          ),
        ),
        pw.SizedBox(height: 24),
        pw.Text('Merci de votre confiance.', style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
      ]),
    ));
    await Printing.layoutPdf(onLayout: (_) => doc.save(), name: 'Facture_${f.numero}.pdf');
  }

  // ================= BON DE LIVRAISON =================
  static Future<void> imprimerBonLivraison(BonLivraison b, ParametresEntreprise params) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _entete(params, 'Bon de livraison', b.numero, b.date),
        pw.SizedBox(height: 20),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('CLIENT', style: const pw.TextStyle(fontSize: 8, color: _inkSoft)),
            pw.Text(b.clientNom, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('TRANSPORTEUR', style: const pw.TextStyle(fontSize: 8, color: _inkSoft)),
            pw.Text(b.transporteur?.isNotEmpty == true ? b.transporteur! : '—', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ]),
        ]),
        if (b.adresseLivraison?.isNotEmpty == true) ...[
          pw.SizedBox(height: 8),
          pw.Text('Livré à : ${b.adresseLivraison}', style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
        ],
        pw.SizedBox(height: 18),
        _ligneTableHeader(['Désignation', 'Quantité', '', '']),
        ...b.lignes.map((l) => _ligneRow([l.designation, l.quantite.toStringAsFixed(2), '', ''])),
        pw.SizedBox(height: 24),
        pw.Text('Marchandise livrée conforme à la commande.', style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
        pw.SizedBox(height: 40),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Signature transporteur', style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
          pw.Text('Signature client', style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
        ]),
      ]),
    ));
    await Printing.layoutPdf(onLayout: (_) => doc.save(), name: 'BonLivraison_${b.numero}.pdf');
  }

  // ================= BON DE SORTIE =================
  static Future<void> imprimerBonSortie(BonSortie b, ParametresEntreprise params) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _entete(params, 'Bon de sortie', b.numero, b.date),
        pw.SizedBox(height: 20),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('CHAUFFEUR', style: const pw.TextStyle(fontSize: 8, color: _inkSoft)),
            pw.Text(b.chauffeurNom?.isNotEmpty == true ? b.chauffeurNom! : '—', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text(b.chauffeurCin?.isNotEmpty == true ? 'CIN : ${b.chauffeurCin}' : '', style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('VÉHICULE', style: const pw.TextStyle(fontSize: 8, color: _inkSoft)),
            pw.Text(b.vehiculeImmatriculation?.isNotEmpty == true ? b.vehiculeImmatriculation! : '—', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ]),
        ]),
        pw.SizedBox(height: 10),
        pw.Text('Motif : ${b.motif?.isNotEmpty == true ? b.motif! : '—'}', style: const pw.TextStyle(fontSize: 10, color: _inkSoft)),
        if (b.observations?.isNotEmpty == true) pw.Text('Observations : ${b.observations}', style: const pw.TextStyle(fontSize: 10, color: _inkSoft)),
        pw.SizedBox(height: 18),
        _ligneTableHeader(['Désignation', 'Quantité', '', '']),
        ...b.lignes.map((l) => _ligneRow([l.designation, '${l.quantite.toStringAsFixed(2)} ${l.unite}', '', ''])),
        pw.SizedBox(height: 24),
        pw.Text('Bon établi pour sortie de marchandise du stock.', style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
        pw.SizedBox(height: 40),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Signature chauffeur', style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
          pw.Text('Signature responsable', style: const pw.TextStyle(fontSize: 9, color: _inkSoft)),
        ]),
      ]),
    ));
    await Printing.layoutPdf(onLayout: (_) => doc.save(), name: 'BonSortie_${b.numero}.pdf');
  }

  static pw.Widget _totalRow(String label, String valeur, {bool gras = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: pw.TextStyle(fontSize: gras ? 12 : 10, fontWeight: gras ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(valeur, style: pw.TextStyle(fontSize: gras ? 12 : 10, fontWeight: gras ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ]),
    );
  }
}
