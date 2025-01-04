import '../consts/strings.dart';

class Publicite {
  final int id;
  final String pathImage;
  final int? typeCategorieId;
  final String? nameSousCategories;

  Publicite({
    required this.id,
    required this.pathImage,
    this.typeCategorieId,
    this.nameSousCategories,
  });

  factory Publicite.fromJson(Map<String, dynamic> json, String baseUrl) {
    String _getFullImageUrl(String pathImage) {
      return '$domaineapiImage/$pathImage';
    }

    // Décrémente le type_categorie_id de 1
    int? _getTypeCategorieId(int? typeCategorieId) {
      if (typeCategorieId != null) {
        return typeCategorieId - 1;
      }
      return null;
    }

    return Publicite(
      id: json['id'],
      pathImage: _getFullImageUrl(json['pathImage']),
      typeCategorieId: _getTypeCategorieId(json['sous_categorie']?['type_categorie_id']),
      nameSousCategories: json['sous_categorie']?['name_sous_categories'],
    );
  }
}
