import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../detail_view/detail_view.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/cart_service.dart';
import '../../../data/services/cart_payload_builder.dart';
import '../../../services/storage_service.dart';
import '../../../services/navigation_service.dart';

class ListingProductCard extends StatefulWidget {
  final Map<String, dynamic> product;

  const ListingProductCard({super.key, required this.product});

  @override
  State<ListingProductCard> createState() => _ListingProductCardState();
}

class _ListingProductCardState extends State<ListingProductCard> {
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  bool _isQuickAdding = false;

  void _showWishlistComingSoon() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wishlist is under development and will be available soon.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isOnSale = _hasStrikePrice(product) || product['onSale'] == true;

    return GestureDetector(
      onTap: () {
        final productId = product['id'] as int?;
        if (productId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailView(productId: productId),
            ),
          );
        }
      },
      child: Container(
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Wishlist icon
            Padding(
              padding: const EdgeInsets.only(left: 6, right: 6, top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _showWishlistComingSoon,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 0.5,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        color: Colors.red[300],
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            // Product Image
            Container(
              height: 105,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(5),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: SizedBox(
                      width: double.infinity,
                      height: 105,
                      child: _isOutOfStock(product)
                          ? ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                Colors.grey,
                                BlendMode.saturation,
                              ),
                              child: Opacity(
                                opacity: 0.6,
                                child: _buildProductImage(product),
                              ),
                            )
                          : _buildProductImage(product),
                    ),
                  ),
                  // SALE Badge (rotated) - only if on sale
                  if (isOnSale)
                    Positioned(
                      top: 8,
                      left: -10,
                      child: Transform.rotate(
                        angle: -0.785398, // -45 degrees
                        child: Container(
                          width: 50,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 0.5,
                                blurRadius: 1,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'SALE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 8,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Out of Stock Badge
                  if (_isOutOfStock(product))
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product Details
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // SKU row
                  SizedBox(
                    height: 13,
                    child: (product['sku'] ?? '').toString().trim().isNotEmpty
                        ? Text(
                            'SKU: ${product['sku']}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 2),
                  // Title
                  SizedBox(
                    height: 32,
                    child: Text(
                      product['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Description
                  SizedBox(
                    height: isOnSale ? 32 : 32,
                    child: Text(
                      product['description'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Price and Cart Row
                  SizedBox(
                    height: isOnSale ? 34 : 32,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Strike-through price (only if on sale)
                              if (isOnSale)
                                SizedBox(
                                  height: 13,
                                  child: Text(
                                    _formatPrice(
                                      product['previous_price'] ??
                                          product['originalPrice'],
                                    ),
                                    style: TextStyle(
                                      fontSize: 10,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              if (isOnSale) const SizedBox(height: 1),
                              Text(
                                _formatPrice(
                                  product['price'] ??
                                      product['currentPrice'] ??
                                      '',
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        _isOutOfStock(product)
                            ? Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.shopping_cart,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                ),
                              )
                            : GestureDetector(
                                onTap:
                                    (_isQuickAdding || _isOutOfStock(product))
                                    ? null
                                    : () => _handleQuickAdd(context),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: _isOutOfStock(product)
                                        ? Colors.grey[400]
                                        : const Color(0xFF151D51),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Center(
                                    child: _isQuickAdding
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Icon(
                                            _isOutOfStock(product)
                                                ? Icons.block
                                                : Icons.shopping_cart,
                                            color: Colors.white,
                                            size: 17,
                                          ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleQuickAdd(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final productId = widget.product['id'] as int?;
    if (productId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Product identifier missing')),
      );
      return;
    }

    if (_isOutOfStock(widget.product)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('This product is out of stock'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isQuickAdding = true;
    });

    try {
      final detailResponse = await _productService.getProductDetails(productId);
      final builder = CartPayloadBuilder(
        product: detailResponse.product,
        qtyUpgradeProducts: detailResponse.qtyUpgradeProducts,
        upgradeProducts: detailResponse.upgradeProducts,
        addonProducts: detailResponse.addonProducts,
        kitQuantity: 1,
        selectedQtyForCustomise: {
          for (final item in detailResponse.qtyUpgradeProducts)
            item.id: item.productBaseQuantity,
        },
        selectedUpgradeIndex: -1,
        selectedSubProductIndex: {
          for (final upgrade in detailResponse.upgradeProducts) upgrade.id: -1,
        },
        addOnSelections: List<bool>.filled(
          detailResponse.addonProducts.length,
          false,
        ),
        addOnQuantities: List<int>.filled(
          detailResponse.addonProducts.length,
          1,
        ),
      );
      final payload = await builder.buildPayload();
      final response = await _cartService.addProducts(payload);
      await StorageService.saveCartData(response);
      NavigationService.instance.refreshCartCount();
      NavigationService.instance.refreshCartItems();

      NavigationService.instance.switchToTab(3);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to add to cart: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isQuickAdding = false;
        });
      } else {
        _isQuickAdding = false;
      }
    }
  }
}

bool _hasStrikePrice(Map<String, dynamic> product) {
  final prev = _readNum(product['previous_price'] ?? product['originalPrice']);
  final price = _readNum(product['price'] ?? product['currentPrice']);
  return prev > 0 && prev > price;
}

bool _isOutOfStock(Map<String, dynamic> product) {
  final outOfStock = product['out_of_stock'];
  if (outOfStock == null) return false;
  if (outOfStock is int) return outOfStock == 1;
  if (outOfStock is bool) return outOfStock;
  if (outOfStock is String) {
    return outOfStock == '1' || outOfStock.toLowerCase() == 'true';
  }
  return false;
}

num _readNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  final s = v.toString().replaceAll(RegExp(r'[^0-9.-]'), '');
  return num.tryParse(s) ?? 0;
}

String _formatPrice(dynamic v) {
  final n = _readNum(v);
  if (n == 0) {
    if (v is String && v.trim().isNotEmpty) return v;
    return '';
  }
  return '\$${n.toStringAsFixed(0)}';
}

Widget _buildProductImage(Map<String, dynamic> product) {
  final thumb = (product['thumbnail'] ?? product['image'])?.toString();
  if (thumb == null || thumb.isEmpty) {
    return CachedNetworkImage(
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg',
      width: double.infinity,
      height: 105,
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        width: double.infinity,
        height: 105,
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: double.infinity,
        height: 105,
        child: _imageFallback(),
      ),
    );
  }

  final isNetwork = thumb.startsWith('http');
  if (isNetwork) {
    return CachedNetworkImage(
      imageUrl: thumb,
      width: double.infinity,
      height: 105,
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        width: double.infinity,
        height: 105,
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => CachedNetworkImage(
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg',
        width: double.infinity,
        height: 105,
        fit: BoxFit.contain,
        errorWidget: (context, url, error) => Container(
          width: double.infinity,
          height: 105,
          child: _imageFallback(),
        ),
      ),
    );
  }

  return Image.asset(
    thumb,
    width: double.infinity,
    height: 105,
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) =>
        Container(width: double.infinity, height: 105, child: _imageFallback()),
  );
}

Widget _imageFallback() {
  return Center(child: Icon(Icons.image, color: Colors.grey[400], size: 35));
}
