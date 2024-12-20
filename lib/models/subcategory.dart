class SubCategory {
  final int id;
  final int typeCategorieId;
  final String nameSousCategories;
  final int? prix;

  SubCategory({
    required this.id,
    required this.typeCategorieId,
    required this.nameSousCategories,
    this.prix,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'],
      typeCategorieId: json['type_categorie_id'],
      nameSousCategories: json['name_sous_categories'],
      prix: json['prix'],
    );
  }
}
