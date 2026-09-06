import 'package:flutter/material.dart';
import '../../services/bons_livraison_service.dart';
import '../../services/bons_sortie_service.dart';
import '../../models/bon_livraison.dart';
import '../../models/bon_sortie.dart';
import '../../widgets/empty_state.dart';
import 'bon_livraison_form_screen.dart';
import 'bon_livraison_detail_screen.dart';
import 'bon_sortie_form_screen.dart';
import 'bon_sortie_detail_screen.dart';

class BonsScreen extends StatefulWidget {
  const BonsScreen({super.key});

  @override
  State<BonsScreen> createState() => _BonsScreenState();
}

class _BonsScreenState extends State<BonsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _blService = BonsLivraisonService();
  final _bsService = BonsSortieService();
  final _recherche = TextEditingController();
  Future<List<BonLivraison>>? _futurBl;
  Future<List<BonSortie>>? _futurBs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _charger();
  }

  void _charger() {
    setState(() {
      _futurBl = _blService.lister(recherche: _recherche.text);
      _futurBs = _bsService.lister(recherche: _recherche.text);
    });
  }

  Future<void> _nouveauSelonOnglet() async {
    if (_tabController.index == 0) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BonLivraisonFormScreen()));
    } else {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BonSortieFormScreen()));
    }
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bons'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [Tab(text: 'Livraison'), Tab(text: 'Sortie')],
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _nouveauSelonOnglet, child: const Icon(Icons.add)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _recherche,
            decoration: const InputDecoration(hintText: 'Rechercher…', prefixIcon: Icon(Icons.search)),
            onChanged: (_) => _charger(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(controller: _tabController, children: [
              _listeLivraisons(),
              _listeSorties(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _listeLivraisons() {
    return FutureBuilder<List<BonLivraison>>(
      future: _futurBl,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final bons = snap.data!;
        if (bons.isEmpty) {
          return EmptyState(
            message: 'Aucun bon de livraison enregistré.',
            actionLabel: 'Créer un bon de livraison',
            onAction: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BonLivraisonFormScreen()));
              _charger();
            },
          );
        }
        return ListView.builder(
          itemCount: bons.length,
          itemBuilder: (context, i) {
            final b = bons[i];
            return Card(
              child: ListTile(
                title: Text(b.numero),
                subtitle: Text('${b.clientNom} · ${b.date.day.toString().padLeft(2, '0')}/${b.date.month.toString().padLeft(2, '0')}/${b.date.year}'),
                trailing: Text('${b.lignes.length} art.'),
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => BonLivraisonDetailScreen(bonId: b.id)));
                  _charger();
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _listeSorties() {
    return FutureBuilder<List<BonSortie>>(
      future: _futurBs,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final bons = snap.data!;
        if (bons.isEmpty) {
          return EmptyState(
            message: 'Aucun bon de sortie enregistré.',
            actionLabel: 'Créer un bon de sortie',
            onAction: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BonSortieFormScreen()));
              _charger();
            },
          );
        }
        return ListView.builder(
          itemCount: bons.length,
          itemBuilder: (context, i) {
            final b = bons[i];
            return Card(
              child: ListTile(
                title: Text(b.numero),
                subtitle: Text('${b.chauffeurNom?.isNotEmpty == true ? b.chauffeurNom! : (b.motif?.isNotEmpty == true ? b.motif! : 'Sortie de stock')} · ${b.date.day.toString().padLeft(2, '0')}/${b.date.month.toString().padLeft(2, '0')}/${b.date.year}'),
                trailing: Text('${b.lignes.length} art.'),
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => BonSortieDetailScreen(bonId: b.id)));
                  _charger();
                },
              ),
            );
          },
        );
      },
    );
  }
}
