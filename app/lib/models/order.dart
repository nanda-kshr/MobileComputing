class OrderItemModel {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double subtotal;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: (json['productId'] ?? '').toString(),
      productName: json['productName'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OrderModel {
  final String id;
  final List<OrderItemModel> items;
  final double subtotal;
  final double tax;
  final double total;
  final String paymentMethod;
  final String status;
  final DateTime? createdAt;

  const OrderModel({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.status,
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      status: json['status'] as String? ?? 'completed',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
