import 'package:flutter/material.dart' hide Category;
import '../models/category.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';

class CatalogScreen extends StatefulWidget {
  final ApiService apiService;

  const CatalogScreen({super.key, required this.apiService});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Category> _categories = [];
  final Map<String, CartItem> _cart = {};

  String _selectedCategory = 'All';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categoriesFuture = widget.apiService.fetchCategories();
      final productsFuture = widget.apiService.fetchProducts(
        search: _searchController.text,
        category: _selectedCategory,
      );

      final results = await Future.wait([categoriesFuture, productsFuture]);
      if (!mounted) return;

      setState(() {
        _categories = results[0] as List<Category>;
        _products = results[1] as List<Product>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _searchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await widget.apiService.fetchProducts(
        search: _searchController.text,
        category: _selectedCategory,
      );
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _addToCart(Product product) {
    if (product.stockQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} is out of stock!')),
      );
      return;
    }

    setState(() {
      if (_cart.containsKey(product.id)) {
        final currentQty = _cart[product.id]!.quantity;
        if (currentQty < product.stockQuantity) {
          _cart[product.id]!.quantity += 1;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot add more. Only ${product.stockQuantity} in stock.')),
          );
        }
      } else {
        _cart[product.id] = CartItem(product: product, quantity: 1);
      }
    });
  }

  int get _totalCartItems => _cart.values.fold(0, (sum, item) => sum + item.quantity);
  double get _cartSubtotal => _cart.values.fold(0.0, (sum, item) => sum + item.subtotal);

  void _openCart() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          cartItems: _cart.values.toList(),
          apiService: widget.apiService,
          onUpdateCart: (updatedItems) {
            setState(() {
              _cart.clear();
              for (final item in updatedItems) {
                _cart[item.product.id] = item;
              }
            });
          },
        ),
      ),
    );

    // If sale completed, clear cart and refresh product list to see updated stock
    if (result == true) {
      setState(() {
        _cart.clear();
      });
      _loadCatalog();
    }
  }

  void _showServerSettings() {
    final controller = TextEditingController(text: widget.apiService.baseUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Backend REST API base URL (e.g. http://localhost:3000 or http://10.0.2.2:3000):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Base URL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.apiService.setBaseUrl(controller.text.trim());
              Navigator.pop(context);
              _loadCatalog();
            },
            child: const Text('Save & Reconnect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Catalog'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Server Settings',
            onPressed: _showServerSettings,
          ),
          IconButton(
            icon: Badge(
              label: Text('$_totalCartItems'),
              isLabelVisible: _totalCartItems > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            tooltip: 'Cart & Billing',
            onPressed: _openCart,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchProducts();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _searchProducts(),
              onChanged: (_) {
                setState(() {});
                _searchProducts();
              },
            ),
          ),

          // Categories Filter Row
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == 'All',
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = 'All';
                      });
                      _searchProducts();
                    },
                  ),
                ),
                ..._categories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(cat.name),
                      selected: _selectedCategory == cat.name,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? cat.name : 'All';
                        });
                        _searchProducts();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Product List / State
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadCatalog,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey),
                                const SizedBox(height: 12),
                                const Text(
                                  'No products found',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await widget.apiService.seedData();
                                    _loadCatalog();
                                  },
                                  icon: const Icon(Icons.cloud_download),
                                  label: const Text('Seed Sample Products'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCatalog,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: _products.length,
                              itemBuilder: (context, index) {
                                final product = _products[index];
                                final inCart = _cart[product.id]?.quantity ?? 0;
                                final isOutOfStock = product.stockQuantity <= 0;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Category icon avatar
                                        CircleAvatar(
                                          radius: 26,
                                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                          child: Icon(
                                            Icons.shopping_bag_outlined,
                                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Product Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade200,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      product.category,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey.shade800,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '\$${product.price.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: Theme.of(context).colorScheme.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              // Stock status badge
                                              Row(
                                                children: [
                                                  Icon(
                                                    isOutOfStock
                                                        ? Icons.cancel
                                                        : (product.stockQuantity < 10 ? Icons.warning_amber : Icons.check_circle),
                                                    size: 14,
                                                    color: isOutOfStock
                                                        ? Colors.red
                                                        : (product.stockQuantity < 10 ? Colors.orange : Colors.green),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isOutOfStock
                                                        ? 'Out of Stock'
                                                        : 'Stock: ${product.stockQuantity}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: isOutOfStock
                                                          ? Colors.red
                                                          : (product.stockQuantity < 10 ? Colors.orange.shade800 : Colors.green.shade800),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Add to Cart Button
                                        ElevatedButton(
                                          onPressed: isOutOfStock ? null : () => _addToCart(product),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: inCart > 0
                                              ? Text('In Cart ($inCart)')
                                              : (isOutOfStock
                                                  ? const Text('Sold Out')
                                                  : const Text('Add')),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: _totalCartItems > 0
          ? FloatingActionButton.extended(
              onPressed: _openCart,
              icon: const Icon(Icons.receipt_long),
              label: Text(
                'Checkout ($_totalCartItems) • \$${_cartSubtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
