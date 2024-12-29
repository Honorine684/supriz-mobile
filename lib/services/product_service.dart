import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/product.dart';
import '../consts/strings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductService {
  final String baseUrl = '$domaineapi';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<dynamic>> fetchCategories() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      print('Categories fetched successfully: ${response.body}');
      return jsonDecode(response.body);
    } else {
      print('Failed to fetch categories: ${response.statusCode} ${response.body}');
      throw Exception('Failed to load categories');
    }
  }

  Future<List<dynamic>> fetchSubCategories(int categoryId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/subcategories/$categoryId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      print('Subcategories fetched successfully: ${response.body}');
      return jsonDecode(response.body);
    } else {
      print('Failed to fetch subcategories: ${response.statusCode} ${response.body}');
      throw Exception('Failed to load subcategories');
    }
  }

  Future<List<Product>> fetchProducts(String categoryName, String subCategoryName) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/products?category_name=$categoryName&subcategory_name=$subCategoryName'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      print('Products fetched successfully: ${response.body}');
      final data = jsonDecode(response.body)['data'] as List;
      return data.map((item) => Product.fromJson(item)).toList();
    } else {
      print('Failed to fetch products: ${response.statusCode} ${response.body}');
      throw Exception('Failed to load products');
    }
  }
}
