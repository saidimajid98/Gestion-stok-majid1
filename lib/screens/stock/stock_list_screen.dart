import 'package:flutter/material.dart';
import '../../services/produits_service.dart';
import '../../models/produit.dart';
import '../../widgets/empty_state.dart';
import '../../theme.dart';
import 'produit_form_screen.dart';

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  final _service = ProduitsService();
  final _recherche = TextEditingController();
  Future<List<Produit>>? _futur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _charger() {
    setState(() => _futur = _service.lister(recherche: _recherche.text));
  }

  Future<void> _ouvrirFormulaire([Produit? p]) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProduitFormScreen(produit: p)));
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock')),
      floatingActionButton: FloatingActionButton(onPressed: () => _ouvrirFormulaire(), child: const Icon(Icons.add)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _recherche,
            decoration: const InputDecoration(hintText: 'Rechercher un produit…', prefixIcon: Icon(Icons.search)),
            onChanged: (_) => _charger(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Produit>>(
              future: _futur,
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final produits = snap.data!;
                if (produits.isEmpty) {
                  return EmptyState(
                    message: 'Aucun produit trouvé. Ajoutez votre premier article au stock.',
                    actionLabel: 'Ajouter un produit',
                    onAction: () => _ouvrirFormulaire(),
                  );
                }
                return ListView.builder(
                  itemCount: produits.length,
                  itemBuilder: (context, i) {
                    final p = produits[i];
                    return Card(
                      child: ListTile(
                        title: Text(p.nom),
                        subtitle: Text('Vente : ${p.prixVente.toStringAsFixed(2)}'),
                        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${p.quantiteTotale.toStringAsFixed(0)} ${p.unite}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(p.sousSeuil ? 'Bas' : 'OK', style: TextStyle(color: p.sousSeuil ? AppColors.danger : AppColors.good, fontSize: 11)),
                        ]),
                        onTap: () => _ouvrirFormulaire(p),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
