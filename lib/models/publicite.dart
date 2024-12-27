class Publicite {
  final int id;
  final String pathImage;
  final int? sousCategorie;
  final String? categorie;

  Publicite({
    required this.id,
    required this.pathImage,
    this.sousCategorie,
    this.categorie,
  });

  factory Publicite.fromJson(Map<String, dynamic> json) {
    return Publicite(
      id: json['id'],
      pathImage: json['pathImage'],
      sousCategorie: json['sous_categorie']?['id'],
      categorie: json['sous_categorie']?['categorie']?['libelle_homme_categories'],
    );
  }
}
