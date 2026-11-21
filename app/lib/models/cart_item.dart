import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get subtotal => product.price * quantity;

  Map<String, dynamic> toOrderItemPayload() {
    return {
      'productId': product.id,
      'quantity': quantity,
    };
  }
}
