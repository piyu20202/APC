import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../detail_view/detail_view.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/cart_service.dart';
import '../../../data/services/cart_payload_builder.dart';
import '../../../services/storage_service.dart';
import '../../../services/navigation_service.dart';

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final double? width;
  final double? height;
  final EdgeInsets? margin;

  const ProductCard({
    super.key,
    required this.product,
    this.width,
    this.height,
    this.margin,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  bool _isQuickAdding = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
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
        width: widget.width,
        // height: widget.height,  // Removed - let content decide height for flexibility
        margin: widget.margin,
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Product Image
            Container(
              height: 120,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8),
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
                      height: 120,
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

                  if (_hasStrikePrice(product))
                    Positioned(
                      top: 12,
                      left: -14,
                      child: Transform.rotate(
                        angle: -0.785398, // -45 degrees in radians
                        child: Container(
                          width: 60,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
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
                                fontSize: 9,
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
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
              padding: const EdgeInsets.fromLTRB(
                8,
                4,
                8,
                0,
              ), // Bottom padding removed
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fixed-height SKU row (1 line space reserved)
                  SizedBox(
                    height: 18,
                    child: (product['sku'] ?? '').toString().trim().isNotEmpty
                        ? Text(
                            'SKU: ${product['sku']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 2),
                  // Fixed-height Title (2 lines)
                  SizedBox(
                    height: 50,
                    child: Text(
                      product['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Fixed-height Description (2 lines) - Reduce height slightly when strike price exists
                  SizedBox(
                    height: _hasStrikePrice(product) ? 50 : 42,
                    child: Text(
                      product['description'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 1),
                  // Price and Cart Row - Fixed height to prevent overflow (always reserve space for strike price)
                  SizedBox(
                    height: 50,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: _hasStrikePrice(product) ? 16 : 0,
                                child: _hasStrikePrice(product)
                                    ? Text(
                                        _formatPrice(
                                          product['previous_price'] ??
                                              product['originalPrice'],
                                        ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              Text(
                                _formatPrice(
                                  product['price'] ??
                                      product['currentPrice'] ??
                                      '',
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _isOutOfStock(product)
                            ? Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.shopping_cart,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              )
                            : GestureDetector(
                                onTap:
                                    (_isQuickAdding || _isOutOfStock(product))
                                    ? null
                                    : () => _handleQuickAdd(context),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _isOutOfStock(product)
                                        ? Colors.grey[400]
                                        : const Color(0xFF151D51),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: _isQuickAdding
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
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
                                            size: 20,
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

    // Check if product is out of stock
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
      if (!context.mounted) return;
      NavigationService.instance.refreshCartCount();
      NavigationService.instance.refreshCartItems();

      NavigationService.instance.switchToTab(
        2,
      ); // Cart is now at index 2 (after removing wishlist)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!context.mounted) return;
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
    // Fall back to string if provided like "$13"
    if (v is String && v.trim().isNotEmpty) return v;
    return '';
  }
  return '\$${n.toStringAsFixed(2)}';
}

Widget _buildProductImage(Map<String, dynamic> product) {
  final thumb = (product['thumbnail'] ?? product['image'])?.toString();
  if (thumb == null || thumb.isEmpty) {
    // Use the provided fallback image URL when thumbnail is empty
    return CachedNetworkImage(
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg',
      width: double.infinity,
      height: 120,
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        width: double.infinity,
        height: 120,
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => SizedBox(
        width: double.infinity,
        height: 120,
        child: _imageFallback(),
      ),
    );
  }

  final isNetwork = thumb.startsWith('http');
  if (isNetwork) {
    return CachedNetworkImage(
      imageUrl: thumb,
      width: double.infinity,
      height: 120,
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        width: double.infinity,
        height: 120,
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => CachedNetworkImage(
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg',
        width: double.infinity,
        height: 120,
        fit: BoxFit.contain,
        errorWidget: (context, url, error) => SizedBox(
          width: double.infinity,
          height: 120,
          child: _imageFallback(),
        ),
      ),
    );
  }

  return Image.asset(
    thumb,
    width: double.infinity,
    height: 120,
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) =>
        SizedBox(width: double.infinity, height: 120, child: _imageFallback()),
  );
}

Widget _imageFallback() {
  return Center(child: Icon(Icons.image, color: Colors.grey[400], size: 40));
}
