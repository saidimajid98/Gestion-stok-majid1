import 'package:flutter/material.dart';
import '../../services/bons_sortie_service.dart';
import '../../services/parametres_service.dart';
import '../../services/pdf_service.dart';
import '../../models/bon_sortie.dart';
import '../../models/trajet.dart';
import '../../theme.dart';
import '../../widgets/suivi_gps_card.dart';

class BonSortieDetailScreen extends StatefulWidget {
  final String bonId;
  const BonSortieDetailScreen({super.key, required this.bonId});

  @override
  State<BonSortieDetailScreen> createState() => _BonSortieDetailScreenState();
}

class _BonSortieDetailScreenState extends State<BonSortieDetailScreen> {
  final _service = BonsSortieService();
  final _paramService = ParametresService();
  BonSortie? _bon;

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
    await PdfService.imprimerBonSortie(_bon!, params);
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

  Widget _champ(String label, String valeur) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
      Text(valeur.isEmpty ? '—' : valeur, style: const TextStyle(fontWeight: FontWeight.bold)),
    ]);
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
                  _champ('CHAUFFEUR', b.chauffeurNom ?? ''),
                  _champ('CIN', b.chauffeurCin ?? ''),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _champ('VÉHICULE', b.vehiculeImmatriculation ?? ''),
                  _champ('MOTIF', b.motif ?? ''),
                ]),
                if (b.observations?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _champ('OBSERVATIONS', b.observations!),
                ],
                const Divider(height: 28),
                ...b.lignes.map((l) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Text(l.designation)),
                        Text('${l.quantite.toStringAsFixed(0)} ${l.unite}'),
                      ]),
                    )),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          SuiviGpsCard(
            bonId: b.id,
            typeBon: TypeBon.sortie,
            chauffeurNomDefaut: b.chauffeurNom,
            chauffeurCinDefaut: b.chauffeurCin,
            vehiculeDefaut: b.vehiculeImmatriculation,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _imprimer, child: const Text('Imprimer / PDF')),
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
