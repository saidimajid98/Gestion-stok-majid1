import 'package:flutter/material.dart';
import '../models/produit.dart';
import '../models/ligne_item.dart';
import '../theme.dart';

/// Éditeur de lignes d'articles réutilisable pour les factures,
/// bons de livraison et bons de sortie.
class LigneEditor extends StatefulWidget {
  final List<LigneItem> lignes;
  final List<Produit> produits;
  final bool afficherPrix;
  final VoidCallback onChanged;

  const LigneEditor({
    super.key,
    required this.lignes,
    required this.produits,
    required this.onChanged,
    this.afficherPrix = true,
  });

  @override
  State<LigneEditor> createState() => _LigneEditorState();
}

class _LigneEditorState extends State<LigneEditor> {
  Produit? _produit(String? id) {
    if (id == null) return null;
    for (final p in widget.produits) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ...widget.lignes.asMap().entries.map((entry) {
        final i = entry.key;
        final ligne = entry.value;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: ligne.produitId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Produit', isDense: true),
                    items: widget.produits
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.nom} (${p.quantiteTotale.toStringAsFixed(0)} ${p.unite})', overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        ligne.produitId = v;
                        final p = _produit(v);
                        if (p != null) {
                          ligne.designation = p.nom;
                          ligne.unite = p.unite;
                          if (ligne.prixUnitaire == 0) ligne.prixUnitaire = p.prixVente;
                        }
                      });
                      widget.onChanged();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.danger),
                  onPressed: () {
                    setState(() => widget.lignes.removeAt(i));
                    widget.onChanged();
                  },
                ),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    initialValue: ligne.quantite == 0 ? '' : ligne.quantite.toString(),
                    decoration: const InputDecoration(labelText: 'Quantité', isDense: true),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) {
                      ligne.quantite = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                      widget.onChanged();
                    },
                  ),
                ),
                if (widget.afficherPrix) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: ligne.prixUnitaire == 0 ? '' : ligne.prixUnitaire.toString(),
                      decoration: const InputDecoration(labelText: 'Prix unit.', isDense: true),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) {
                        ligne.prixUnitaire = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                        widget.onChanged();
                      },
                    ),
                  ),
                ],
              ]),
              if (widget.afficherPrix) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(ligne.total.toStringAsFixed(2), style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                ),
              ],
              if (ligne.produitId != null && _produit(ligne.produitId) != null && ligne.quantite > _produit(ligne.produitId)!.quantiteTotale)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Stock insuffisant (disponible : ${_produit(ligne.produitId)!.quantiteTotale.toStringAsFixed(0)})',
                    style: const TextStyle(color: AppColors.danger, fontSize: 11.5),
                  ),
                ),
            ]),
          ),
        );
      }),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () {
            setState(() => widget.lignes.add(LigneItem()));
            widget.onChanged();
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ajouter un article'),
        ),
      ),
    ]);
  }
}
