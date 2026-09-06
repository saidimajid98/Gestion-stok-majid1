class PointGps {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  PointGps({required this.latitude, required this.longitude, required this.timestamp});

  factory PointGps.fromMap(Map<String, dynamic> m) => PointGps(
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        timestamp: DateTime.parse(m['timestamp'] as String),
      );
}

enum StatutTrajet { enCours, termine, annule }

StatutTrajet _statutFromString(String s) {
  switch (s) {
    case 'termine':
      return StatutTrajet.termine;
    case 'annule':
      return StatutTrajet.annule;
    default:
      return StatutTrajet.enCours;
  }
}

String statutTrajetToString(StatutTrajet s) {
  switch (s) {
    case StatutTrajet.termine:
      return 'termine';
    case StatutTrajet.annule:
      return 'annule';
    case StatutTrajet.enCours:
      return 'en_cours';
  }
}

/// Type de bon auquel le trajet est rattaché : livraison ou sortie.
enum TypeBon { livraison, sortie }

String typeBonToString(TypeBon t) => t == TypeBon.livraison ? 'livraison' : 'sortie';
TypeBon typeBonFromString(String s) => s == 'livraison' ? TypeBon.livraison : TypeBon.sortie;

class Trajet {
  final String id;
  final String bonId;
  final TypeBon typeBon;
  final String? chauffeurNom;
  final String? chauffeurCin;
  final String? vehiculeImmatriculation;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final StatutTrajet statut;
  final double? distanceKm;
  final int? dureeMinutes;
  final List<PointGps> points;

  Trajet({
    required this.id,
    required this.bonId,
    required this.typeBon,
    this.chauffeurNom,
    this.chauffeurCin,
    this.vehiculeImmatriculation,
    required this.dateDebut,
    this.dateFin,
    required this.statut,
    this.distanceKm,
    this.dureeMinutes,
    this.points = const [],
  });

  factory Trajet.fromMap(Map<String, dynamic> m) => Trajet(
        id: m['id'] as String,
        bonId: m['bon_id'] as String,
        typeBon: typeBonFromString(m['type_bon'] as String),
        chauffeurNom: m['chauffeur_nom'] as String?,
        chauffeurCin: m['chauffeur_cin'] as String?,
        vehiculeImmatriculation: m['vehicule_immatriculation'] as String?,
        dateDebut: DateTime.parse(m['date_debut'] as String),
        dateFin: m['date_fin'] != null ? DateTime.parse(m['date_fin'] as String) : null,
        statut: _statutFromString(m['statut'] as String),
        distanceKm: (m['distance_km'] as num?)?.toDouble(),
        dureeMinutes: (m['duree_minutes'] as num?)?.toInt(),
        points: (m['points'] as List<dynamic>? ?? []).map((p) => PointGps.fromMap(p as Map<String, dynamic>)).toList(),
      );
}
