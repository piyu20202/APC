import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:marquee/marquee.dart';
import '../detail_view/detail_view.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/cart_service.dart';
import '../../../data/services/cart_payload_builder.dart';
import '../../../services/storage_service.dart';
import '../../../services/navigation_service.dart';
import 'cart_feedback_overlay.dart';

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

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isOnSale = _hasStrikePrice(product) || product['onSale'] == true;
    // FIX 4: Removed unnecessary `dynamic` type annotation
    final rawFeatures = product['display_features'];

    // First parse raw features into a flat list
    final List<String> rawFeatList = () {
      if (rawFeatures == null) return <String>[];
      if (rawFeatures is String) {
        final s = rawFeatures.trim();
        return s.isEmpty ? <String>[] : <String>[s];
      }
      if (rawFeatures is List || rawFeatures is Iterable) {
        return (rawFeatures as Iterable)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return <String>[];
    }();

    // Split each entry by comma: "FRAME, 4M" → ["FRAME", "4M"]
    final List<String> featureBadges = rawFeatList
        .expand(
          (e) => e.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
        )
        .toList();

    // Parse raw colors
    final rawColors = product['display_feature_colors'];
    final List<String> rawColorList = () {
      if (rawColors == null) return <String>[];
      if (rawColors is List) {
        return rawColors
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (rawColors is String && rawColors.trim().isNotEmpty) {
        return <String>[rawColors.trim()];
      }
      return <String>[];
    }();

    // Expand colors to match split badges:
    // e.g. rawFeatList[0] = "FRAME, 4M" (2 parts), rawColorList[0] = "#006400"
    // → featureColors = ["#006400", "#006400"]
    final List<String> featureColors = () {
      final List<String> expanded = [];
      for (var i = 0; i < rawFeatList.length; i++) {
        final parts = rawFeatList[i]
            .split(',')
            .where((s) => s.trim().isNotEmpty)
            .toList();
        final color = i < rawColorList.length ? rawColorList[i] : '';
        for (var _ in parts) {
          expanded.add(color);
        }
      }
      return expanded;
    }();

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
              // FIX 5: withOpacity -> withValues
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: _isOutOfStock(product)
                            ? ColorFiltered(
                                colorFilter: const ColorFilter.mode(
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
                    if (_shouldShowSaleTopBanner(product))
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: _buildSaleTopBannerLabel(
                            _saleLabel(product),
                            fontSize: 11,
                          ),
                        ),
                      ),

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
                                // FIX 5: withOpacity -> withValues
                                color: Colors.black.withValues(alpha: 0.2),
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (product['show_freight_cost_icon'] == 1 ||
                      product['show_freight_cost_icon'] == '1' ||
                      product['show_free_shipping_icon'] == 1 ||
                      product['show_free_shipping_icon'] == '1') ...[
                    _buildShippingLabels(product),
                    const SizedBox(height: 5),
                  ],
                  SizedBox(
                    height: 13,
                    child: (product['sku'] ?? '').toString().trim().isNotEmpty
                        ? Text(
                            'SKU: ${product['sku']}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 1),
                  SizedBox(
                    height: 34,
                    child: Text(
                      product['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 32,
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
                  if (featureBadges.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 20,
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ...featureBadges.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  String display = entry.value;
                                  // Remove surrounding square brackets e.g. [CONTROL WITH YOUR PHONE]
                                  display = display
                                      .replaceAll(RegExp(r'^\[|\]$'), '')
                                      .trim();

                                  // --- Dynamic background color logic ---
                                  // Fallback: dark green #006400
                                  const Color fallbackBgColor = Color(
                                    0xFF006400,
                                  );
                                  Color bgColor = fallbackBgColor;

                                  if (idx < featureColors.length) {
                                    final hexStr = featureColors[idx]
                                        .replaceAll('#', '')
                                        .trim();
                                    if (hexStr.length == 6 ||
                                        hexStr.length == 8) {
                                      final fullHex = hexStr.length == 6
                                          ? 'FF$hexStr'
                                          : hexStr;
                                      final parsed = int.tryParse(
                                        fullHex,
                                        radix: 16,
                                      );
                                      if (parsed != null) {
                                        bgColor = Color(parsed);
                                      }
                                    }
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      display.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(width: 16),
                              ],
                            ),
                          ),
                          if (featureBadges.length > 1)
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: IgnorePointer(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 20,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.white,
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 14,
                                      color: Colors.white,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.chevron_right,
                                        size: 12,
                                        color: Colors.black38,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 40,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isOnSale && _shouldShowPrice(product))
                                Text(
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
                              _shouldShowPrice(product)
                                  ? Text(
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
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Respect show_add_to_cart flag (default: show)
                        _shouldShowAddToCart(product)
                            ? (_isOutOfStock(product)
                                  ? Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[400],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.shopping_cart,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap:
                                          (_isQuickAdding ||
                                              _isOutOfStock(product))
                                          ? null
                                          : () => _handleQuickAdd(context),
                                      child: Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: _isOutOfStock(product)
                                              ? Colors.grey[400]
                                              : const Color(0xFF151D51),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Center(
                                          child: _isQuickAdding
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                              : Icon(
                                                  _isOutOfStock(product)
                                                      ? Icons.block
                                                      : Icons.shopping_cart,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                        ),
                                      ),
                                    ))
                            : const SizedBox(width: 34, height: 34),
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
      await StorageService.saveCartDataWithProductHints(
        response,
        listingProduct: widget.product,
      );
      if (!context.mounted) return;
      NavigationService.instance.refreshCartCount();
      NavigationService.instance.refreshCartItems();
      CartFeedbackOverlay.showSuccess(context);
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

// ============================================================
// ProductListCard
// ============================================================

class ProductListCard extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductListCard({super.key, required this.product});

  @override
  State<ProductListCard> createState() => _ProductListCardState();
}

class _ProductListCardState extends State<ProductListCard> {
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  bool _isQuickAdding = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isOnSale = _hasStrikePrice(product) || product['onSale'] == true;
    final outOfStock = _isOutOfStock(product);
    final rawFeatures = product['display_features'];

    // First parse raw features into a flat list
    final List<String> rawFeatListL = () {
      if (rawFeatures == null) return <String>[];
      if (rawFeatures is String) {
        final s = rawFeatures.trim();
        return s.isEmpty ? <String>[] : <String>[s];
      }
      if (rawFeatures is List || rawFeatures is Iterable) {
        return (rawFeatures as Iterable)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return <String>[];
    }();

    // Split each entry by comma: "FRAME, 4M" → ["FRAME", "4M"]
    final List<String> featureBadges = rawFeatListL
        .expand(
          (e) => e.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
        )
        .toList();

    // Parse raw colors
    final rawColors = product['display_feature_colors'];
    final List<String> rawColorListL = () {
      if (rawColors == null) return <String>[];
      if (rawColors is List) {
        return rawColors
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (rawColors is String && rawColors.trim().isNotEmpty) {
        return <String>[rawColors.trim()];
      }
      return <String>[];
    }();

    // Expand colors to match split badges
    final List<String> featureColors = () {
      final List<String> expanded = [];
      for (var i = 0; i < rawFeatListL.length; i++) {
        final parts = rawFeatListL[i]
            .split(',')
            .where((s) => s.trim().isNotEmpty)
            .toList();
        final color = i < rawColorListL.length ? rawColorListL[i] : '';
        for (var _ in parts) {
          expanded.add(color);
        }
      }
      return expanded;
    }();

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
        constraints: const BoxConstraints(minHeight: 120),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              // FIX 5: withOpacity -> withValues
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: Container(
                        color: Colors.white,
                        child: SizedBox(
                          width: 120,
                          height: double.infinity,
                          child: outOfStock
                              ? ColorFiltered(
                                  colorFilter: const ColorFilter.mode(
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
                    ),
                    if (_shouldShowSaleTopBanner(product))
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: _buildSaleTopBannerLabel(
                            _saleLabel(product),
                            fontSize: 9,
                          ),
                        ),
                      ),
                    // FIX 1: Added missing `if (outOfStock)` check and correct
                    // `Positioned(` opening that was absent in the original
                    if (outOfStock)
                      Positioned(
                        top: 8,
                        right: 8,
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
                                // FIX 5: withOpacity -> withValues
                                color: Colors.black.withValues(alpha: 0.2),
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
                    // FIX 2: Removed duplicate _buildShippingLabels — kept only one
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: _buildShippingLabels(product),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((product['sku'] ?? '').toString().trim().isNotEmpty)
                        Text(
                          'SKU: ${product['sku']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      const SizedBox(height: 5),
                      Text(
                        product['name'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        product['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                      if (featureBadges.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        SizedBox(
                          height: 20,
                          child: Stack(
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ...featureBadges.asMap().entries.map((
                                      entry,
                                    ) {
                                      final idx = entry.key;
                                      String display = entry.value;
                                      // Remove surrounding square brackets e.g. [CONTROL WITH YOUR PHONE]
                                      display = display
                                          .replaceAll(RegExp(r'^\[|\]$'), '')
                                          .trim();

                                      // --- Dynamic background color logic ---
                                      // Fallback: dark green #006400
                                      const Color fallbackBgColor = Color(
                                        0xFF006400,
                                      );
                                      Color bgColor = fallbackBgColor;

                                      if (idx < featureColors.length) {
                                        final hexStr = featureColors[idx]
                                            .replaceAll('#', '')
                                            .trim();
                                        if (hexStr.length == 6 ||
                                            hexStr.length == 8) {
                                          final fullHex = hexStr.length == 6
                                              ? 'FF$hexStr'
                                              : hexStr;
                                          final parsed = int.tryParse(
                                            fullHex,
                                            radix: 16,
                                          );
                                          if (parsed != null) {
                                            bgColor = Color(parsed);
                                          }
                                        }
                                      }

                                      return Container(
                                        margin: const EdgeInsets.only(right: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          display.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      );
                                    }),
                                    const SizedBox(width: 16),
                                  ],
                                ),
                              ),
                              if (featureBadges.length > 1)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: IgnorePointer(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 20,
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                Colors.white,
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 14,
                                          color: Colors.white,
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.chevron_right,
                                            size: 12,
                                            color: Colors.black38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isOnSale && _shouldShowPrice(product))
                                  Text(
                                    _formatPrice(
                                      product['previous_price'] ??
                                          product['originalPrice'],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                if (isOnSale && _shouldShowPrice(product))
                                  const SizedBox(height: 2),
                                _shouldShowPrice(product)
                                    ? Text(
                                        _formatPrice(
                                          product['price'] ??
                                              product['currentPrice'] ??
                                              '',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _shouldShowAddToCart(product)
                              ? (outOfStock
                                    ? Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[400],
                                          borderRadius: BorderRadius.circular(
                                            7,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.shopping_cart,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      )
                                    : GestureDetector(
                                        onTap: (_isQuickAdding || outOfStock)
                                            ? null
                                            : () => _handleQuickAdd(context),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF151D51),
                                            borderRadius: BorderRadius.circular(
                                              7,
                                            ),
                                          ),
                                          child: Center(
                                            child: _isQuickAdding
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.shopping_cart,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                          ),
                                        ),
                                      ))
                              : const SizedBox.shrink(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
      await StorageService.saveCartDataWithProductHints(
        response,
        listingProduct: widget.product,
      );
      if (!context.mounted) return;
      NavigationService.instance.refreshCartCount();
      NavigationService.instance.refreshCartItems();
      CartFeedbackOverlay.showSuccess(context);
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

// ============================================================
// Top-level helper functions
// ============================================================

String _saleLabel(Map<String, dynamic> product) {
  final label = product['onsale_line'];
  if (label is String && label.trim().isNotEmpty) {
    return label.trim();
  }
  return 'Sale';
}

bool _shouldShowSaleTopBanner(Map<String, dynamic> product) {
  final label = product['onsale_line'];
  if (label is String && label.trim().isNotEmpty) return true;
  return _hasStrikePrice(product) || product['onSale'] == true;
}

/// Scrolling sale text for red sale banners.
Widget _buildSaleTopBannerLabel(String text, {double fontSize = 11}) {
  final style = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: fontSize,
    height: 1.2,
  );
  final lineHeight = fontSize * 1.2;

  return SizedBox(
    height: lineHeight,
    width: double.infinity,
    child: Marquee(
      text: text,
      style: style,
      scrollAxis: Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.center,
      blankSpace: 28,
      velocity: 28,
      pauseAfterRound: const Duration(milliseconds: 900),
      startPadding: 6,
      accelerationDuration: const Duration(milliseconds: 400),
      decelerationDuration: const Duration(milliseconds: 400),
      showFadingOnlyWhenScrolling: true,
      fadingEdgeStartFraction: 0.08,
      fadingEdgeEndFraction: 0.08,
    ),
  );
}

bool _hasStrikePrice(Map<String, dynamic> product) {
  final prev = _readNum(product['previous_price'] ?? product['originalPrice']);
  final price = _readNum(product['price'] ?? product['currentPrice']);
  return prev > 0 && prev > price;
}

bool _shouldShowPrice(Map<String, dynamic> product) {
  final v = product['show_price'];
  if (v == null) return true;
  if (v is int) return v == 1;
  if (v is bool) return v;
  final s = v.toString().toLowerCase();
  return s == '1' || s == 'true';
}

bool _shouldShowAddToCart(Map<String, dynamic> product) {
  final v = product['show_add_to_cart'];
  if (v == null) return true;
  if (v is int) return v == 1;
  if (v is bool) return v;
  final s = v.toString().toLowerCase();
  return s == '1' || s == 'true';
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

Widget _buildShippingLabels(Map<String, dynamic> product) {
  final showFreight =
      product['show_freight_cost_icon'] == 1 ||
      product['show_freight_cost_icon'] == '1';
  final showFreeShipping =
      product['show_free_shipping_icon'] == 1 ||
      product['show_free_shipping_icon'] == '1';

  if (!showFreight && !showFreeShipping) return const SizedBox.shrink();

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (showFreight)
        _buildShippingLabel(
          text: 'Freight Delivery',
          icon: Icons.local_shipping,
          color: const Color(0xFF151D51),
        ),
      if (showFreeShipping)
        Padding(
          padding: EdgeInsets.only(top: showFreight ? 2 : 0),
          child: _buildShippingLabel(
            text: 'Free Shipping',
            icon: Icons.check_circle_outline,
            color: const Color(0xFF2E7D32),
          ),
        ),
    ],
  );
}

Widget _buildShippingLabel({
  required String text,
  required IconData icon,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: BoxDecoration(
      // FIX 5: withOpacity -> withValues
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(3),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
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
  return '\$${n.toStringAsFixed(2)}';
}

Widget _buildProductImage(Map<String, dynamic> product) {
  final thumb = (product['thumbnail'] ?? product['image'])?.toString();
  if (thumb == null || thumb.isEmpty) {
    return Image.asset(
      'assets/images/no_image.png',
      width: double.infinity,
      height: 100,
      fit: BoxFit.contain,
    );
  }

  final isNetwork = thumb.startsWith('http');
  if (isNetwork) {
    return CachedNetworkImage(
      imageUrl: thumb,
      width: double.infinity,
      height: 100,
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        width: double.infinity,
        height: 100,
        color: Colors.white,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Image.asset(
        'assets/images/no_image.png',
        width: double.infinity,
        height: 124,
        fit: BoxFit.contain,
      ),
    );
  }

  return Image.asset(
    thumb,
    width: double.infinity,
    height: 124,
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) =>
        SizedBox(width: double.infinity, height: 124, child: _imageFallback()),
  );
}

Widget _imageFallback() {
  return Center(
    child: Image.asset('assets/images/no_image.png', fit: BoxFit.contain),
  );
}
