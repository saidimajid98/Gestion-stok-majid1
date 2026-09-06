class Produit {
  final String id;
  final String nom;
  final String? categorieId;
  final String unite;
  final double prixAchat;
  final double prixVente;
  final double seuilAlerte;
  final double quantiteTotale; // agrégée depuis la vue v_produits_stock

  Produit({
    required this.id,
    required this.nom,
    this.categorieId,
    required this.unite,
    required this.prixAchat,
    required this.prixVente,
    required this.seuilAlerte,
    required this.quantiteTotale,
  });

  bool get sousSeuil => quantiteTotale <= seuilAlerte;

  factory Produit.fromMap(Map<String, dynamic> m) => Produit(
        id: m['id'] as String,
        nom: m['nom'] as String,
        categorieId: m['categorie_id'] as String?,
        unite: (m['unite'] as String?) ?? 'unité',
        prixAchat: (m['prix_achat'] as num?)?.toDouble() ?? 0,
        prixVente: (m['prix_vente'] as num?)?.toDouble() ?? 0,
        seuilAlerte: (m['seuil_alerte'] as num?)?.toDouble() ?? 0,
        quantiteTotale: (m['quantite_totale'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toInsertMap() => {
        'nom': nom,
        'categorie_id': categorieId,
        'unite': unite,
        'prix_achat': prixAchat,
        'prix_vente': prixVente,
        'seuil_alerte': seuilAlerte,
      };
}
