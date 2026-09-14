import 'package:flutter/material.dart';
import '../../services/factures_service.dart';
import '../../models/facture.dart';
import '../../widgets/empty_state.dart';
import '../../theme.dart';
import 'facture_form_screen.dart';
import 'facture_detail_screen.dart';

class FacturesListScreen extends StatefulWidget {
  const FacturesListScreen({super.key});

  @override
  State<FacturesListScreen> createState() => _FacturesListScreenState();
}

class _FacturesListScreenState extends State<FacturesListScreen> {
  final _service = FacturesService();
  final _recherche = TextEditingController();
  Future<List<Facture>>? _futur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _charger() { setState(() { _futur = _service.lister(recherche: _recherche.text); }); }

  Future<void> _ouvrirFormulaire() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FactureFormScreen()));
    if (mounted) _charger();
  }

  Future<void> _ouvrirDetail(String id) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => FactureDetailScreen(factureId: id)));
    if (mounted) _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Factures')),
      floatingActionButton: FloatingActionButton(onPressed: _ouvrirFormulaire, child: const Icon(Icons.add)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _recherche,
            decoration: const InputDecoration(hintText: 'Rechercher (n°, client)…', prefixIcon: Icon(Icons.search)),
            onChanged: (_) => _charger(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Facture>>(
              future: _futur,
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final factures = snap.data!;
                if (factures.isEmpty) {
                  return EmptyState(message: 'Aucune facture émise.', actionLabel: 'Créer une facture', onAction: _ouvrirFormulaire);
                }
                return ListView.builder(
                  itemCount: factures.length,
                  itemBuilder: (context, i) {
                    final f = factures[i];
                    return Card(
                      child: ListTile(
                        title: Text(f.numero),
                        subtitle: Text('${f.clientNom} · ${f.date.day.toString().padLeft(2, '0')}/${f.date.month.toString().padLeft(2, '0')}/${f.date.year}'),
                        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${f.totalTtc.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(f.statut == 'payee' ? 'Payée' : 'Impayée', style: TextStyle(color: f.statut == 'payee' ? AppColors.good : AppColors.danger, fontSize: 11)),
                        ]),
                        onTap: () => _ouvrirDetail(f.id),
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
