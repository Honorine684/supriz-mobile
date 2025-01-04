// ignore_for_file: prefer_const_constructors

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../consts/colors.dart';
import '../../consts/images.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/our_button.dart';
import '../panier/cart_controller.dart';
import '../panier/cart_provider.dart';

class ProduitScreen extends StatefulWidget {
  final int initialCategoryIndex;
  final String initialSubCategory;

  const ProduitScreen(
      {super.key,
      required this.initialCategoryIndex,
      required this.initialSubCategory});

  @override
  _ProduitScreenState createState() => _ProduitScreenState();
}

class _ProduitScreenState extends State<ProduitScreen> {
  late int _activeCategoryIndex;
  late String _activeSubCategory;
  String _searchQuery = '';
  List<dynamic> _categories = [];
  List<dynamic> _subCategories = [];
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isError = false;
  final ProductService _productService = ProductService();
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _activeCategoryIndex = widget.initialCategoryIndex;
    _activeSubCategory = widget.initialSubCategory;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      _categories = await _productService.fetchCategories();
      _loadSubCategories(_categories[_activeCategoryIndex]['id']);
    } catch (e) {
      setState(() {
        _isError = true;
      });
    }
  }

  Future<void> _loadSubCategories(int categoryId) async {
    try {
      _subCategories = await _productService.fetchSubCategories(categoryId);
      _activeSubCategory = _subCategories.isNotEmpty
          ? _subCategories[0]['name_sous_categories']
          : '';
      _loadProducts(_categories[_activeCategoryIndex]['name_id_categories'],
          _activeSubCategory);
    } catch (e) {
      setState(() {
        _isError = true;
      });
    }
  }

  Future<void> _loadProducts(
      String categoryName, String subCategoryName) async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });
    try {
      _products =
          await _productService.fetchProducts(categoryName, subCategoryName);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isError = true;
      });
    }
  }

  void _showProductDetails(Product product) {
    showProductDialog(product);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: blueColor,
          surfaceTintColor: blueColor,
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage(icAppLogo),
                radius: 20,
              ),
              SizedBox(width: 40),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_categories.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(
                            _categories[index]['libelle_homme_categories'],
                            style: TextStyle(
                              color: _activeCategoryIndex == index
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                          selected: _activeCategoryIndex == index,
                          selectedColor: roscColor,
                          backgroundColor: Colors.blueGrey[600],
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: Colors.transparent,
                              width: 0,
                            ),
                          ),
                          onSelected: (bool selected) {
                            setState(() {
                              _activeCategoryIndex = index;
                              _loadSubCategories(_categories[index]['id']);
                            });
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _subCategories.map<Widget>((subCategory) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(
                        subCategory['name_sous_categories'],
                        style: TextStyle(
                          color: _activeSubCategory ==
                                  subCategory['name_sous_categories']
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      selected: _activeSubCategory ==
                          subCategory['name_sous_categories'],
                      selectedColor: blueColor,
                      backgroundColor: roscColor,
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Colors.transparent,
                          width: 0,
                        ),
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          _activeSubCategory =
                              subCategory['name_sous_categories'];
                          _loadProducts(
                              _categories[_activeCategoryIndex]
                                  ['name_id_categories'],
                              _activeSubCategory);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 40,
                child: TextField(
                  cursorColor: blueColor,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit',
                    suffixIcon: Icon(Icons.search),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: blueColor),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(
                color: blueColor,
              ))
                  : _isError
                      ? Center(child: Text('Erreur de chargement des données'))
                      : _buildProductList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    List<Product> products = _products;

    if (_searchQuery.isNotEmpty) {
      products = products
          .where((product) =>
              product.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (products.isEmpty) {
      return const Center(
        child: Text(
          'Aucun produit disponible.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return GestureDetector(
          onTap: () {
            _showProductDetails(product);
          },
          child: Card(
            color: Colors.white,
            elevation: 4.0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        product.images.first,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${product.price} FCFA',
                    style: const TextStyle(
                      color: blackprice,
                      fontSize: 18,
                    ),
                  ),
                  if (product.prixPromo != null && product.prixPromo != 0)
                    Text(
                      '${product.prixPromo} FCFA',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Row(
                    children: List.generate(
                      5,
                      (index) {
                        return Icon(
                          index < product.evaluation
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void addToCart(Product product, int quantity, String personalization) {
    Provider.of<CartProvider>(context, listen: false)
        .addToCart(product, quantity, personalization);
    Navigator.of(context).pop();
  }

  void showProductDialog(Product product) {
    int quantity = 1;
    int current = 0;
    bool showFullDescription = false;
    TextEditingController personalizationController = TextEditingController();
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
            vertical: MediaQuery.of(context).size.height * 0.05,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: CarouselSlider(
                                  items: product.images.map((image) {
                                    return Builder(
                                      builder: (BuildContext context) {
                                        return Image.network(
                                          image,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 230,
                                        );
                                      },
                                    );
                                  }).toList(),
                                  options: CarouselOptions(
                                    height: 230,
                                    enlargeCenterPage: true,
                                    autoPlay: false,
                                    aspectRatio: 16 / 9,
                                    viewportFraction: 1.0,
                                    onPageChanged: (index, reason) {
                                      setState(() {
                                        current = index;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Positioned(
                                bottom: 4,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: AnimatedSmoothIndicator(
                                    activeIndex: current,
                                    count: product.images.length,
                                    effect: const ScrollingDotsEffect(
                                      activeDotColor: blueColor,
                                      dotColor: Colors.grey,
                                      dotHeight: 5.0,
                                      dotWidth: 5.0,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                              if (product.info != null)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black12.withOpacity(0.5),
                                      borderRadius: const BorderRadius.only(
                                        bottomRight: Radius.circular(20),
                                        topLeft: Radius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      "Durée: ${product.info}",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black12.withOpacity(0.5),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(20),
                                      topRight: Radius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    "Livraison: ${product.prixLivraison}",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                      (starIndex) {
                                    return Icon(
                                      starIndex < product.evaluation
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${product.price} FCFA',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (quantity > 1) quantity--;
                                      });
                                    },
                                    child: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 17,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    quantity.toString(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        quantity++;
                                      });
                                    },
                                    child: const Icon(
                                      Icons.add_circle_outline,
                                      size: 17,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final span = TextSpan(
                                text: product.description,
                                style: const TextStyle(fontSize: 14),
                              );
                              final tp = TextPainter(
                                maxLines: 2,
                                textAlign: TextAlign.left,
                                textDirection: TextDirection.ltr,
                                text: span,
                              );
                              tp.layout(maxWidth: constraints.maxWidth);
                              bool exceedsLineLimit = tp.didExceedMaxLines;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    showFullDescription
                                        ? product.description
                                        : product.description.length > 90
                                        ? '${product.description.substring(0, 90)}...'
                                        : product.description,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 10),
                                  if (product.description.length > 90 ||
                                      exceedsLineLimit)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          showFullDescription =
                                          !showFullDescription;
                                        });
                                      },
                                      child: Text(
                                        showFullDescription
                                            ? 'Voir moins'
                                            : 'Voir plus',
                                        style: const TextStyle(
                                          color: blueColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          if (product.personnalisable == "yes")
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 9.0),
                                  child: TextField(
                                    controller: personalizationController,
                                    maxLines: 2,
                                    maxLength: 200,
                                    decoration: InputDecoration(
                                      hintMaxLines: 3,
                                      hintStyle: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                      hintText: 'Entrez votre personnalisation',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                ),
                                if (errorMessage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5.0),
                                    child: Text(
                                      errorMessage,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          ourButton(
                            text: "Ajouter au panier",
                            onPressed: () async {
                              if (product.personnalisable == "yes" &&
                                  personalizationController.text.isEmpty) {
                                setState(() {
                                  errorMessage =
                                  "Veuillez entrer votre personnalisation.";
                                });
                              } else {
                                setState(() {
                                  errorMessage = '';
                                });
                                try {
                                  await Provider.of<CartProvider>(context,
                                      listen: false)
                                      .addToCart(product, quantity,
                                      personalizationController.text);
                                  Navigator.of(context).pop(); // Fermeture du dialogue
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                        Text('Produit ajouté au panier')),
                                  );
                                  final CartController cartController = Get.find<CartController>();
                                  cartController.initialize();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Erreur lors de l\'ajout au panier')),
                                  );
                                } finally {
                                  setState(() {
                                  });
                                }
                              }
                            },
                            suffixIcon: Icons.add_shopping_cart,
                            backgroundColor: vertpan,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

}
