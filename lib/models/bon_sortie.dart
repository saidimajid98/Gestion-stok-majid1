class LigneBS {
  final String id;
  final String? produitId;
  final String designation;
  final double quantite;
  final String unite;

  LigneBS({required this.id, this.produitId, required this.designation, required this.quantite, this.unite = ''});

  factory LigneBS.fromMap(Map<String, dynamic> m) => LigneBS(
        id: m['id'] as String,
        produitId: m['produit_id'] as String?,
        designation: m['designation'] as String,
        quantite: (m['quantite'] as num).toDouble(),
        unite: (m['unite'] as String?) ?? '',
      );
}

class BonSortie {
  final String id;
  final String numero;
  final DateTime date;
  final String? chauffeurNom;
  final String? chauffeurCin;
  final String? vehiculeImmatriculation;
  final String? motif;
  final String? observations;
  final List<LigneBS> lignes;

  BonSortie({
    required this.id,
    required this.numero,
    required this.date,
    this.chauffeurNom,
    this.chauffeurCin,
    this.vehiculeImmatriculation,
    this.motif,
    this.observations,
    this.lignes = const [],
  });

  factory BonSortie.fromMap(Map<String, dynamic> m) => BonSortie(
        id: m['id'] as String,
        numero: m['numero'] as String,
        date: DateTime.parse(m['date'] as String),
        chauffeurNom: m['chauffeur_nom'] as String?,
        chauffeurCin: m['chauffeur_cin'] as String?,
        vehiculeImmatriculation: m['vehicule_immatriculation'] as String?,
        motif: m['motif'] as String?,
        observations: m['observations'] as String?,
        lignes: (m['lignes_bon_sortie'] as List<dynamic>? ?? [])
            .map((l) => LigneBS.fromMap(l as Map<String, dynamic>))
            .toList(),
      );
}
