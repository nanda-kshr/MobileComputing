import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class CartScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final ApiService apiService;
  final ValueChanged<List<CartItem>> onUpdateCart;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.apiService,
    required this.onUpdateCart,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartItem> _items;
  String _selectedPaymentMethod = 'cash';
  bool _isProcessingSale = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.cartItems);
  }

  double get _subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get _tax => double.parse((_subtotal * 0.05).toStringAsFixed(2));
  double get _total => double.parse((_subtotal + _tax).toStringAsFixed(2));

  void _incrementItem(CartItem item) {
    if (item.quantity < item.product.stockQuantity) {
      setState(() {
        item.quantity += 1;
      });
      widget.onUpdateCart(_items);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot add more. Max stock is ${item.product.stockQuantity}.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _decrementItem(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity -= 1;
      } else {
        _items.remove(item);
      }
    });
    widget.onUpdateCart(_items);
  }

  void _removeItem(CartItem item) {
    setState(() {
      _items.remove(item);
    });
    widget.onUpdateCart(_items);
  }

  Future<void> _completeSaleTransaction() async {
    if (_items.isEmpty) return;

    setState(() {
      _isProcessingSale = true;
    });

    try {
      final order = await widget.apiService.createOrder(
        items: _items,
        paymentMethod: _selectedPaymentMethod,
      );

      if (!mounted) return;
      setState(() {
        _isProcessingSale = false;
      });

      _showReceiptDialog(order);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingSale = false;
      });

      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Checkout Error'),
            ],
          ),
          content: Text(errorMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showReceiptDialog(OrderModel order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Sale Completed!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Receipt #${order.id}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              const Divider(height: 20),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.productName} x${item.quantity}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:', style: TextStyle(fontSize: 13)),
                  Text('\$${order.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tax (5%):', style: TextStyle(fontSize: 13)),
                  Text('\$${order.tax.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Paid:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Payment Method: ${order.paymentMethod.toUpperCase()}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to catalog with sale completed flag
            },
            child: const Text('Start New Sale'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Billing & Cart'),
      ),
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.remove_shopping_cart, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No items in cart',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Return to Catalog'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Cart items list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${item.product.price.toStringAsFixed(2)} each',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                    Text(
                                      'Subtotal: \$${item.subtotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Stepper Controls
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () => _decrementItem(item),
                                    tooltip: 'Decrease',
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                    onPressed: () => _incrementItem(item),
                                    tooltip: 'Increase',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                    onPressed: () => _removeItem(item),
                                    tooltip: 'Remove',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bill Totals & Checkout Panel
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Payment Method Selector
                      const Text(
                        'Payment Method',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildPaymentChoice('cash', 'Cash', Icons.payments_outlined),
                          const SizedBox(width: 8),
                          _buildPaymentChoice('card', 'Card', Icons.credit_card_outlined),
                          const SizedBox(width: 8),
                          _buildPaymentChoice('upi', 'UPI', Icons.qr_code_scanner),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Bill Calculation Breakdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                          Text('\$${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax (5%):', style: TextStyle(fontSize: 14)),
                          Text('\$${_tax.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bill Total:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            '\$${_total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Complete Sale Button
                      ElevatedButton(
                        onPressed: _isProcessingSale ? null : _completeSaleTransaction,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isProcessingSale
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Complete Sale (\$${_total.toStringAsFixed(2)})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPaymentChoice(String method, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == method;
    return Expanded(
      child: ChoiceChip(
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedPaymentMethod = method;
            });
          }
        },
      ),
    );
  }
}
