import 'package:flutter/material.dart';
import '../services/produits_service.dart';
import '../services/factures_service.dart';
import '../services/bons_livraison_service.dart';
import '../services/bons_sortie_service.dart';
import '../services/parametres_service.dart';
import '../models/produit.dart';
import '../models/facture.dart';
import '../widgets/stat_card.dart';
import '../widgets/empty_state.dart';
import '../theme.dart';
import 'factures/facture_detail_screen.dart';
import 'factures/facture_form_screen.dart';
import 'bons/bon_livraison_form_screen.dart';
import 'bons/bon_sortie_form_screen.dart';
import 'stock/produit_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _produitsService = ProduitsService();
  final _facturesService = FacturesService();
  final _blService = BonsLivraisonService();
  final _bsService = BonsSortieService();
  final _paramService = ParametresService();

  late Future<_DashboardData> _futur;

  @override
  void initState() {
    super.initState();
    _futur = _charger();
  }

  Future<_DashboardData> _charger() async {
    final produits = await _produitsService.lister();
    final factures = await _facturesService.lister();
    final livraisons = await _blService.lister();
    final bons = await _bsService.lister();
    final params = await _paramService.obtenir();

    final sousSeuil = produits.where((p) => p.sousSeuil).toList();
    final valeurStock = produits.fold<double>(0, (s, p) => s + p.quantiteTotale * p.prixAchat);

    final moisCourant = DateTime.now();
    final caMois = factures
        .where((f) => f.statut == 'payee' && f.date.year == moisCourant.year && f.date.month == moisCourant.month)
        .fold<double>(0, (s, f) => s + f.totalTtc);

    return _DashboardData(
      produits: produits,
      sousSeuil: sousSeuil,
      valeurStock: valeurStock,
      caMois: caMois,
      facturesRecentes: factures.take(5).toList(),
      devise: params.devise,
    );
  }

  Future<void> _rafraichir() async {
    final futur = _charger();
    setState(() => _futur = futur);
    await futur;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(children: [
          Text('Registre', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold)),
          Text('Aperçu de l\'activité', style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
        ]),
      ),
      body: FutureBuilder<_DashboardData>(
        future: _futur,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final d = snap.data!;
          return RefreshIndicator(
            onRefresh: _rafraichir,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.7,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  StatCard(label: 'Valeur du stock', valeur: '${d.valeurStock.toStringAsFixed(0)} ${d.devise}'),
                  StatCard(label: 'Sous seuil', valeur: '${d.sousSeuil.length}', couleur: d.sousSeuil.isNotEmpty ? AppColors.danger : null),
                  StatCard(label: 'Produits', valeur: '${d.produits.length}'),
                  StatCard(label: 'CA payé (mois)', valeur: '${d.caMois.toStringAsFixed(0)} ${d.devise}', couleur: AppColors.good),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Actions rapides', style: TextStyle(fontFamily: 'serif', fontSize: 16.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 3.2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  OutlinedButton(onPressed: () => _ouvrir(const FactureFormScreen()), child: const Text('+ Facture')),
                  OutlinedButton(onPressed: () => _ouvrir(const BonLivraisonFormScreen()), child: const Text('+ Livraison')),
                  OutlinedButton(onPressed: () => _ouvrir(const BonSortieFormScreen()), child: const Text('+ Sortie')),
                  OutlinedButton(onPressed: () => _ouvrir(const ProduitFormScreen()), child: const Text('+ Produit')),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Dernières factures', style: TextStyle(fontFamily: 'serif', fontSize: 16.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (d.facturesRecentes.isEmpty)
                const EmptyState(message: 'Aucune facture pour le moment.')
              else
                ...d.facturesRecentes.map((f) => _ligneFacture(f, d.devise)),
              if (d.sousSeuil.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Alertes stock', style: TextStyle(fontFamily: 'serif', fontSize: 16.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...d.sousSeuil.map((p) => _ligneAlerte(p)),
              ],
            ]),
          );
        },
      ),
    );
  }

  Future<void> _ouvrir(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    _rafraichir();
  }

  Widget _ligneFacture(Facture f, String devise) {
    return Card(
      child: ListTile(
        title: Text('${f.numero} · ${f.clientNom}'),
        subtitle: Text('${f.date.day.toString().padLeft(2, '0')}/${f.date.month.toString().padLeft(2, '0')}/${f.date.year}'),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${f.totalTtc.toStringAsFixed(2)} $devise', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(f.statut == 'payee' ? 'Payée' : 'Impayée', style: TextStyle(color: f.statut == 'payee' ? AppColors.good : AppColors.danger, fontSize: 11)),
        ]),
        onTap: () => _ouvrir(FactureDetailScreen(factureId: f.id)),
      ),
    );
  }

  Widget _ligneAlerte(Produit p) {
    return Card(
      child: ListTile(
        title: Text(p.nom),
        subtitle: Text('Quantité : ${p.quantiteTotale.toStringAsFixed(0)} ${p.unite} · Seuil ${p.seuilAlerte.toStringAsFixed(0)}'),
      ),
    );
  }
}

class _DashboardData {
  final List<Produit> produits;
  final List<Produit> sousSeuil;
  final double valeurStock;
  final double caMois;
  final List<Facture> facturesRecentes;
  final String devise;

  _DashboardData({
    required this.produits,
    required this.sousSeuil,
    required this.valeurStock,
    required this.caMois,
    required this.facturesRecentes,
    required this.devise,
  });
}
