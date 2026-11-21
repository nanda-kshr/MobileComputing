import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/category.dart';
import 'package:app/models/product.dart';
import 'package:app/models/cart_item.dart';
import 'package:app/models/order.dart';

void main() {
  group('Category Model', () {
    test('fromJson and toJson', () {
      final json = {
        '_id': 'cat123',
        'name': 'Beverages',
        'description': 'Drinks and juices',
      };
      final cat = Category.fromJson(json);
      expect(cat.id, 'cat123');
      expect(cat.name, 'Beverages');
      expect(cat.description, 'Drinks and juices');

      final serialized = cat.toJson();
      expect(serialized['_id'], 'cat123');
      expect(serialized['name'], 'Beverages');
    });
  });

  group('Product Model', () {
    test('fromJson and copyWith', () {
      final json = {
        '_id': 'prod1',
        'name': 'Arabica Coffee',
        'description': 'Roasted coffee',
        'price': 12.5,
        'category': 'Beverages',
        'stockQuantity': 40,
        'sku': 'COF-01',
      };
      final prod = Product.fromJson(json);
      expect(prod.id, 'prod1');
      expect(prod.name, 'Arabica Coffee');
      expect(prod.price, 12.5);
      expect(prod.stockQuantity, 40);

      final updated = prod.copyWith(stockQuantity: 39);
      expect(updated.stockQuantity, 39);
      expect(updated.name, 'Arabica Coffee');
    });
  });

  group('CartItem Model', () {
    test('subtotal and order item payload', () {
      const prod = Product(
        id: 'p1',
        name: 'Tea',
        description: '',
        price: 4.0,
        category: 'Beverages',
        stockQuantity: 10,
        sku: 'TEA-1',
      );
      final item = CartItem(product: prod, quantity: 3);
      expect(item.subtotal, 12.0);

      final payload = item.toOrderItemPayload();
      expect(payload['productId'], 'p1');
      expect(payload['quantity'], 3);
    });
  });

  group('OrderModel', () {
    test('fromJson creates full order structure', () {
      final json = {
        '_id': 'ord123',
        'items': [
          {
            'productId': 'p1',
            'productName': 'Tea',
            'quantity': 2,
            'price': 4.0,
            'subtotal': 8.0,
          }
        ],
        'subtotal': 8.0,
        'tax': 0.4,
        'total': 8.4,
        'paymentMethod': 'card',
        'status': 'completed',
        'createdAt': '2026-11-21T10:00:00.000Z',
      };
      final order = OrderModel.fromJson(json);
      expect(order.id, 'ord123');
      expect(order.items.length, 1);
      expect(order.items.first.productName, 'Tea');
      expect(order.total, 8.4);
      expect(order.paymentMethod, 'card');
      expect(order.status, 'completed');
    });
  });
}
