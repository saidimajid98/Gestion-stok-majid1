import 'package:flutter/material.dart';
import '../../services/bons_livraison_service.dart';
import '../../services/parametres_service.dart';
import '../../services/pdf_service.dart';
import '../../models/bon_livraison.dart';
import '../../models/ligne_item.dart';
import '../../models/trajet.dart';
import '../../theme.dart';
import '../../widgets/suivi_gps_card.dart';
import '../factures/facture_form_screen.dart';

class BonLivraisonDetailScreen extends StatefulWidget {
  final String bonId;
  const BonLivraisonDetailScreen({super.key, required this.bonId});

  @override
  State<BonLivraisonDetailScreen> createState() => _BonLivraisonDetailScreenState();
}

class _BonLivraisonDetailScreenState extends State<BonLivraisonDetailScreen> {
  final _service = BonsLivraisonService();
  final _paramService = ParametresService();
  BonLivraison? _bon;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final b = await _service.obtenir(widget.bonId);
    setState(() => _bon = b);
  }

  Future<void> _imprimer() async {
    final params = await _paramService.obtenir();
    await PdfService.imprimerBonLivraison(_bon!, params);
  }

  Future<void> _facturer() async {
    final b = _bon!;
    final lignes = b.lignes.map((l) => LigneItem(produitId: l.produitId, designation: l.designation, quantite: l.quantite, prixUnitaire: l.prixUnitaire)).toList();
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => FactureFormScreen(clientIdInitial: b.clientId, lignesInitiales: lignes)));
  }

  Future<void> _supprimer() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce bon ?'),
        content: const Text('Les quantités seront réintégrées au stock.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirme != true) return;
    await _service.supprimer(widget.bonId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final b = _bon;
    if (b == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text('Bon ${b.numero}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('CLIENT', style: TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                    Text(b.clientNom, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('TRANSPORTEUR', style: TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                    Text(b.transporteur?.isNotEmpty == true ? b.transporteur! : '—', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                ]),
                const Divider(height: 24),
                ...b.lignes.map((l) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Text(l.designation)),
                        Text(l.quantite.toStringAsFixed(0)),
                      ]),
                    )),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          SuiviGpsCard(bonId: b.id, typeBon: TypeBon.livraison, vehiculeDefaut: b.transporteur),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: _facturer, child: const Text('Facturer'))),
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
}
