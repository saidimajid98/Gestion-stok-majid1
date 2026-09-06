import 'package:flutter/material.dart';
import '../../services/parametres_service.dart';
import '../../models/parametres.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  final _service = ParametresService();
  final _nom = TextEditingController();
  final _adresse = TextEditingController();
  final _telephone = TextEditingController();
  final _ice = TextEditingController();
  final _devise = TextEditingController();
  final _tva = TextEditingController();
  bool _chargement = true;
  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final p = await _service.obtenir();
    _nom.text = p.nom;
    _adresse.text = p.adresse;
    _telephone.text = p.telephone;
    _ice.text = p.ice;
    _devise.text = p.devise;
    _tva.text = p.tvaDefaut.toString();
    setState(() => _chargement = false);
  }

  Future<void> _enregistrer() async {
    setState(() => _enregistrement = true);
    final p = ParametresEntreprise(
      nom: _nom.text.trim(),
      adresse: _adresse.text.trim(),
      telephone: _telephone.text.trim(),
      ice: _ice.text.trim(),
      devise: _devise.text.trim().isEmpty ? 'DH' : _devise.text.trim(),
      tvaDefaut: double.tryParse(_tva.text.replaceAll(',', '.')) ?? 20,
    );
    try {
      await _service.enregistrer(p);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paramètres enregistrés.')));
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
      appBar: AppBar(title: const Text('Paramètres')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _nom, decoration: const InputDecoration(labelText: 'Nom de l\'entreprise')),
          const SizedBox(height: 12),
          TextField(controller: _adresse, decoration: const InputDecoration(labelText: 'Adresse')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _telephone, decoration: const InputDecoration(labelText: 'Téléphone'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _ice, decoration: const InputDecoration(labelText: 'ICE / RC'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _devise, decoration: const InputDecoration(labelText: 'Devise'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _tva, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'TVA par défaut (%)'))),
          ]),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _enregistrement ? null : _enregistrer,
            child: _enregistrement ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Enregistrer'),
          ),
        ]),
      ),
    );
  }
}
