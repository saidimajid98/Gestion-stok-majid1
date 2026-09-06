import 'supabase_service.dart';
import '../models/produit.dart';

class ProduitsService {
  final _sb = SupabaseService.client;

  Future<List<Produit>> lister({String? recherche}) async {
    var query = _sb.from('v_produits_stock').select();
    if (recherche != null && recherche.trim().isNotEmpty) {
      query = query.ilike('nom', '%${recherche.trim()}%');
    }
    final res = await query.order('nom');
    return (res as List).map((m) => Produit.fromMap(m as Map<String, dynamic>)).toList();
  }

  Future<List<Produit>> sousSeuil() async {
    final res = await _sb.from('v_produits_stock').select().order('nom');
    return (res as List)
        .map((m) => Produit.fromMap(m as Map<String, dynamic>))
        .where((p) => p.sousSeuil)
        .toList();
  }

  Future<void> creer(Produit p, double quantiteInitiale, String entrepotId) async {
    final inserted = await _sb.from('produits').insert(p.toInsertMap()).select().single();
    final produitId = inserted['id'] as String;
    if (quantiteInitiale != 0) {
      await _sb.from('stocks').insert({
        'produit_id': produitId,
        'entrepot_id': entrepotId,
        'quantite': quantiteInitiale,
      });
    }
  }

  Future<void> modifier(String id, Produit p) async {
    await _sb.from('produits').update(p.toInsertMap()).eq('id', id);
  }

  Future<void> supprimer(String id) async {
    await _sb.from('produits').delete().eq('id', id);
  }

  /// Ajustement manuel du stock (correction d'inventaire), journalisé
  /// côté base via la fonction SQL `ajuster_stock`.
  Future<void> ajusterStockManuel(String produitId, String entrepotId, double delta, String motif) async {
    await _sb.rpc('ajuster_stock', params: {
      'p_produit_id': produitId,
      'p_entrepot_id': entrepotId,
      'p_delta': delta,
      'p_type': 'correction',
      'p_reference_type': 'manuel',
      'p_reference_id': null,
      'p_motif': motif,
    });
  }

  Future<double> valeurTotaleStock() async {
    final produits = await lister();
    double total = 0;
    for (final p in produits) {
      total += p.quantiteTotale * p.prixAchat;
    }
    return total;
  }
}
