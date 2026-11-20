import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductApi {
  static const endpoint = String.fromEnvironment(
    'GAIA_API_BASE_URL',
    defaultValue: 'https://danar-iqbal-gaia.pws.cs.ui.ac.id/api/products/',
  );

  Future<List<Product>> fetchProducts() async {
    final response = await http
        .get(Uri.parse(endpoint))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Server mengembalikan status ${response.statusCode}.');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final rows = decoded is List ? decoded : (decoded['results'] as List);
    return rows
        .map((row) => Product.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
