import 'package:flutter/material.dart';
import '../../services/produits_service.dart';
import '../../services/supabase_service.dart';
import '../../models/produit.dart';
import '../../theme.dart';

class ProduitFormScreen extends StatefulWidget {
  final Produit? produit;
  const ProduitFormScreen({super.key, this.produit});

  @override
  State<ProduitFormScreen> createState() => _ProduitFormScreenState();
}

class _ProduitFormScreenState extends State<ProduitFormScreen> {
  final _service = ProduitsService();
  final _nom = TextEditingController();
  final _unite = TextEditingController(text: 'unité');
  final _quantite = TextEditingController(text: '0');
  final _seuil = TextEditingController(text: '0');
  final _prixAchat = TextEditingController(text: '0');
  final _prixVente = TextEditingController(text: '0');
  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    final p = widget.produit;
    if (p != null) {
      _nom.text = p.nom;
      _unite.text = p.unite;
      _quantite.text = p.quantiteTotale.toString();
      _seuil.text = p.seuilAlerte.toString();
      _prixAchat.text = p.prixAchat.toString();
      _prixVente.text = p.prixVente.toString();
    }
  }

  Future<void> _enregistrer() async {
    if (_nom.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merci de renseigner une désignation.')));
      return;
    }
    setState(() => _enregistrement = true);
    final p = Produit(
      id: widget.produit?.id ?? '',
      nom: _nom.text.trim(),
      unite: _unite.text.trim().isEmpty ? 'unité' : _unite.text.trim(),
      prixAchat: double.tryParse(_prixAchat.text.replaceAll(',', '.')) ?? 0,
      prixVente: double.tryParse(_prixVente.text.replaceAll(',', '.')) ?? 0,
      seuilAlerte: double.tryParse(_seuil.text.replaceAll(',', '.')) ?? 0,
      quantiteTotale: double.tryParse(_quantite.text.replaceAll(',', '.')) ?? 0,
    );
    try {
      if (widget.produit == null) {
        final entrepotId = await SupabaseService.entrepotParDefautId();
        await _service.creer(p, p.quantiteTotale, entrepotId);
      } else {
        await _service.modifier(widget.produit!.id, p);
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
        title: const Text('Supprimer ce produit ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirme != true) return;
    await _service.supprimer(widget.produit!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final modif = widget.produit != null;
    return Scaffold(
      appBar: AppBar(title: Text(modif ? 'Modifier le produit' : 'Nouveau produit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _nom, decoration: const InputDecoration(labelText: 'Désignation')),
          const SizedBox(height: 12),
          TextField(controller: _unite, decoration: const InputDecoration(labelText: 'Unité (sac, pièce, kg…)')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _quantite, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantité'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _seuil, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Seuil d\'alerte'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _prixAchat, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix achat'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _prixVente, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix vente'))),
          ]),
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
              child: const Text('Supprimer le produit'),
            ),
          ],
        ]),
      ),
    );
  }
}
