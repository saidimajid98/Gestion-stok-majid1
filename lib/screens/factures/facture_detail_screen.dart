import 'package:flutter/material.dart';
import '../../services/factures_service.dart';
import '../../services/parametres_service.dart';
import '../../services/pdf_service.dart';
import '../../models/facture.dart';
import '../../theme.dart';

class FactureDetailScreen extends StatefulWidget {
  final String factureId;
  const FactureDetailScreen({super.key, required this.factureId});

  @override
  State<FactureDetailScreen> createState() => _FactureDetailScreenState();
}

class _FactureDetailScreenState extends State<FactureDetailScreen> {
  final _service = FacturesService();
  final _paramService = ParametresService();
  Facture? _facture;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final f = await _service.obtenir(widget.factureId);
    setState(() => _facture = f);
  }

  Future<void> _basculerStatut() async {
    final f = _facture!;
    await _service.changerStatut(f.id, f.statut == 'payee' ? 'impayee' : 'payee');
    _charger();
  }

  Future<void> _imprimer() async {
    final params = await _paramService.obtenir();
    await PdfService.imprimerFacture(_facture!, params);
  }

  Future<void> _supprimer() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette facture ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirme != true) return;
    await _service.supprimer(widget.factureId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final f = _facture;
    if (f == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text('Facture ${f.numero}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('FACTURÉ À', style: TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                    Text(f.clientNom, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('STATUT', style: TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                    Text(f.statut == 'payee' ? 'Payée' : 'Impayée',
                        style: TextStyle(fontWeight: FontWeight.bold, color: f.statut == 'payee' ? AppColors.good : AppColors.danger)),
                  ]),
                ]),
                const Divider(height: 24),
                ...f.lignes.map((l) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Text(l.designation)),
                        Text('${l.quantite.toStringAsFixed(0)} × ${l.prixUnitaire.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.inkSoft)),
                      ]),
                    )),
                const Divider(height: 24),
                _totalRow('Total HT', f.totalHt),
                _totalRow('TVA (${f.tva.toStringAsFixed(0)}%)', f.totalTva),
                _totalRow('Total TTC', f.totalTtc, gras: true),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: _basculerStatut, child: Text(f.statut == 'payee' ? 'Marquer impayée' : 'Marquer payée'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(onPressed: _imprimer, child: const Text('Imprimer / PDF'))),
          ]),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _supprimer,
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.dangerSoft)),
            child: const Text('Supprimer'),
          ),
        ]),
      ),
    );
  }

  Widget _totalRow(String label, double valeur, {bool gras = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontWeight: gras ? FontWeight.bold : FontWeight.normal, fontSize: gras ? 16 : 13.5)),
        Text(valeur.toStringAsFixed(2), style: TextStyle(fontWeight: gras ? FontWeight.bold : FontWeight.normal, fontSize: gras ? 16 : 13.5)),
      ]),
    );
  }
}
