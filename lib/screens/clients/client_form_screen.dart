import 'package:flutter/material.dart';
import '../../services/clients_service.dart';
import '../../models/client.dart';
import '../../theme.dart';

class ClientFormScreen extends StatefulWidget {
  final Client? client;
  const ClientFormScreen({super.key, this.client});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _service = ClientsService();
  final _nom = TextEditingController();
  final _telephone = TextEditingController();
  final _adresse = TextEditingController();
  final _ice = TextEditingController();
  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    if (c != null) {
      _nom.text = c.nom;
      _telephone.text = c.telephone ?? '';
      _adresse.text = c.adresse ?? '';
      _ice.text = c.ice ?? '';
    }
  }

  Future<void> _enregistrer() async {
    if (_nom.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merci de renseigner un nom.')));
      return;
    }
    setState(() => _enregistrement = true);
    final c = Client(id: widget.client?.id ?? '', nom: _nom.text.trim(), telephone: _telephone.text.trim(), adresse: _adresse.text.trim(), ice: _ice.text.trim());
    try {
      if (widget.client == null) {
        await _service.creer(c);
      } else {
        await _service.modifier(widget.client!.id, c);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  Future<void> _supprimer() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce client ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirme != true) return;
    await _service.supprimer(widget.client!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final modif = widget.client != null;
    return Scaffold(
      appBar: AppBar(title: Text(modif ? 'Modifier le client' : 'Nouveau client')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _nom, decoration: const InputDecoration(labelText: 'Nom')),
          const SizedBox(height: 12),
          TextField(controller: _telephone, decoration: const InputDecoration(labelText: 'Téléphone')),
          const SizedBox(height: 12),
          TextField(controller: _adresse, decoration: const InputDecoration(labelText: 'Adresse')),
          const SizedBox(height: 12),
          TextField(controller: _ice, decoration: const InputDecoration(labelText: 'ICE / Registre de commerce')),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _enregistrement ? null : _enregistrer,
            child: _enregistrement ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Enregistrer'),
          ),
          if (modif) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _supprimer,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.dangerSoft)),
              child: const Text('Supprimer le client'),
            ),
          ],
        ]),
      ),
    );
  }
}
