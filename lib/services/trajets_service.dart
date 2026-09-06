import 'supabase_service.dart';
import '../models/trajet.dart';

class TrajetsService {
  final _sb = SupabaseService.client;

  /// Le ou les trajets rattachés à un bon donné (le plus récent en premier).
  Future<List<Trajet>> listerPourBon(String bonId, TypeBon typeBon) async {
    final res = await _sb
        .from('trajets')
        .select()
        .eq('bon_id', bonId)
        .eq('type_bon', typeBonToString(typeBon))
        .order('date_debut', ascending: false);
    return (res as List).map((m) => Trajet.fromMap(m as Map<String, dynamic>)).toList();
  }

  /// Trajet actif (en_cours) pour un bon, s'il y en a un.
  Future<Trajet?> enCoursPourBon(String bonId, TypeBon typeBon) async {
    final trajets = await listerPourBon(bonId, typeBon);
    for (final t in trajets) {
      if (t.statut == StatutTrajet.enCours) return t;
    }
    return null;
  }

  Future<Trajet> demarrer({
    required String bonId,
    required TypeBon typeBon,
    String? chauffeurNom,
    String? chauffeurCin,
    String? vehiculeImmatriculation,
  }) async {
    final inserted = await _sb.from('trajets').insert({
      'bon_id': bonId,
      'type_bon': typeBonToString(typeBon),
      'chauffeur_nom': chauffeurNom,
      'chauffeur_cin': chauffeurCin,
      'vehicule_immatriculation': vehiculeImmatriculation,
      'date_debut': DateTime.now().toIso8601String(),
      'statut': 'en_cours',
    }).select().single();
    return Trajet.fromMap(inserted);
  }

  /// Ajoute une position GPS au trajet (appel atomique côté base).
  /// Prévu pour être branché sur un flux de positions (ex. package
  /// `geolocator`) : chaque nouvelle position reçue déclenche cet appel.
  Future<void> ajouterPoint(String trajetId, double latitude, double longitude) async {
    await _sb.rpc('ajouter_point_trajet', params: {
      'p_trajet_id': trajetId,
      'p_latitude': latitude,
      'p_longitude': longitude,
      'p_timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<Trajet> terminer(String trajetId, {double? distanceKm}) async {
    final updated = await _sb.from('trajets').update({
      'date_fin': DateTime.now().toIso8601String(),
      'statut': 'termine',
      if (distanceKm != null) 'distance_km': distanceKm,
    }).eq('id', trajetId).select().single();
    return Trajet.fromMap(updated);
  }

  Future<void> annuler(String trajetId) async {
    await _sb.from('trajets').update({'statut': 'annule', 'date_fin': DateTime.now().toIso8601String()}).eq('id', trajetId);
  }
}
