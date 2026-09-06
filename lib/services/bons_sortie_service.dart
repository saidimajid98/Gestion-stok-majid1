import 'supabase_service.dart';
import '../models/bon_sortie.dart';
import '../models/ligne_item.dart';

class BonsSortieService {
  final _sb = SupabaseService.client;

  static const _selectComplet = '*, lignes_bon_sortie(*)';

  Future<List<BonSortie>> lister({String? recherche}) async {
    final res = await _sb.from('bons_sortie').select(_selectComplet).order('date', ascending: false);
    var bons = (res as List).map((m) => BonSortie.fromMap(m as Map<String, dynamic>)).toList();
    if (recherche != null && recherche.trim().isNotEmpty) {
      final q = recherche.trim().toLowerCase();
      bons = bons.where((b) =>
          b.numero.toLowerCase().contains(q) ||
          (b.motif ?? '').toLowerCase().contains(q) ||
          (b.chauffeurNom ?? '').toLowerCase().contains(q) ||
          (b.vehiculeImmatriculation ?? '').toLowerCase().contains(q)).toList();
    }
    return bons;
  }

  Future<BonSortie> obtenir(String id) async {
    final res = await _sb.from('bons_sortie').select(_selectComplet).eq('id', id).single();
    return BonSortie.fromMap(res);
  }

  /// Crée un bon de sortie. L'insertion des lignes déclenche automatiquement
  /// la sortie de stock (trigger SQL `trg_lignes_bon_sortie_insert`).
  /// Le numéro est généré au format BS-<année>-0001 (compteur annuel).
  Future<BonSortie> creer({
    required String entrepotId,
    required DateTime date,
    String? chauffeurNom,
    String? chauffeurCin,
    String? vehiculeImmatriculation,
    String? motif,
    String? observations,
    required List<LigneItem> lignes,
  }) async {
    final numero = await _sb.rpc('prochain_numero_annuel', params: {'p_cle_base': 'bon_sortie', 'p_prefixe': 'BS'}) as String;
    final inserted = await _sb.from('bons_sortie').insert({
      'numero': numero,
      'entrepot_id': entrepotId,
      'date': date.toIso8601String().substring(0, 10),
      'chauffeur_nom': chauffeurNom,
      'chauffeur_cin': chauffeurCin,
      'vehicule_immatriculation': vehiculeImmatriculation,
      'motif': motif,
      'observations': observations,
    }).select().single();
    final bonId = inserted['id'] as String;

    for (final l in lignes) {
      await _sb.from('lignes_bon_sortie').insert({
        'bon_sortie_id': bonId,
        'produit_id': l.produitId,
        'designation': l.designation,
        'quantite': l.quantite,
        'unite': l.unite,
      });
    }
    return obtenir(bonId);
  }

  /// Supprime le bon ; la suppression des lignes (cascade) réintègre
  /// automatiquement les quantités au stock (trigger de suppression).
  Future<void> supprimer(String id) async {
    await _sb.from('bons_sortie').delete().eq('id', id);
  }
}
