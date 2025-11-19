import 'package:apcproject/services/storage_service.dart';
import 'package:flutter/material.dart';

import '../drawer_view/drawer.dart';
import '../widget/cart_item_card.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartItems = [];
  double deliveryCost = 0.0;
  bool _isLoading = true;
  String? _errorMessage;
  double? _serverReportedTotal;
  int? _serverReportedQty;
  Map<String, dynamic>? _lastCartResponse;
  final Set<String> _deletingItems = {};

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        title: const Text(
          'Cart',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: null,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : cartItems.isEmpty
          ? _buildEmptyCart()
          : _buildCartWithItems(),
    );
  }

  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final settings = await StorageService.getSettings();
      final defaultImageUrl = settings?.generalSettings.defaultImage;
      final cartResponse =
          await StorageService.getCartData() ?? _mockCartResponse;
      final baseImageUrl = cartResponse['base_url_image'] as String?;
      final parsedItems = _parseCartResponse(
        cartResponse,
        baseImageUrl: baseImageUrl,
        defaultImageUrl: defaultImageUrl,
      );

      setState(() {
        _lastCartResponse = cartResponse;
        cartItems = parsedItems;
        _serverReportedTotal = (cartResponse['totalPrice'] as num?)?.toDouble();
        _serverReportedQty = cartResponse['totalQty'] as int?;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to load cart items. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDeleteItem({
    required String? cartKey,
    required int index,
  }) async {
    if (cartKey == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to delete this item.')),
        );
      }
      return;
    }
    if (_deletingItems.contains(cartKey)) {
      return;
    }

    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) {
      return;
    }

    setState(() {
      _deletingItems.add(cartKey);
    });

    try {
      setState(() {
        cartItems.removeAt(index);
        _serverReportedTotal = _calculateSubtotal();
        _serverReportedQty = _calculateTotalQuantity();
      });

      await _persistCartSnapshot(cartKeyToRemove: cartKey);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to remove item: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingItems.remove(cartKey);
        });
      } else {
        _deletingItems.remove(cartKey);
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove item?'),
            content: const Text(
              'Are you sure you want to remove this item from your cart?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _persistCartSnapshot({required String cartKeyToRemove}) async {
    final updatedResponse = _lastCartResponse != null
        ? Map<String, dynamic>.from(_lastCartResponse!)
        : <String, dynamic>{};

    final cartMap = Map<String, dynamic>.from(
      (updatedResponse['cart'] as Map<String, dynamic>?) ?? {},
    );
    cartMap.remove(cartKeyToRemove);

    updatedResponse['cart'] = cartMap;
    updatedResponse['totalQty'] =
        _serverReportedQty ?? _calculateTotalQuantity();
    updatedResponse['totalPrice'] =
        _serverReportedTotal ?? _calculateSubtotal();

    _lastCartResponse = updatedResponse;
    await StorageService.saveCartData(updatedResponse);
  }

  List<Map<String, dynamic>> _parseCartResponse(
    Map<String, dynamic> cartResponse, {
    String? baseImageUrl,
    String? defaultImageUrl,
  }) {
    final cartMap = cartResponse['cart'];
    if (cartMap is! Map<String, dynamic>) {
      return [];
    }

    final List<Map<String, dynamic>> parsedItems = [];

    for (final entry in cartMap.entries) {
      final value = entry.value;
      if (value is! Map<String, dynamic>) continue;

      final productDetails = value['item'] as Map<String, dynamic>? ?? {};
      final kitItems = _mapKitItems(value['kitCustomiseDetails']);
      final unitPrice = (value['price'] as num?)?.toDouble() ?? 0.0;
      final qty = (value['qty'] as num?)?.toInt() ?? 1;
      final thumbnail = productDetails['thumbnail'] as String?;
      final photo = productDetails['photo'] as String?;
      final resolvedImage = _resolveProductImage(
        baseImageUrl: baseImageUrl,
        thumbnail: thumbnail,
        photo: photo,
        defaultImageUrl: defaultImageUrl,
      );

      parsedItems.add({
        'id': entry.key,
        'productId': productDetails['id'],
        'type': kitItems.isNotEmpty ? 'kit' : 'single',
        'name': productDetails['name'] ?? '',
        'sku': productDetails['sku'] ?? '',
        'image': resolvedImage,
        'defaultImage': defaultImageUrl,
        'price': unitPrice,
        'quantity': qty,
        'kitItems': kitItems,
      });
    }

    return parsedItems;
  }

  List<Map<String, dynamic>> _mapKitItems(dynamic kitDetailsRaw) {
    if (kitDetailsRaw is! Map<String, dynamic>) {
      return [];
    }

    final entries =
        kitDetailsRaw.entries
            .where((entry) => entry.value is Map<String, dynamic>)
            .map(
              (entry) =>
                  MapEntry(entry.key, entry.value as Map<String, dynamic>),
            )
            .toList()
          ..sort((a, b) {
            final aOrder = (a.value['kit_primaryID'] as num?)?.toInt() ?? 0;
            final bOrder = (b.value['kit_primaryID'] as num?)?.toInt() ?? 0;
            return aOrder.compareTo(bOrder);
          });

    int index = 0;
    return entries.map((entry) {
      index++;
      final itemData = entry.value;
      final qty =
          (itemData['productBaseQuantity'] as num?)?.toInt() ??
          (itemData['minimumBaseQuantity'] as num?)?.toInt() ??
          1;
      return {
        'num': index.toString().padLeft(2, '0'),
        'name': itemData['productName'] ?? '',
        'sku': itemData['productSku'] ?? '',
        'qty': qty,
      };
    }).toList();
  }

  int _calculateTotalQuantity() {
    return cartItems.fold(
      0,
      (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
    );
  }

  String? _resolveProductImage({
    String? baseImageUrl,
    String? thumbnail,
    String? photo,
    String? defaultImageUrl,
  }) {
    final sanitizedBase = (baseImageUrl?.isNotEmpty ?? false)
        ? baseImageUrl!.trim()
        : null;
    final sanitizedThumbnail = (thumbnail?.isNotEmpty ?? false)
        ? thumbnail!.trim()
        : null;
    final sanitizedPhoto = (photo?.isNotEmpty ?? false) ? photo!.trim() : null;
    if (sanitizedThumbnail != null) {
      if (sanitizedThumbnail.startsWith('http')) {
        return sanitizedThumbnail;
      }
      if (sanitizedBase != null) {
        final normalizedBase = sanitizedBase.endsWith('/')
            ? sanitizedBase.substring(0, sanitizedBase.length - 1)
            : sanitizedBase;
        final normalizedThumb = sanitizedThumbnail.startsWith('/')
            ? sanitizedThumbnail.substring(1)
            : sanitizedThumbnail;
        return '$normalizedBase/$normalizedThumb';
      }
    }
    if (sanitizedPhoto != null) {
      return sanitizedPhoto;
    }
    if (defaultImageUrl != null && defaultImageUrl.isNotEmpty) {
      return defaultImageUrl;
    }
    return null;
  }

  double _calculateSubtotal() {
    return cartItems.fold(
      0.0,
      (sum, item) =>
          sum +
          (((item['price'] as num?)?.toDouble() ?? 0.0) *
              ((item['quantity'] as num?)?.toDouble() ?? 1.0)),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Looks like you haven\'t added anything yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to catalog/home
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF151D51),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Go to catalog',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadCartItems,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF151D51),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartWithItems() {
    final subtotal = _serverReportedTotal ?? _calculateSubtotal();
    final totalQty = _serverReportedQty ?? _calculateTotalQuantity();
    final total = subtotal + deliveryCost;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cart Items
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final cartKey = item['id'] as String?;
                    return CartItemCard(
                      item: item,
                      index: index,
                      onQuantityDecrease: () {
                        if (item['quantity'] > 1) {
                          setState(() {
                            cartItems[index]['quantity']--;
                            _serverReportedTotal = null;
                            _serverReportedQty = null;
                          });
                        }
                      },
                      onQuantityIncrease: () {
                        setState(() {
                          cartItems[index]['quantity']++;
                          _serverReportedTotal = null;
                          _serverReportedQty = null;
                        });
                      },
                      onDelete: () {
                        if (cartKey != null &&
                            _deletingItems.contains(cartKey)) {
                          return;
                        }
                        _handleDeleteItem(cartKey: cartKey, index: index);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Order Summary
        _buildOrderSummary(subtotal, total, totalQty),
        const SizedBox(height: 20),

        // Checkout Button
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to checkout page
                  Navigator.pushNamed(context, '/checkout');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF151D51),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(double subtotal, double total, int totalQty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items in Cart',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              Text(
                totalQty.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal (GST Incl)',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total cost (GST Incl)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const Map<String, dynamic> _mockCartResponse = {
  'base_url_image':
      'https://gurgaonit.com/apc_production_dev/assets/images/thumbnails',
  'cart': {
    '1364_1763365707': {
      'item_id': '1364_1763365707',
      'qty': 2,
      'price': 795,
      'productItemType': 'kit',
      'kitCustomiseDetails': {
        '1382': {
          'kit_primaryID': 6016,
          'productName':
              'APC Proteous 500 Italian Made FEATURE RICH Sliding Gate Motor',
          'productBaseQuantity': 1,
          'minimumBaseQuantity': 1,
        },
        '1885': {
          'kit_primaryID': 10964,
          'productName':
              'Concrete In Plate for Proteous Siding Gate Motor P500 and P450',
          'productBaseQuantity': 1,
          'minimumBaseQuantity': 1,
        },
        '210': {
          'kit_primaryID': 5759,
          'productName': 'APC Four Button Keyring Remote',
          'productBaseQuantity': 2,
          'minimumBaseQuantity': 2,
        },
        '1914': {
          'kit_primaryID': 11225,
          'productName':
              'Gear Rack Nylon Coated With Steel Core, Strong and Quiet - (1m Pack  - 2 x 50 CM) Made in Italy by Stagnoli',
          'productBaseQuantity': 4,
          'minimumBaseQuantity': 4,
        },
        '1630': {
          'kit_primaryID': 8092,
          'productName':
              'Two FREE Sunvisor Remote Controls (Promotion) with every Electric Gate Automation Kit order.',
          'productBaseQuantity': 2,
          'minimumBaseQuantity': 2,
        },
      },
      'item': {
        'id': 1364,
        'sku': 'APC-P500-DC-KB',
        'name':
            'Build Your Own Electric Gate Kit with APC Proteous 500 FEATURE RICH AC to 24V DC Extra Heavy Duty FEATURE RICH Automatic Sliding Gate Kit with Encoder System',
        'price': 795,
        'photo': 'assets/images/product.jpg',
        'thumbnail': '1673928881RL5c8o9k.jpg',
      },
    },
  },
  'totalQty': 2,
  'totalPrice': 1590,
};
