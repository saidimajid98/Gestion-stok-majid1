class LigneBL {
  final String id;
  final String? produitId;
  final String designation;
  final double quantite;
  final double prixUnitaire;

  LigneBL({required this.id, this.produitId, required this.designation, required this.quantite, this.prixUnitaire = 0});

  factory LigneBL.fromMap(Map<String, dynamic> m) => LigneBL(
        id: m['id'] as String,
        produitId: m['produit_id'] as String?,
        designation: m['designation'] as String,
        quantite: (m['quantite'] as num).toDouble(),
        prixUnitaire: (m['prix_unitaire'] as num?)?.toDouble() ?? 0,
      );
}

class BonLivraison {
  final String id;
  final String numero;
  final String? clientId;
  final String clientNom;
  final DateTime date;
  final String? transporteur;
  final String? adresseLivraison;
  final List<LigneBL> lignes;

  BonLivraison({
    required this.id,
    required this.numero,
    this.clientId,
    required this.clientNom,
    required this.date,
    this.transporteur,
    this.adresseLivraison,
    this.lignes = const [],
  });

  factory BonLivraison.fromMap(Map<String, dynamic> m) => BonLivraison(
        id: m['id'] as String,
        numero: m['numero'] as String,
        clientId: m['client_id'] as String?,
        clientNom: (m['clients'] != null ? m['clients']['nom'] : null) ?? '—',
        date: DateTime.parse(m['date'] as String),
        transporteur: m['transporteur'] as String?,
        adresseLivraison: m['adresse_livraison'] as String?,
        lignes: (m['lignes_bl'] as List<dynamic>? ?? [])
            .map((l) => LigneBL.fromMap(l as Map<String, dynamic>))
            .toList(),
      );
}
