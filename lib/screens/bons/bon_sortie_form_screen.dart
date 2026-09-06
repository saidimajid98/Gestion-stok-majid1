import 'package:flutter/material.dart';
import '../../services/bons_sortie_service.dart';
import '../../services/produits_service.dart';
import '../../services/supabase_service.dart';
import '../../models/produit.dart';
import '../../models/ligne_item.dart';
import '../../widgets/ligne_editor.dart';

class BonSortieFormScreen extends StatefulWidget {
  const BonSortieFormScreen({super.key});

  @override
  State<BonSortieFormScreen> createState() => _BonSortieFormScreenState();
}

class _BonSortieFormScreenState extends State<BonSortieFormScreen> {
  final _service = BonsSortieService();
  final _produitsService = ProduitsService();
  final _chauffeurNom = TextEditingController();
  final _chauffeurCin = TextEditingController();
  final _vehicule = TextEditingController();
  final _motif = TextEditingController();
  final _observations = TextEditingController();

  List<Produit> _produits = [];
  DateTime _date = DateTime.now();
  final _lignes = <LigneItem>[];
  bool _chargement = true;
  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final produits = await _produitsService.lister();
    setState(() {
      _produits = produits;
      _chargement = false;
    });
  }

  Future<void> _enregistrer() async {
    final lignesValides = _lignes.where((l) => l.produitId != null && l.quantite > 0).toList();
    if (lignesValides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajoutez au moins un article valide.')));
      return;
    }
    setState(() => _enregistrement = true);
    try {
      final entrepotId = await SupabaseService.entrepotParDefautId();
      await _service.creer(
        entrepotId: entrepotId,
        date: _date,
        chauffeurNom: _chauffeurNom.text.trim(),
        chauffeurCin: _chauffeurCin.text.trim(),
        vehiculeImmatriculation: _vehicule.text.trim(),
        motif: _motif.text.trim(),
        observations: _observations.text.trim(),
        lignes: lignesValides,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau bon de sortie')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Date'),
            controller: TextEditingController(text: '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}'),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (d != null) setState(() => _date = d);
            },
          ),
          const SizedBox(height: 16),
          const Text('Chauffeur et véhicule', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _chauffeurNom, decoration: const InputDecoration(labelText: 'Nom du chauffeur'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _chauffeurCin, decoration: const InputDecoration(labelText: 'CIN'))),
          ]),
          const SizedBox(height: 12),
          TextField(controller: _vehicule, decoration: const InputDecoration(labelText: 'Immatriculation du véhicule')),
          const SizedBox(height: 16),
          TextField(controller: _motif, decoration: const InputDecoration(labelText: 'Motif (transfert, casse, échantillon…)')),
          const SizedBox(height: 12),
          TextField(controller: _observations, maxLines: 3, decoration: const InputDecoration(labelText: 'Observations (optionnel)')),
          const SizedBox(height: 16),
          LigneEditor(lignes: _lignes, produits: _produits, afficherPrix: false, onChanged: () => setState(() {})),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _enregistrement ? null : _enregistrer,
            child: _enregistrement ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Créer le bon de sortie'),
          ),
        ]),
      ),
    );
  }
}
