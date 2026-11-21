import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class ApiService {
  final http.Client client;
  String _baseUrl;

  ApiService({http.Client? client, String? baseUrl})
      : client = client ?? http.Client(),
        _baseUrl = baseUrl ?? _getDefaultBaseUrl();

  static String _getDefaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000';
      }
    } catch (_) {
      // In web or tests where Platform isn't supported
    }
    return 'http://localhost:3000';
  }

  String get baseUrl => _baseUrl;

  void setBaseUrl(String newUrl) {
    if (newUrl.endsWith('/')) {
      _baseUrl = newUrl.substring(0, newUrl.length - 1);
    } else {
      _baseUrl = newUrl;
    }
  }

  Future<List<Product>> fetchProducts({String? search, String? category}) async {
    final queryParams = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['q'] = search.trim();
    }
    if (category != null && category.trim().isNotEmpty && category != 'All') {
      queryParams['category'] = category.trim();
    }

    final uri = Uri.parse('$_baseUrl/api/products').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load products: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<Category>> fetchCategories() async {
    final uri = Uri.parse('$_baseUrl/api/categories');
    final response = await client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load categories: ${response.statusCode} - ${response.body}');
    }
  }

  Future<OrderModel> createOrder({
    required List<CartItem> items,
    required String paymentMethod,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/orders');
    final payload = {
      'items': items.map((item) => item.toOrderItemPayload()).toList(),
      'paymentMethod': paymentMethod,
    };

    final response = await client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return OrderModel.fromJson(data);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        }
      } catch (e) {
        if (e is! FormatException) rethrow;
      }
      throw Exception('Failed to process order (${response.statusCode}): ${response.body}');
    }
  }

  Future<bool> seedData() async {
    final uri = Uri.parse('$_baseUrl/api/seed?force=true');
    final response = await client.post(uri);
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
