import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app/models/product.dart';
import 'package:app/models/cart_item.dart';
import 'package:app/screens/cart_screen.dart';
import 'package:app/services/api_service.dart';

void main() {
  const p1 = Product(
    id: 'p1',
    name: 'Espresso Roast',
    description: 'Fresh coffee',
    price: 10.0,
    category: 'Beverages',
    stockQuantity: 5,
    sku: 'ESP-1',
  );

  const p2 = Product(
    id: 'p2',
    name: 'Blueberry Muffin',
    description: 'Freshly baked',
    price: 4.0,
    category: 'Bakery',
    stockQuantity: 10,
    sku: 'MUF-1',
  );

  testWidgets('CartScreen displays items, calculates subtotal, tax, and total', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response('{}', 200);
    });
    final apiService = ApiService(client: mockClient, baseUrl: 'http://test.local');

    final cartItems = [
      CartItem(product: p1, quantity: 2), // 20.00
      CartItem(product: p2, quantity: 1), // 4.00
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: CartScreen(
          cartItems: cartItems,
          apiService: apiService,
          onUpdateCart: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify item listings
    expect(find.text('Espresso Roast'), findsOneWidget);
    expect(find.text('Blueberry Muffin'), findsOneWidget);

    // Subtotal: 24.00
    // Tax (5%): 1.20
    // Total: 25.20
    expect(find.text('\$24.00'), findsOneWidget);
    expect(find.text('\$1.20'), findsOneWidget);
    expect(find.text('\$25.20'), findsOneWidget);
  });

  testWidgets('CartScreen stepper increments and decrements quantity', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response('{}', 200);
    });
    final apiService = ApiService(client: mockClient, baseUrl: 'http://test.local');

    final cartItems = [
      CartItem(product: p1, quantity: 1),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: CartScreen(
          cartItems: cartItems,
          apiService: apiService,
          onUpdateCart: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Quantity initially 1
    expect(find.text('1'), findsOneWidget);

    // Tap increase (+)
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    // Quantity now 2
    expect(find.text('2'), findsOneWidget);
    expect(find.text('\$20.00'), findsOneWidget); // subtotal updated

    // Tap decrease (-)
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();

    // Quantity back to 1
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('CartScreen completes sale and shows receipt dialog', (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/api/orders') && request.method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['paymentMethod'], 'card');
        return http.Response(
          jsonEncode({
            '_id': 'ord-test-999',
            'items': [
              {
                'productId': 'p1',
                'productName': 'Espresso Roast',
                'quantity': 1,
                'price': 10.0,
                'subtotal': 10.0,
              }
            ],
            'subtotal': 10.0,
            'tax': 0.5,
            'total': 10.5,
            'paymentMethod': 'card',
            'status': 'completed',
          }),
          201,
        );
      }
      return http.Response('Error', 400);
    });

    final apiService = ApiService(client: mockClient, baseUrl: 'http://test.local');
    final cartItems = [
      CartItem(product: p1, quantity: 1),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: CartScreen(
          cartItems: cartItems,
          apiService: apiService,
          onUpdateCart: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Select 'Card' payment method
    await tester.tap(find.text('Card'));
    await tester.pumpAndSettle();

    // Tap Complete Sale
    final completeBtn = find.widgetWithText(ElevatedButton, 'Complete Sale (\$10.50)');
    expect(completeBtn, findsOneWidget);
    await tester.tap(completeBtn);
    await tester.pumpAndSettle();

    // Verify Receipt Dialog is shown
    expect(find.text('Sale Completed!'), findsOneWidget);
    expect(find.text('Receipt #ord-test-999'), findsOneWidget);
    expect(find.text('Payment Method: CARD'), findsOneWidget);
    expect(find.text('Start New Sale'), findsOneWidget);
  });
}
