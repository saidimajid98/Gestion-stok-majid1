// Ligne d'article générique, utilisée pour l'édition des lignes de
// facture, bon de livraison et bon de sortie avant enregistrement.
class LigneItem {
  String? produitId;
  String designation;
  double quantite;
  double prixUnitaire;
  String unite; // utilisé par le bon de sortie (récupéré depuis le produit)

  LigneItem({this.produitId, this.designation = '', this.quantite = 1, this.prixUnitaire = 0, this.unite = ''});

  double get total => quantite * prixUnitaire;
}
