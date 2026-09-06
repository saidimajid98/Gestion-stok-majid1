class Client {
  final String id;
  final String nom;
  final String? telephone;
  final String? adresse;
  final String? ice;

  Client({required this.id, required this.nom, this.telephone, this.adresse, this.ice});

  factory Client.fromMap(Map<String, dynamic> m) => Client(
        id: m['id'] as String,
        nom: m['nom'] as String,
        telephone: m['telephone'] as String?,
        adresse: m['adresse'] as String?,
        ice: m['ice'] as String?,
      );

  Map<String, dynamic> toInsertMap() => {
        'nom': nom,
        'telephone': telephone,
        'adresse': adresse,
        'ice': ice,
      };
}
