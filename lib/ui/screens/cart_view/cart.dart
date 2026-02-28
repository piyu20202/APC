import 'dart:convert';

import 'package:apcproject/data/services/cart_service.dart';
import 'package:apcproject/services/storage_service.dart';
import 'package:apcproject/services/navigation_service.dart';
import 'package:flutter/material.dart';
import '../../../core/network/network_checker.dart';

import '../drawer_view/drawer.dart';
import '../widget/app_state_view.dart';
import '../widget/cart_item_card.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();
  List<Map<String, dynamic>> cartItems = [];
  double deliveryCost = 0.0;
  bool _isLoading = true;
  String? _errorMessage;
  double? _serverReportedTotal;
  int? _serverReportedQty;
  Map<String, dynamic>? _lastCartResponse;
  final Set<String> _deletingItems = {};
  bool _isCheckoutSubmitting = false;
  final List<int> _removedProductIds = [];
  final List<String> _removedCartItemIds = [];
  final Map<String, int> _quantityChanges = {};
  final Map<String, double> _unitPrices = {};

  @override
  void initState() {
    super.initState();
    NavigationService.instance.registerCartItemsRefresher(() {
      if (mounted) {
        _loadCartItems();
      }
    });
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
      body: RefreshIndicator.adaptive(
        onRefresh: _onRefreshCart,
        child: _isLoading
            ? const CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppStateView(state: AppViewState.loading),
                  ),
                ],
              )
            : (_errorMessage != null)
            ? CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppStateView(
                      state: AppViewState.error,
                      title: 'Unable to load cart',
                      message: _errorMessage,
                      primaryActionLabel: 'Retry',
                      onPrimaryAction: _loadCartItems,
                    ),
                  ),
                ],
              )
            : (cartItems.isEmpty)
            ? CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppStateView(
                      state: AppViewState.empty,
                      title: 'Your cart is empty',
                      message:
                          'Looks like you have not added anything to the cart. Go ahead & explore categories',
                      primaryActionLabel: 'Go to Shopping',
                      onPrimaryAction: () {
                        // In this app, the "catalog" lives on the Home tab.
                        // Using Navigator.pop() here can pop the root route (black screen)
                        // when Cart is shown as a bottom-tab screen.
                        NavigationService.instance.switchToTab(0);

                        final navigator = Navigator.of(context);
                        if (navigator.canPop()) {
                          navigator.popUntil((route) => route.isFirst);
                        }
                      },
                    ),
                  ),
                ],
              )
            : _buildCartWithItems(),
      ),
    );
  }

  Future<void> _onRefreshCart() async {
    // Cart is local-first in this app, but still check connectivity to give
    // a clear message when user expects a server refresh.
    final hasInternet = await NetworkChecker.hasConnection();
    if (!hasInternet) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Refreshing local cart…'),
          ),
        );
      }
    }
    await _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final settings = await StorageService.getSettings();
      final defaultImageUrl = settings?.generalSettings.defaultImage;
      final cartResponse = await StorageService.getCartData();
      if (cartResponse == null) {
        setState(() {
          _lastCartResponse = null;
          cartItems = [];
          _serverReportedTotal = 0;
          _serverReportedQty = 0;
          _unitPrices.clear();
          _quantityChanges.clear();
          _removedProductIds.clear();
          _removedCartItemIds.clear();
        });
        return;
      }
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
        _unitPrices
          ..clear()
          ..addAll(_deriveUnitPriceMap(parsedItems));
        _quantityChanges.clear();
        _removedProductIds.clear();
        _removedCartItemIds.clear();
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
    bool hasAddons = false,
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

    final confirmed = await _showDeleteConfirmation(hasAddons: hasAddons);
    if (!confirmed) {
      return;
    }

    setState(() {
      _deletingItems.add(cartKey);
    });

    try {
      // If deleting main product with add-ons, also delete all add-ons
      final List<String> keysToRemove = [cartKey];
      final List<int> indicesToRemove = [index];

      if (hasAddons) {
        // Find all add-on items that have this cart key as parent
        for (int i = 0; i < cartItems.length; i++) {
          final item = cartItems[i];
          final parentKey = item['parentCartKey'] as String?;
          if (parentKey == cartKey) {
            keysToRemove.add(item['id'] as String);
            indicesToRemove.add(i);
          }
        }
      }

      setState(() {
        // Remove items in reverse order to maintain correct indices
        indicesToRemove.sort((a, b) => b.compareTo(a));
        for (final idx in indicesToRemove) {
          if (idx < cartItems.length) {
            final removedItem = cartItems[idx];
            final removedId = removedItem['itemId'] as String?;
            final removedProductId = (removedItem['productId'] as num?)
                ?.toInt();

            cartItems.removeAt(idx);

            if (removedProductId != null &&
                !_removedProductIds.contains(removedProductId)) {
              _removedProductIds.add(removedProductId);
            }
            if (removedId != null) {
              if (!_removedCartItemIds.contains(removedId)) {
                _removedCartItemIds.add(removedId);
              }
              _quantityChanges.remove(removedId);
              _unitPrices.remove(removedId);
            }
          }
        }
        _serverReportedTotal = _calculateSubtotal();
        _serverReportedQty = _calculateTotalQuantity();
      });

      // Persist removal of all keys
      for (final key in keysToRemove) {
        await _persistCartSnapshot(cartKeyToRemove: key);
      }
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

  Future<bool> _showDeleteConfirmation({bool hasAddons = false}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove item?'),
            content: Text(
              hasAddons
                  ? 'This will also remove all associated add-on products. Are you sure?'
                  : 'Are you sure you want to remove this item from your cart?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  hasAddons ? 'Remove All' : 'Remove',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
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
    NavigationService.instance.refreshCartCount();
    NavigationService.instance.refreshCartItems();
  }

  Future<void> _persistQuantitySnapshot() async {
    if (_lastCartResponse == null) return;

    final updatedResponse =
        Map<String, dynamic>.from(_lastCartResponse!);
    final cartMap = Map<String, dynamic>.from(
      (updatedResponse['cart'] as Map<String, dynamic>?) ?? {},
    );

    for (final item in cartItems) {
      final key = item['id'];
      if (key == null) continue;
      final quantity = item['quantity'];

      if (cartMap[key] is Map<String, dynamic>) {
        final entry =
            Map<String, dynamic>.from(cartMap[key] as Map<String, dynamic>);
        entry['qty'] = quantity;
        cartMap[key] = entry;
      }
    }

    updatedResponse['cart'] = cartMap;
    updatedResponse['totalQty'] = _calculateTotalQuantity();
    updatedResponse['totalPrice'] = _calculateSubtotal();

    _lastCartResponse = updatedResponse;
    await StorageService.saveCartData(updatedResponse);
    NavigationService.instance.refreshCartCount();
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
      final itemId = (value['item_id'] ?? entry.key).toString();
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

      // Check if this is an add-on product (has addon_ prefix in cart key)
      final isAddon =
          value['is_addon'] == 1 || entry.key.toString().contains('addon_');
      final parentCartKey = value['parent_cart_key'] as String?;

      parsedItems.add({
        'id': entry.key,
        'itemId': itemId,
        'productId': productDetails['id'],
        'type': kitItems.isNotEmpty ? 'kit' : 'single',
        'name': productDetails['name'] ?? '',
        'sku': productDetails['sku'] ?? '',
        'image': resolvedImage,
        'defaultImage': defaultImageUrl,
        'price': unitPrice,
        'quantity': qty,
        'kitItems': kitItems,
        'isAddon': isAddon,
        'parentCartKey': parentCartKey,
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
    return cartItems.fold(0, (sum, item) {
      final quantity = item['quantity'];
      if (quantity is num) {
        return sum + quantity.round();
      }
      if (quantity is String) {
        return sum + (int.tryParse(quantity) ?? 0);
      }
      return sum;
    });
  }

  Map<String, double> _deriveUnitPriceMap(List<Map<String, dynamic>> items) {
    final map = <String, double>{};
    for (final item in items) {
      final itemId = item['itemId'] as String?;
      if (itemId != null) {
        map[itemId] = (item['price'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return map;
  }

  void _recordQuantityChange(String itemId, int delta) {
    if (delta == 0) {
      return;
    }
    final updatedValue = (_quantityChanges[itemId] ?? 0) + delta;
    if (updatedValue == 0) {
      _quantityChanges.remove(itemId);
    } else {
      _quantityChanges[itemId] = updatedValue;
    }
  }

  Future<Map<String, dynamic>> _buildUpdatePayload() async {
    dynamic oldCartPayload = '';

    Map<String, dynamic>? storedCartResponse =
        await StorageService.getCartData();
    storedCartResponse ??= _lastCartResponse;

    if (storedCartResponse != null) {
      final cartEntries = storedCartResponse['cart'];
      if (cartEntries is Map<String, dynamic>) {
        oldCartPayload = cartEntries;
      }
    }

    final removeProductActions = _removedCartItemIds
        .map((id) => {'id': id})
        .toList();

    final List<Map<String, dynamic>> increaseProductActions = [];
    final List<Map<String, dynamic>> decreaseProductActions = [];

    _quantityChanges.forEach((itemId, qtyChange) {
      final unitPrice = _unitPrices[itemId] ?? 0.0;
      if (qtyChange > 0) {
        increaseProductActions.add({
          'id': itemId,
          'qty': qtyChange,
          'price': unitPrice,
        });
      } else if (qtyChange < 0) {
        decreaseProductActions.add({
          'id': itemId,
          'qty': qtyChange.abs(),
          'price': unitPrice,
        });
      }
    });

    return {
      'old_cart': oldCartPayload,
      'actions': {
        'remove_product': removeProductActions,
        'increase_product': increaseProductActions,
        'decrease_product': decreaseProductActions,
      },
    };
  }

  Future<void> _handleCheckout() async {
    if (_isCheckoutSubmitting) {
      return;
    }

    setState(() {
      _isCheckoutSubmitting = true;
    });

    try {
      final payload = await _buildUpdatePayload();

      // Log POST body
      final prettyPayload = const JsonEncoder.withIndent('  ').convert(payload);
      debugPrint('************checkout post body start************');
      debugPrint(prettyPayload);
      debugPrint('*************checkout post body end***********');

      final response = await _cartService.updateCart(payload);

      // Log API response
      final prettyResponse = const JsonEncoder.withIndent(
        '  ',
      ).convert(response);
      debugPrint('=== CHECKOUT - API RESPONSE ===');
      debugPrint(prettyResponse);
      debugPrint('==============================');

      await StorageService.saveCartData(response);
      NavigationService.instance.refreshCartCount();
      NavigationService.instance.refreshCartItems();

      final settings = await StorageService.getSettings();
      final defaultImageUrl = settings?.generalSettings.defaultImage;
      final baseImageUrl = response['base_url_image'] as String?;
      final refreshedItems = _parseCartResponse(
        response,
        baseImageUrl: baseImageUrl,
        defaultImageUrl: defaultImageUrl,
      );

      if (!mounted) return;
      setState(() {
        _lastCartResponse = response;
        cartItems = refreshedItems;
        _serverReportedTotal = (response['totalPrice'] as num?)?.toDouble();
        _serverReportedQty = response['totalQty'] as int?;
        _unitPrices
          ..clear()
          ..addAll(_deriveUnitPriceMap(refreshedItems));
        _quantityChanges.clear();
        _removedProductIds.clear();
        _removedCartItemIds.clear();
      });

      if (!mounted) return;
      Navigator.pushNamed(context, '/checkout');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to update cart: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckoutSubmitting = false;
        });
      } else {
        _isCheckoutSubmitting = false;
      }
    }
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

  List<Map<String, dynamic>> _groupCartItems() {
    final List<Map<String, dynamic>> grouped = [];
    final Set<String> processedAddons = {};

    for (final item in cartItems) {
      final isAddon = item['isAddon'] == true;
      final cartKey = item['id'] as String;

      // Skip if this addon was already processed as part of a main product group
      if (isAddon && processedAddons.contains(cartKey)) {
        continue;
      }

      if (!isAddon) {
        // This is a main product, find its add-ons
        final List<Map<String, dynamic>> relatedAddons = [];

        for (final potentialAddon in cartItems) {
          final potentialAddonIsAddon = potentialAddon['isAddon'] == true;
          final parentKey = potentialAddon['parentCartKey'] as String?;

          if (potentialAddonIsAddon && parentKey == cartKey) {
            relatedAddons.add(potentialAddon);
            processedAddons.add(potentialAddon['id'] as String);
          }
        }

        grouped.add({'main': item, 'addons': relatedAddons});
      } else if (!processedAddons.contains(cartKey)) {
        // This is an orphaned add-on (no parent found), treat as standalone
        grouped.add({'main': item, 'addons': []});
        processedAddons.add(cartKey);
      }
    }

    return grouped;
  }

  Widget _buildCartWithItems() {
    final subtotal = _serverReportedTotal ?? _calculateSubtotal();
    final totalQty = _calculateTotalQuantity();
    final total = subtotal + deliveryCost;

    // Group items: main products with their add-ons
    final groupedItems = _groupCartItems();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, groupIndex) {
              final group = groupedItems[groupIndex];
              final mainItem = group['main'] as Map<String, dynamic>;
              final addons =
                  (group['addons'] as List<Map<String, dynamic>>?) ?? [];
              final mainIndex = cartItems.indexWhere(
                (item) => item['id'] == mainItem['id'],
              );
              final cartKey = mainItem['id'] as String?;

              return Column(
                children: [
                  // Main product
                  CartItemCard(
                    item: mainItem,
                    index: mainIndex,
                    isMainProduct: addons.isNotEmpty,
                    onQuantityDecrease: () {
                      final itemId = cartItems[mainIndex]['itemId'] as String?;
                      final currentQty =
                          (cartItems[mainIndex]['quantity'] as num?)?.toInt() ??
                          1;
                      if (currentQty > 1) {
                        setState(() {
                          cartItems[mainIndex]['quantity'] = currentQty - 1;
                          _serverReportedTotal = null;
                          _serverReportedQty = null;
                        });
                        if (itemId != null) {
                          _recordQuantityChange(itemId, -1);
                        }
                    // Keep cart badge in sync with quantity changes
                    _persistQuantitySnapshot();
                      }
                    },
                    onQuantityIncrease: () {
                      final itemId = cartItems[mainIndex]['itemId'] as String?;
                      final currentQty =
                          (cartItems[mainIndex]['quantity'] as num?)?.toInt() ??
                          0;
                      setState(() {
                        cartItems[mainIndex]['quantity'] = currentQty + 1;
                        _serverReportedTotal = null;
                        _serverReportedQty = null;
                      });
                      if (itemId != null) {
                        _recordQuantityChange(itemId, 1);
                      }
                  // Keep cart badge in sync with quantity changes
                  _persistQuantitySnapshot();
                    },
                    onDelete: () {
                      if (cartKey != null && _deletingItems.contains(cartKey)) {
                        return;
                      }
                      _handleDeleteItem(
                        cartKey: cartKey,
                        index: mainIndex,
                        hasAddons: addons.isNotEmpty,
                      );
                    },
                  ),

                  // Add-on products
                  ...addons.map((addonItem) {
                    final addonIndex = cartItems.indexWhere(
                      (item) => item['id'] == addonItem['id'],
                    );
                    final addonCartKey = addonItem['id'] as String?;

                    return CartItemCard(
                      item: addonItem,
                      index: addonIndex,
                      isAddonProduct: true,
                      onQuantityDecrease: () {
                        final itemId =
                            cartItems[addonIndex]['itemId'] as String?;
                        final currentQty =
                            (cartItems[addonIndex]['quantity'] as num?)
                                ?.toInt() ??
                            1;
                        if (currentQty > 1) {
                          setState(() {
                            cartItems[addonIndex]['quantity'] = currentQty - 1;
                            _serverReportedTotal = null;
                            _serverReportedQty = null;
                          });
                          if (itemId != null) {
                            _recordQuantityChange(itemId, -1);
                          }
                          // Keep cart badge in sync with quantity changes
                          _persistQuantitySnapshot();
                        }
                      },
                      onQuantityIncrease: () {
                        final itemId =
                            cartItems[addonIndex]['itemId'] as String?;
                        final currentQty =
                            (cartItems[addonIndex]['quantity'] as num?)
                                ?.toInt() ??
                            0;
                        setState(() {
                          cartItems[addonIndex]['quantity'] = currentQty + 1;
                          _serverReportedTotal = null;
                          _serverReportedQty = null;
                        });
                        if (itemId != null) {
                          _recordQuantityChange(itemId, 1);
                        }
                        // Keep cart badge in sync with quantity changes
                        _persistQuantitySnapshot();
                      },
                      onDelete: () {
                        if (addonCartKey != null &&
                            _deletingItems.contains(addonCartKey)) {
                          return;
                        }
                        _handleDeleteItem(
                          cartKey: addonCartKey,
                          index: addonIndex,
                        );
                      },
                    );
                  }),
                ],
              );
            }, childCount: groupedItems.length),
          ),
        ),

        // Order Summary
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildOrderSummary(subtotal, total, totalQty),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // Checkout Button
        SliverToBoxAdapter(
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
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
                  onPressed: _isCheckoutSubmitting ? null : _handleCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF151D51),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCheckoutSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
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
            color: Colors.grey.withValues(alpha: 0.1),
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
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
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
