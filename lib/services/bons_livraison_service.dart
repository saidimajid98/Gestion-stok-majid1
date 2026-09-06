import 'supabase_service.dart';
import '../models/bon_livraison.dart';
import '../models/ligne_item.dart';

class BonsLivraisonService {
  final _sb = SupabaseService.client;

  static const _selectComplet = '*, clients(nom), lignes_bl(*)';

  Future<List<BonLivraison>> lister({String? recherche}) async {
    final res = await _sb.from('bons_livraison').select(_selectComplet).order('date', ascending: false);
    var bons = (res as List).map((m) => BonLivraison.fromMap(m as Map<String, dynamic>)).toList();
    if (recherche != null && recherche.trim().isNotEmpty) {
      final q = recherche.trim().toLowerCase();
      bons = bons.where((b) => b.numero.toLowerCase().contains(q) || b.clientNom.toLowerCase().contains(q)).toList();
    }
    return bons;
  }

  Future<BonLivraison> obtenir(String id) async {
    final res = await _sb.from('bons_livraison').select(_selectComplet).eq('id', id).single();
    return BonLivraison.fromMap(res);
  }

  /// Crée un bon de livraison. L'insertion des lignes déclenche
  /// automatiquement la sortie de stock (trigger SQL `trg_lignes_bl_insert`).
  Future<BonLivraison> creer({
    required String? clientId,
    required String entrepotId,
    required DateTime date,
    String? transporteur,
    String? adresseLivraison,
    required List<LigneItem> lignes,
  }) async {
    final numero = await _sb.rpc('prochain_numero', params: {'p_cle': 'bon_livraison', 'p_prefixe': 'BL'}) as String;
    final inserted = await _sb.from('bons_livraison').insert({
      'numero': numero,
      'client_id': clientId,
      'entrepot_id': entrepotId,
      'date': date.toIso8601String().substring(0, 10),
      'transporteur': transporteur,
      'adresse_livraison': adresseLivraison,
    }).select().single();
    final bonId = inserted['id'] as String;

    for (final l in lignes) {
      await _sb.from('lignes_bl').insert({
        'bon_livraison_id': bonId,
        'produit_id': l.produitId,
        'designation': l.designation,
        'quantite': l.quantite,
        'prix_unitaire': l.prixUnitaire,
      });
    }
    return obtenir(bonId);
  }

  /// Supprime le bon ; la suppression des lignes (cascade) réintègre
  /// automatiquement les quantités au stock (trigger `trg_lignes_bl_delete`).
  Future<void> supprimer(String id) async {
    await _sb.from('bons_livraison').delete().eq('id', id);
  }
}
