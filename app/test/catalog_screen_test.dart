import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app/screens/catalog_screen.dart';
import 'package:app/services/api_service.dart';

void main() {
  final sampleCategories = [
    {'_id': 'c1', 'name': 'Beverages', 'description': 'Drinks'},
    {'_id': 'c2', 'name': 'Bakery', 'description': 'Pastries'},
  ];

  final sampleProducts = [
    {
      '_id': 'p1',
      'name': 'Coffee Beans',
      'description': 'Dark roast',
      'price': 10.0,
      'category': 'Beverages',
      'stockQuantity': 15,
      'sku': 'COF-1',
    },
    {
      '_id': 'p2',
      'name': 'Croissant',
      'description': 'Butter croissant',
      'price': 3.5,
      'category': 'Bakery',
      'stockQuantity': 0,
      'sku': 'BAK-1',
    },
  ];

  testWidgets('CatalogScreen renders products, search, categories, and handles Add to Cart', (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/api/categories')) {
        return http.Response(jsonEncode(sampleCategories), 200);
      }
      if (request.url.path.endsWith('/api/products')) {
        return http.Response(jsonEncode(sampleProducts), 200);
      }
      return http.Response('Not Found', 404);
    });

    final apiService = ApiService(client: mockClient, baseUrl: 'http://test.local');

    await tester.pumpWidget(
      MaterialApp(
        home: CatalogScreen(apiService: apiService),
      ),
    );

    // Initial pump & settle
    await tester.pumpAndSettle();

    // Verify Title & Search Bar
    expect(find.text('Product Catalog'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Verify Category Filter Chips
    expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Beverages'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Bakery'), findsOneWidget);

    // Verify Products rendered
    expect(find.text('Coffee Beans'), findsOneWidget);
    expect(find.text('\$10.00'), findsOneWidget);
    expect(find.text('Stock: 15'), findsOneWidget);

    // Verify Out of Stock product
    expect(find.text('Croissant'), findsOneWidget);
    expect(find.text('Out of Stock'), findsOneWidget);

    // Add Coffee Beans to cart
    final addButton = find.widgetWithText(ElevatedButton, 'Add');
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Verify button state changes to "In Cart (1)"
    expect(find.text('In Cart (1)'), findsOneWidget);

    // Verify Floating Action Button displays checkout with total
    expect(find.textContaining('Checkout (1) • \$10.00'), findsOneWidget);
  });

  testWidgets('CatalogScreen displays empty state when no products found', (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/api/categories')) {
        return http.Response(jsonEncode([]), 200);
      }
      if (request.url.path.endsWith('/api/products')) {
        return http.Response(jsonEncode([]), 200);
      }
      return http.Response('Not Found', 404);
    });

    final apiService = ApiService(client: mockClient, baseUrl: 'http://test.local');

    await tester.pumpWidget(
      MaterialApp(
        home: CatalogScreen(apiService: apiService),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No products found'), findsOneWidget);
    expect(find.text('Seed Sample Products'), findsOneWidget);
  });

  testWidgets('CatalogScreen displays error state with Retry button on API failure', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response('Network timeout', 500);
    });

    final apiService = ApiService(client: mockClient, baseUrl: 'http://test.local');

    await tester.pumpWidget(
      MaterialApp(
        home: CatalogScreen(apiService: apiService),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
