import 'package:flutter/material.dart';
import '../services/trajets_service.dart';
import '../models/trajet.dart';
import '../theme.dart';

/// Carte "Suivi GPS" affichée sur le détail d'un bon de livraison ou de
/// sortie. Permet de démarrer/terminer un trajet et de consulter son état.
///
/// Note : l'ajout de position ci-dessous est manuel (latitude/longitude
/// saisies) pour rester indépendant de tout package tiers. Pour un
/// suivi GPS temps réel automatique, ajoutez le package `geolocator`
/// à pubspec.yaml et appelez `TrajetsService.ajouterPoint(...)` à chaque
/// nouvelle position reçue de `Geolocator.getPositionStream()`.
class SuiviGpsCard extends StatefulWidget {
  final String bonId;
  final TypeBon typeBon;
  final String? chauffeurNomDefaut;
  final String? chauffeurCinDefaut;
  final String? vehiculeDefaut;

  const SuiviGpsCard({
    super.key,
    required this.bonId,
    required this.typeBon,
    this.chauffeurNomDefaut,
    this.chauffeurCinDefaut,
    this.vehiculeDefaut,
  });

  @override
  State<SuiviGpsCard> createState() => _SuiviGpsCardState();
}

class _SuiviGpsCardState extends State<SuiviGpsCard> {
  final _service = TrajetsService();
  Trajet? _trajetActif;
  List<Trajet> _historique = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final tous = await _service.listerPourBon(widget.bonId, widget.typeBon);
    setState(() {
      _historique = tous;
      _trajetActif = tous.where((t) => t.statut == StatutTrajet.enCours).isEmpty
          ? null
          : tous.firstWhere((t) => t.statut == StatutTrajet.enCours);
      _chargement = false;
    });
  }

  Future<void> _demarrer() async {
    final nom = TextEditingController(text: widget.chauffeurNomDefaut ?? '');
    final cin = TextEditingController(text: widget.chauffeurCinDefaut ?? '');
    final vehicule = TextEditingController(text: widget.vehiculeDefaut ?? '');
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Démarrer un trajet'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nom, decoration: const InputDecoration(labelText: 'Chauffeur')),
          const SizedBox(height: 10),
          TextField(controller: cin, decoration: const InputDecoration(labelText: 'CIN')),
          const SizedBox(height: 10),
          TextField(controller: vehicule, decoration: const InputDecoration(labelText: 'Véhicule (immatriculation)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Démarrer')),
        ],
      ),
    );
    if (confirme != true) return;
    await _service.demarrer(
      bonId: widget.bonId,
      typeBon: widget.typeBon,
      chauffeurNom: nom.text.trim(),
      chauffeurCin: cin.text.trim(),
      vehiculeImmatriculation: vehicule.text.trim(),
    );
    _charger();
  }

  Future<void> _ajouterPosition() async {
    final lat = TextEditingController();
    final lng = TextEditingController();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter une position'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: lat, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Latitude')),
          const SizedBox(height: 10),
          TextField(controller: lng, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Longitude')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ajouter')),
        ],
      ),
    );
    if (confirme != true) return;
    final la = double.tryParse(lat.text.replaceAll(',', '.'));
    final lo = double.tryParse(lng.text.replaceAll(',', '.'));
    if (la == null || lo == null) return;
    await _service.ajouterPoint(_trajetActif!.id, la, lo);
    _charger();
  }

  Future<void> _terminer() async {
    final distance = TextEditingController();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terminer le trajet'),
        content: TextField(
          controller: distance,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Distance parcourue (km, optionnel)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Terminer')),
        ],
      ),
    );
    if (confirme != true) return;
    await _service.terminer(_trajetActif!.id, distanceKm: double.tryParse(distance.text.replaceAll(',', '.')));
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Suivi GPS', style: TextStyle(fontWeight: FontWeight.bold)),
            if (_trajetActif != null)
              const Chip(label: Text('En cours', style: TextStyle(fontSize: 11)), backgroundColor: AppColors.goodSoft, labelStyle: TextStyle(color: AppColors.good)),
          ]),
          const SizedBox(height: 10),
          if (_trajetActif == null)
            ElevatedButton(onPressed: _demarrer, child: const Text('Démarrer un trajet'))
          else ...[
            Text('Chauffeur : ${_trajetActif!.chauffeurNom?.isNotEmpty == true ? _trajetActif!.chauffeurNom! : '—'}'),
            Text('Véhicule : ${_trajetActif!.vehiculeImmatriculation?.isNotEmpty == true ? _trajetActif!.vehiculeImmatriculation! : '—'}'),
            Text('Départ : ${_formatDateHeure(_trajetActif!.dateDebut)}'),
            Text('Positions enregistrées : ${_trajetActif!.points.length}'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: _ajouterPosition, child: const Text('+ Position'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(onPressed: _terminer, child: const Text('Terminer'))),
            ]),
          ],
          if (_historique.where((t) => t.statut != StatutTrajet.enCours).isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Historique', style: TextStyle(fontSize: 12, color: AppColors.inkSoft, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ..._historique.where((t) => t.statut != StatutTrajet.enCours).map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(_formatDateHeure(t.dateDebut), style: const TextStyle(fontSize: 12.5)),
                    Text(
                      t.statut == StatutTrajet.termine
                          ? '${t.distanceKm?.toStringAsFixed(1) ?? '—'} km · ${t.dureeMinutes ?? '—'} min'
                          : 'Annulé',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                    ),
                  ]),
                )),
          ],
        ]),
      ),
    );
  }

  String _formatDateHeure(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
