class ParametresEntreprise {
  final String nom;
  final String adresse;
  final String telephone;
  final String ice;
  final String devise;
  final double tvaDefaut;

  ParametresEntreprise({
    required this.nom,
    required this.adresse,
    required this.telephone,
    required this.ice,
    required this.devise,
    required this.tvaDefaut,
  });

  factory ParametresEntreprise.fromMap(Map<String, dynamic> m) => ParametresEntreprise(
        nom: (m['nom'] as String?) ?? '',
        adresse: (m['adresse'] as String?) ?? '',
        telephone: (m['telephone'] as String?) ?? '',
        ice: (m['ice'] as String?) ?? '',
        devise: (m['devise'] as String?) ?? 'DH',
        tvaDefaut: (m['tva_defaut'] as num?)?.toDouble() ?? 20,
      );

  Map<String, dynamic> toUpdateMap() => {
        'nom': nom,
        'adresse': adresse,
        'telephone': telephone,
        'ice': ice,
        'devise': devise,
        'tva_defaut': tvaDefaut,
      };
}
