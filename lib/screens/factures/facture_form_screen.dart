import 'package:flutter/material.dart';
import '../../services/factures_service.dart';
import '../../services/produits_service.dart';
import '../../services/clients_service.dart';
import '../../services/parametres_service.dart';
import '../../models/produit.dart';
import '../../models/client.dart';
import '../../models/ligne_item.dart';
import '../../widgets/ligne_editor.dart';

class FactureFormScreen extends StatefulWidget {
  /// Pré-remplissage optionnel (ex. transformation d'un bon en facture).
  final String? clientIdInitial;
  final List<LigneItem>? lignesInitiales;

  const FactureFormScreen({super.key, this.clientIdInitial, this.lignesInitiales});

  @override
  State<FactureFormScreen> createState() => _FactureFormScreenState();
}

class _FactureFormScreenState extends State<FactureFormScreen> {
  final _facturesService = FacturesService();
  final _produitsService = ProduitsService();
  final _clientsService = ClientsService();
  final _paramService = ParametresService();

  List<Produit> _produits = [];
  List<Client> _clients = [];
  String? _clientId;
  DateTime _date = DateTime.now();
  double _tva = 20;
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
    final params = await _paramService.obtenir();
    setState(() {
      _produits = produits;
      _clients = clients;
      _tva = params.tvaDefaut;
      _chargement = false;
    });
  }

  double get _totalHt => _lignes.fold(0, (s, l) => s + l.total);
  double get _totalTva => _totalHt * _tva / 100;
  double get _totalTtc => _totalHt + _totalTva;

  Future<void> _enregistrer() async {
    final lignesValides = _lignes.where((l) => l.produitId != null && l.quantite > 0).toList();
    if (lignesValides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajoutez au moins un article valide.')));
      return;
    }
    setState(() => _enregistrement = true);
    try {
      await _facturesService.creer(clientId: _clientId, date: _date, tva: _tva, lignes: lignesValides);
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
      appBar: AppBar(title: const Text('Nouvelle facture')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<String>(
            value: _clientId,
            decoration: const InputDecoration(labelText: 'Client'),
            items: [
              const DropdownMenuItem(value: null, child: Text('— Client libre —')),
              ..._clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nom))),
            ],
            onChanged: (v) => setState(() => _clientId = v),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Date'),
                controller: TextEditingController(text: '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}'),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (d != null) setState(() => _date = d);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: _tva.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'TVA (%)'),
                onChanged: (v) => setState(() => _tva = double.tryParse(v.replaceAll(',', '.')) ?? 0),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          LigneEditor(lignes: _lignes, produits: _produits, afficherPrix: true, onChanged: () => setState(() {})),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                _totalRow('Total HT', _totalHt),
                _totalRow('TVA (${_tva.toStringAsFixed(0)}%)', _totalTva),
                const Divider(),
                _totalRow('Total TTC', _totalTtc, gras: true),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _enregistrement ? null : _enregistrer,
            child: _enregistrement ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Créer la facture'),
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
