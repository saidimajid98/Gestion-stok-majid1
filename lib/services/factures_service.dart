import 'supabase_service.dart';
import '../models/facture.dart';
import '../models/ligne_item.dart';

class FacturesService {
  final _sb = SupabaseService.client;

  static const _selectComplet = '*, clients(nom), lignes_facture(*)';

  Future<List<Facture>> lister({String? recherche}) async {
    final res = await _sb.from('factures').select(_selectComplet).order('date', ascending: false);
    var factures = (res as List).map((m) => Facture.fromMap(m as Map<String, dynamic>)).toList();
    if (recherche != null && recherche.trim().isNotEmpty) {
      final q = recherche.trim().toLowerCase();
      factures = factures.where((f) => f.numero.toLowerCase().contains(q) || f.clientNom.toLowerCase().contains(q)).toList();
    }
    return factures;
  }

  Future<Facture> obtenir(String id) async {
    final res = await _sb.from('factures').select(_selectComplet).eq('id', id).single();
    return Facture.fromMap(res);
  }

  /// Crée une facture avec ses lignes. Les totaux sont recalculés
  /// automatiquement côté base par un trigger sur `lignes_facture`.
  Future<Facture> creer({
    required String? clientId,
    required DateTime date,
    required double tva,
    required List<LigneItem> lignes,
  }) async {
    final numero = await _sb.rpc('prochain_numero', params: {'p_cle': 'facture', 'p_prefixe': 'FAC'}) as String;
    final inserted = await _sb.from('factures').insert({
      'numero': numero,
      'client_id': clientId,
      'date': date.toIso8601String().substring(0, 10),
      'tva': tva,
      'statut': 'impayee',
    }).select().single();
    final factureId = inserted['id'] as String;

    if (lignes.isNotEmpty) {
      await _sb.from('lignes_facture').insert(lignes.map((l) => l.toLigneFactureInsert(factureId)).toList());
    }
    return obtenir(factureId);
  }

  Future<void> changerStatut(String id, String statut) async {
    await _sb.from('factures').update({'statut': statut}).eq('id', id);
  }

  Future<void> supprimer(String id) async {
    await _sb.from('factures').delete().eq('id', id);
  }
}
