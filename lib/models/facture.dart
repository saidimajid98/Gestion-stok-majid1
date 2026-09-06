import 'ligne_item.dart';

class LigneFacture {
  final String id;
  final String? produitId;
  final String designation;
  final double quantite;
  final double prixUnitaire;

  LigneFacture({
    required this.id,
    this.produitId,
    required this.designation,
    required this.quantite,
    required this.prixUnitaire,
  });

  double get total => quantite * prixUnitaire;

  factory LigneFacture.fromMap(Map<String, dynamic> m) => LigneFacture(
        id: m['id'] as String,
        produitId: m['produit_id'] as String?,
        designation: m['designation'] as String,
        quantite: (m['quantite'] as num).toDouble(),
        prixUnitaire: (m['prix_unitaire'] as num).toDouble(),
      );
}

class Facture {
  final String id;
  final String numero;
  final String? clientId;
  final String clientNom;
  final DateTime date;
  final double tva;
  final String statut; // impayee | payee | annulee
  final double totalHt;
  final double totalTva;
  final double totalTtc;
  final List<LigneFacture> lignes;

  Facture({
    required this.id,
    required this.numero,
    this.clientId,
    required this.clientNom,
    required this.date,
    required this.tva,
    required this.statut,
    required this.totalHt,
    required this.totalTva,
    required this.totalTtc,
    this.lignes = const [],
  });

  factory Facture.fromMap(Map<String, dynamic> m) => Facture(
        id: m['id'] as String,
        numero: m['numero'] as String,
        clientId: m['client_id'] as String?,
        clientNom: (m['clients'] != null ? m['clients']['nom'] : null) ?? 'Client',
        date: DateTime.parse(m['date'] as String),
        tva: (m['tva'] as num).toDouble(),
        statut: m['statut'] as String,
        totalHt: (m['total_ht'] as num?)?.toDouble() ?? 0,
        totalTva: (m['total_tva'] as num?)?.toDouble() ?? 0,
        totalTtc: (m['total_ttc'] as num?)?.toDouble() ?? 0,
        lignes: (m['lignes_facture'] as List<dynamic>? ?? [])
            .map((l) => LigneFacture.fromMap(l as Map<String, dynamic>))
            .toList(),
      );
}

extension LigneItemMap on LigneItem {
  Map<String, dynamic> toLigneFactureInsert(String factureId) => {
        'facture_id': factureId,
        'produit_id': produitId,
        'designation': designation,
        'quantite': quantite,
        'prix_unitaire': prixUnitaire,
      };
}
