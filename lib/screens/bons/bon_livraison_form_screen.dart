import 'package:flutter/material.dart';
import '../../services/bons_livraison_service.dart';
import '../../services/produits_service.dart';
import '../../services/clients_service.dart';
import '../../services/supabase_service.dart';
import '../../models/produit.dart';
import '../../models/client.dart';
import '../../models/ligne_item.dart';
import '../../widgets/ligne_editor.dart';

class BonLivraisonFormScreen extends StatefulWidget {
  final String? clientIdInitial;
  final List<LigneItem>? lignesInitiales;
  const BonLivraisonFormScreen({super.key, this.clientIdInitial, this.lignesInitiales});

  @override
  State<BonLivraisonFormScreen> createState() => _BonLivraisonFormScreenState();
}

class _BonLivraisonFormScreenState extends State<BonLivraisonFormScreen> {
  final _service = BonsLivraisonService();
  final _produitsService = ProduitsService();
  final _clientsService = ClientsService();
  final _transporteur = TextEditingController();
  final _adresse = TextEditingController();

  List<Produit> _produits = [];
  List<Client> _clients = [];
  String? _clientId;
  DateTime _date = DateTime.now();
  final _lignes = <LigneItem>[];
  bool _chargement = true;
  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    _clientId = widget.clientIdInitial;
    if (widget.lignesInitiales != null) _lignes.addAll(widget.lignesInitiales!);
    _charger();
  }

  Future<void> _charger() async {
    final produits = await _produitsService.lister();
    final clients = await _clientsService.lister();
    setState(() {
      _produits = produits;
      _clients = clients;
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
        clientId: _clientId,
        entrepotId: entrepotId,
        date: _date,
        transporteur: _transporteur.text.trim(),
        adresseLivraison: _adresse.text.trim(),
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
      appBar: AppBar(title: const Text('Nouveau bon de livraison')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<String>(
            value: _clientId,
            decoration: const InputDecoration(labelText: 'Client'),
            items: [
              const DropdownMenuItem(value: null, child: Text('— Sans client —')),
              ..._clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nom))),
            ],
            onChanged: (v) => setState(() => _clientId = v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Date'),
            controller: TextEditingController(text: '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}'),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (d != null) setState(() => _date = d);
            },
          ),
          const SizedBox(height: 12),
          TextField(controller: _transporteur, decoration: const InputDecoration(labelText: 'Transporteur (optionnel)')),
          const SizedBox(height: 12),
          TextField(controller: _adresse, decoration: const InputDecoration(labelText: 'Adresse de livraison (optionnel)')),
          const SizedBox(height: 16),
          LigneEditor(lignes: _lignes, produits: _produits, afficherPrix: true, onChanged: () => setState(() {})),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _enregistrement ? null : _enregistrer,
            child: _enregistrement ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Créer le bon de livraison'),
          ),
        ]),
      ),
    );
  }
}
