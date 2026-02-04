import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/cart_service.dart';
import '../../../data/services/cart_payload_builder.dart';
import '../../../services/navigation_service.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../data/models/product_details_model.dart';
import '../../../data/models/product_detail_response.dart';
import '../../../data/models/settings_model.dart';
import '../../../services/storage_service.dart';
import '../../../core/exceptions/api_exception.dart';

class DetailView extends StatefulWidget {
  final int productId;

  const DetailView({super.key, required this.productId});

  @override
  State<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;
  Timer? _imageTimer;
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = true;
  bool _scrollListenerAttached = false;

  static const String _productImageBaseUrl =
      'https://www.gurgaonit.com/apc_production_dev/assets/images/products/';

  // API state
  ProductDetailsModel? _product;
  List<KitIncludeItem> _kitIncludesOne = [];
  List<KitIncludeItem> _kitIncludesTwo = [];
  List<QtyUpgradeProduct> _qtyUpgradeProducts = [];
  List<UpgradeProduct> _upgradeProducts = [];
  List<AddonProduct> _addonProducts = [];
  List<GalleryItem> _gallery = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAddingToCart = false;

  // Settings state
  SettingsModel? _settings;

  // Footer state
  int kitQuantity = 1;

  final Map<int, int> _selectedQtyForCustomise = {};
  int _selectedUpgradeIndex = -1;
  final Map<int, int> _selectedSubProductIndex =
      {}; // upgradeProductId -> subProductIndex (-1 means main product selected)
  List<bool> _addOnSelections = [];
  List<int> _addOnQuantities = [];
  bool _hasUserManuallySelectedUpgrade =
      false; // Track if user manually selected upgrade

  bool get _isKitProduct => (_product?.isKIT?.toLowerCase() ?? '') == 'yes';

  /// Determines if the Upgrades section should be shown at all.
  ///
  /// We always show the section for kit products, even if there are
  /// no upgrade items, so that we can explicitly tell the user that
  /// no upgrades are available for this kit.
  bool get _shouldShowUpgradesSection => _isKitProduct;

  List<String> get productImages {
    final List<String> images = [];
    if (_gallery.isNotEmpty) {
      images.addAll(
        _gallery
            .map((item) => _resolveImageUrl(item.photo))
            .where((url) => url.isNotEmpty),
      );
    }

    if (images.isEmpty && _product != null) {
      final thumbnailUrl = _resolveImageUrl(_product!.thumbnail);
      if (thumbnailUrl.isNotEmpty) {
        images.add(thumbnailUrl);
      } else {
        final fallback = _resolveImageUrl(_product!.photo);
        if (fallback.isNotEmpty) {
          images.add(fallback);
        }
      }
    }

    return images;
  }

  String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return '';
    }
    if (path.startsWith('http')) {
      return path;
    }
    return '$_productImageBaseUrl$path';
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF151D51),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [Colors.yellow[600]!, Colors.grey[300]!],
              stops: const [0.3, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  List<int> _quantityOptionsFor(QtyUpgradeProduct item) {
    final baseQuantity = math.max(item.productBaseQuantity, 1);
    final maxQuantity = item.maxQuantity >= baseQuantity
        ? item.maxQuantity
        : baseQuantity;
    final totalOptions = math.max(1, maxQuantity - baseQuantity + 1);
    return List<int>.generate(totalOptions, (index) => baseQuantity + index);
  }

  double _calculateExtraCost(QtyUpgradeProduct item, int quantity) {
    final baseQuantity = item.productBaseQuantity;
    final additionalUnits = math.max(0, quantity - baseQuantity);
    return additionalUnits * item.extraUnitPrice;
  }

  String _formatCurrency(num value) => value.toStringAsFixed(2);

  /// Calculate total extra cost from all customise kit items
  CartPayloadBuilder? _createPayloadBuilder() {
    if (_product == null) return null;
    return CartPayloadBuilder(
      product: _product!,
      qtyUpgradeProducts: _qtyUpgradeProducts,
      upgradeProducts: _upgradeProducts,
      addonProducts: _addonProducts,
      kitQuantity: kitQuantity,
      selectedQtyForCustomise: _selectedQtyForCustomise,
      selectedUpgradeIndex: _selectedUpgradeIndex,
      selectedSubProductIndex: _selectedSubProductIndex,
      addOnSelections: _addOnSelections,
      addOnQuantities: _addOnQuantities,
    );
  }

  double _calculateFinalPrice() =>
      _createPayloadBuilder()?.calculateFinalPrice() ?? 0.0;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    // Show indicator if near top (within 200px) and there's more content to scroll
    final shouldShow = currentScroll < 200 && maxScroll > 100;

    if (shouldShow != _showScrollIndicator) {
      setState(() {
        _showScrollIndicator = shouldShow;
      });
    }
  }

  Future<void> _fetchProductDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detailResponse = await _productService.getProductDetails(
        widget.productId,
      );
      setState(() {
        _product = detailResponse.product;
        _kitIncludesOne = detailResponse.kitIncludesOne;
        _kitIncludesTwo = detailResponse.kitIncludesTwo;
        _qtyUpgradeProducts = detailResponse.qtyUpgradeProducts;
        _upgradeProducts = detailResponse.upgradeProducts;
        _addonProducts = detailResponse.addonProducts;
        _gallery = detailResponse.gallery;

        _selectedQtyForCustomise
          ..clear()
          ..addEntries(
            detailResponse.qtyUpgradeProducts.map(
              (item) => MapEntry(item.id, item.productBaseQuantity),
            ),
          );

        // Pre-select first upgrade product by default (if upgrades exist)
        _selectedUpgradeIndex = detailResponse.upgradeProducts.isNotEmpty
            ? 0
            : -1;
        if (_selectedUpgradeIndex == 0 &&
            detailResponse.upgradeProducts.isNotEmpty) {
          _selectedSubProductIndex[detailResponse.upgradeProducts[0].id] = -1;
        }
        _addOnSelections = List<bool>.filled(
          detailResponse.addonProducts.length,
          false,
        );
        _addOnQuantities = List<int>.filled(
          detailResponse.addonProducts.length,
          1,
        );

        _isLoading = false;
      });

      // Restart auto-slide if gallery images are available
      if (_gallery.isNotEmpty) {
        _imageTimer?.cancel();
        _currentImageIndex = 0;
        if (mounted) {
          _startImageAutoSlide();
        }
      }

      // Attach scroll listener after data is loaded
      if (mounted && !_scrollListenerAttached) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _scrollController.hasClients &&
              !_scrollListenerAttached) {
            _scrollController.addListener(_onScroll);
            _scrollListenerAttached = true;
            _onScroll();
          }
        });
      }
    } on ApiException catch (e) {
      setState(() {
        // Show user-friendly error message
        if (e.statusCode == 500) {
          _errorMessage = 'Server error. Please try again later.';
        } else if (e.statusCode == 404) {
          _errorMessage = 'Product not found.';
        } else if (e.statusCode == 401) {
          _errorMessage = 'Unauthorized. Please check your credentials.';
        } else {
          _errorMessage = e.message.isNotEmpty
              ? e.message
              : 'Failed to load product details. Please try again.';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _imageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _startImageAutoSlide() {
    _imageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (productImages.isEmpty || productImages.length <= 1) return;
      if (_currentImageIndex < productImages.length - 1) {
        _currentImageIndex++;
      } else {
        _currentImageIndex = 0;
      }
      _imageController.animateToPage(
        _currentImageIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Product Detail',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Action Bar (fixed)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  // Column 1: Kit Quantity Section
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Kit Quantity:',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Minus button
                            GestureDetector(
                              onTap: () {
                                if (kitQuantity > 1) {
                                  setState(() {
                                    kitQuantity--;
                                  });
                                }
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[400]!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Quantity
                            Container(
                              width: 28,
                              height: 24,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[400]!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  kitQuantity.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Plus button
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  kitQuantity++;
                                });
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[400]!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Column 2: Price Section
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: const Text(
                            'Your Price:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$${_formatCurrency(_calculateFinalPrice())}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Add to Cart Button
                            GestureDetector(
                              onTap:
                                  (_isAddingToCart ||
                                      (_product?.outOfStock ?? 0) == 1)
                                  ? null
                                  : _handleAddToCart,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: (_product?.outOfStock ?? 0) == 1
                                      ? Colors.grey[400]
                                      : Colors.orange,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: (_product?.outOfStock ?? 0) == 1
                                    ? const Text(
                                        'OUT OF STOCK',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : _isAddingToCart
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.shopping_cart,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Cart',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Contact and Dispatch Info (fixed)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              color: Colors.white,
              child: Row(
                children: [
                  // Contact Section
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.phone, color: Colors.orange, size: 16),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Have Questions?',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Text(
                              'Talk to the Experts',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _settings?.pageSettings.phone ?? '1800 694 283',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Dispatch Info
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.access_time,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Dispatched in:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Within One',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            'Business Day',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading product',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _fetchProductDetails,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _product == null
          ? const Center(child: Text('Product not found'))
          : Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Images Section
                      _buildProductImagesSection(),

                      // Product Details
                      _buildProductDetails(),

                      if (_isKitProduct) ...[
                        _buildKitIncludes(),
                        _buildCustomiseYourKit(),
                        if (_shouldShowUpgradesSection) _buildUpgrades(),
                        if (_addonProducts.isNotEmpty) _buildAddOnItems(),
                      ],

                      // Product Information section
                      _buildProductInformation(),

                      // Footer content moved into scrollable area
                      _buildScrollableFooter(),
                    ],
                  ),
                ),
                // Scroll Indicator
                AnimatedOpacity(
                  opacity: _showScrollIndicator ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: _showScrollIndicator
                      ? Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                if (_scrollController.hasClients) {
                                  _scrollController.animateTo(
                                    _scrollController.position.maxScrollExtent *
                                        0.3,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOut,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Scroll for more',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
    );
  }

  Widget _buildProductImagesSection() {
    final images = productImages;
    if (images.isEmpty) {
      return Container(
        height: 250,
        color: Colors.white,
        child: const Center(
          child: Icon(Icons.image, size: 50, color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 250,
      color: Colors.white,
      child: Column(
        children: [
          // Main Image with PageView
          Expanded(
            child: PageView.builder(
              controller: _imageController,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemCount: images.length,
              itemBuilder: (context, index) {
                final imageUrl = images[index];
                final isNetwork = imageUrl.startsWith('http');

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.12),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey[100],
                      child: isNetwork
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Image.asset(
                              imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Image Indicators
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.blue
                        : Colors.grey[300],
                  ),
                ),
              ),
            ),
          ),

          // Thumbnail Images
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                final imageUrl = images[index];
                final isNetwork = imageUrl.startsWith('http');

                return GestureDetector(
                  onTap: () {
                    _imageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _currentImageIndex == index
                            ? Colors.blue
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.grey[100],
                        child: isNetwork
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image,
                                    size: 24,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : Image.asset(
                                imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image,
                                      size: 24,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails() {
    if (_product == null) return const SizedBox.shrink();

    final isInStock = _product!.outOfStock == 0;

    final hasAddonOrUpgrade =
        _isKitProduct &&
        (_upgradeProducts.isNotEmpty || _addonProducts.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Strong indication for addon/upgrade items in KIT
          if (hasAddonOrUpgrade) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle,
                    color: Colors.orange.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ADD-ON & UPGRADE ITEMS AVAILABLE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This KIT includes customisation options. Scroll down to add upgrades and add-ons.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          Text(
            _product!.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Product SKU: ${_product!.sku}',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isInStock ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isInStock ? 'In Stock' : 'Out of Stock',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Shipping Display Section (conditional)
          if ((_product?.showFreeShippingIcon ?? 0) == 1 ||
              (_product?.showFreightCostIcon ?? 0) == 1)
            Row(
              children: [
                // FREE Shipping Badge
                if ((_product?.showFreeShippingIcon ?? 0) == 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.yellow[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_shipping,
                          color: Colors.green[800],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'FREE',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Shipping',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Spacing between badges
                if ((_product?.showFreeShippingIcon ?? 0) == 1 &&
                    (_product?.showFreightCostIcon ?? 0) == 1)
                  const SizedBox(width: 12),
                // Freight Delivery Icon
                if ((_product?.showFreightCostIcon ?? 0) == 1)
                  Row(
                    children: [
                      Icon(Icons.local_shipping, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Freight Delivery',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.info_outline, color: Colors.red, size: 14),
                    ],
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Kit Price: ',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
              Text(
                '\$${_product!.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (_product!.previousPrice > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '\$${_product!.previousPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/images/sale.png',
                  width: 50,
                  height: 44,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Payment options - Afterpay
          Row(
            children: [
              Text(
                'Or in 4 payment of ',
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
              Text(
                '\$${(_product!.price.toDouble() / 4).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                ' with ',
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCF4E6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'afterpay',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'info',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Payment options - ZIP
          Row(
            children: [
              const Text(
                'or from ',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
              const Text(
                '\$10/week',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                ' with ',
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
              Row(
                children: [
                  const Text(
                    'Z',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Center(
                      child: Text(
                        'I',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'P',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Icon(Icons.info_outline, color: Colors.grey[700], size: 14),
            ],
          ),
          const SizedBox(height: 8),
          if (_product!.shortDescription != null &&
              _product!.shortDescription!.isNotEmpty)
            Text(
              _product!.shortDescription!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScrollableFooter() {
    // Only show the "Your Customised Kit Includes" section if there are actual user selections
    if (!_isKitProduct) {
      return const SizedBox.shrink();
    }

    final customiseData = getCustomiseKitData();
    final upgradeData = getSelectedUpgradeData();
    final addOnData = getSelectedAddOnData();

    // Check if there's anything to show - only items that user actually selected/changed
    // For customise: only show if quantity was changed from base
    final hasCustomise = customiseData.any((item) {
      final itemData = _qtyUpgradeProducts.firstWhere(
        (p) => p.id == item['id'],
        orElse: () => _qtyUpgradeProducts.first,
      );
      final selectedQty = item['qty'] as int;
      final baseQty = itemData.productBaseQuantity;
      return selectedQty > baseQty;
    });

    // For upgrade: only show if user manually selected an upgrade (not default auto-selection)
    final hasUpgrade =
        _hasUserManuallySelectedUpgrade &&
        upgradeData != null &&
        (upgradeData['isUpgrade'] as bool? ?? false) &&
        (upgradeData['price'] as num) > 0;

    // For add-on: only show if user actually selected add-ons
    final hasAddOn = addOnData.isNotEmpty;

    // Only show section if user has made selections
    if (!hasCustomise && !hasUpgrade && !hasAddOn) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: Column(
        children: [
          // Kit Summary Section - Only shows when user makes selections
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Customised Kit Includes:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF151D51),
                  ),
                ),
                const SizedBox(height: 12),

                // Customise your Kit Items (only if user changed quantities)
                if (hasCustomise) ...[
                  ...customiseData
                      .where((item) {
                        final itemData = _qtyUpgradeProducts.firstWhere(
                          (p) => p.id == item['id'],
                          orElse: () => _qtyUpgradeProducts.first,
                        );
                        final selectedQty = item['qty'] as int;
                        final baseQty = itemData.productBaseQuantity;
                        // Only show if quantity was changed from base
                        return selectedQty > baseQty;
                      })
                      .map((item) {
                        final itemData = _qtyUpgradeProducts.firstWhere(
                          (p) => p.id == item['id'],
                          orElse: () => _qtyUpgradeProducts.first,
                        );
                        final selectedQty = item['qty'] as int;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Customise: ${itemData.name} - Qty: $selectedQty',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                ],

                // Upgrade Items (only if user selected an upgrade)
                if (hasUpgrade) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Upgrade: ${_getUpgradeName(upgradeData)} - Qty: ${upgradeData['qty']}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Add-On Items (only if user added add-ons)
                if (hasAddOn) ...[
                  ...addOnData.map((item) {
                    final itemData = _addonProducts.firstWhere(
                      (p) => p.id == item['id'],
                      orElse: () => _addonProducts.first,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Add-On: ${itemData.name} - Qty: ${item['qty']}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          // Dynamic Summary Section
          _buildDynamicSummary(),

          // Bottom padding for scroll
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDynamicSummary() {
    final customiseData = getCustomiseKitData();
    final upgradeData = getSelectedUpgradeData();
    final addOnData = getSelectedAddOnData();

    // Check if there's anything to show - only items that user actually selected/changed
    // For customise: only show if quantity was changed from base
    final hasCustomise = customiseData.any((item) {
      final itemData = _qtyUpgradeProducts.firstWhere(
        (p) => p.id == item['id'],
        orElse: () => _qtyUpgradeProducts.first,
      );
      final selectedQty = item['qty'] as int;
      final baseQty = itemData.productBaseQuantity;
      return selectedQty > baseQty;
    });

    // For upgrade: only show if user manually selected an upgrade (not default auto-selection)
    final hasUpgrade =
        _hasUserManuallySelectedUpgrade &&
        upgradeData != null &&
        (upgradeData['isUpgrade'] as bool? ?? false) &&
        (upgradeData['price'] as num) > 0;

    // For add-on: only show if user actually selected add-ons
    final hasAddOn = addOnData.isNotEmpty;

    if (!hasCustomise && !hasUpgrade && !hasAddOn) {
      return const SizedBox.shrink();
    }

    // Calculate total items for max height calculation
    final totalItems =
        customiseData.length + (hasUpgrade ? 1 : 0) + addOnData.length;
    // Set max height based on number of items (max 4-5 items visible, then scroll)
    // Each item is approximately 20-24px (text height + padding), so 5 items = ~120px
    final maxHeight = totalItems > 4 ? 120.0 : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: ConstrainedBox(
        constraints: maxHeight != null
            ? BoxConstraints(maxHeight: maxHeight)
            : const BoxConstraints(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Customise your Kit Summary
              if (hasCustomise) ...[
                ...customiseData
                    .where((item) {
                      final itemData = _qtyUpgradeProducts.firstWhere(
                        (p) => p.id == item['id'],
                        orElse: () => _qtyUpgradeProducts.first,
                      );
                      final selectedQty = item['qty'] as int;
                      final baseQty = itemData.productBaseQuantity;
                      // Only show if quantity was changed from base
                      return selectedQty > baseQty;
                    })
                    .map((item) {
                      final itemData = _qtyUpgradeProducts.firstWhere(
                        (p) => p.id == item['id'],
                        orElse: () => _qtyUpgradeProducts.first,
                      );
                      final price = (item['price'] as num).toDouble();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Customise: ${itemData.name} - Qty: ${item['qty']}, Price: \$${_formatCurrency(price)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
              ],

              // Upgrades Summary
              if (hasUpgrade) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Upgrade: ${_getUpgradeName(upgradeData)} - Qty: ${upgradeData['qty']}, Price: \$${_formatCurrency((upgradeData['price'] as num).toDouble())}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              // Add-On Items Summary
              if (hasAddOn) ...[
                ...addOnData.map((item) {
                  final itemData = _addonProducts.firstWhere(
                    (p) => p.id == item['id'],
                    orElse: () => _addonProducts.first,
                  );
                  final totalPrice =
                      (item['qty'] as int) * (item['price'] as num).toDouble();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Add-On: ${itemData.name} - Qty: ${item['qty']}, Price: \$${_formatCurrency(totalPrice)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getUpgradeName(Map<String, dynamic> upgradeData) {
    if (_selectedUpgradeIndex < 0 ||
        _selectedUpgradeIndex >= _upgradeProducts.length) {
      return '';
    }

    final upgradeProduct = _upgradeProducts[_selectedUpgradeIndex];
    final selectedSubIndex = _selectedSubProductIndex[upgradeProduct.id] ?? -1;

    // If sub-product is selected
    if (selectedSubIndex >= 0 &&
        selectedSubIndex < upgradeProduct.subProducts.length) {
      return upgradeProduct.subProducts[selectedSubIndex].name;
    }

    // Main product is selected
    return upgradeProduct.name;
  }

  Widget _buildKitIncludes() {
    if (!_isKitProduct) {
      return const SizedBox.shrink();
    }

    if (_kitIncludesOne.isEmpty && _kitIncludesTwo.isEmpty) {
      return const SizedBox.shrink();
    }

    Widget buildColumn(List<KitIncludeItem> items, int startIndex) {
      if (items.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final displayNumber = startIndex + entry.key;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      displayNumber.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF151D51),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Qty: ${item.productBaseQuantity}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Kit Includes'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: buildColumn(_kitIncludesOne, 1)),
              const SizedBox(width: 16),
              Expanded(
                child: buildColumn(_kitIncludesTwo, _kitIncludesOne.length + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomiseYourKit() {
    if (!_isKitProduct || _qtyUpgradeProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Customise your Kit'),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _qtyUpgradeProducts.length,
            itemBuilder: (context, index) {
              final item = _qtyUpgradeProducts[index];
              final selectedQty =
                  _selectedQtyForCustomise[item.id] ?? item.productBaseQuantity;
              final quantityOptions = _quantityOptionsFor(item);
              final extraCost = _calculateExtraCost(item, selectedQty);
              final imageUrl = _resolveImageUrl(item.photo);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[500],
                                  size: 20,
                                ),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.image,
                                color: Colors.grey[500],
                                size: 20,
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF151D51),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.sku,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quantity:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF151D51),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: quantityOptions.contains(selectedQty)
                                        ? selectedQty
                                        : quantityOptions.first,
                                    isDense: true,
                                    iconSize: 14,
                                    items: quantityOptions.map((qty) {
                                      final optionExtra = _calculateExtraCost(
                                        item,
                                        qty,
                                      );
                                      final formattedExtra = _formatCurrency(
                                        optionExtra,
                                      );
                                      final displayText = optionExtra == 0.0
                                          ? '$qty'
                                          : '$qty (+\$$formattedExtra)';
                                      return DropdownMenuItem<int>(
                                        value: qty,
                                        child: Text(
                                          displayText,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _selectedQtyForCustomise[item.id] =
                                            value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '+\$${_formatCurrency(extraCost)} (extra qty)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: extraCost > 0
                                        ? Colors.green[700]
                                        : Colors.black38,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.upgradeShortDescription,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey[700],
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUpgrades() {
    // Only relevant for kit products
    if (!_shouldShowUpgradesSection) {
      return const SizedBox.shrink();
    }

    final hasUpgradeData =
        _qtyUpgradeProducts.any((item) => item.isUpgradeQty) &&
        _upgradeProducts.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Upgrades are available for following items'),
          const SizedBox(height: 12),
          if (!hasUpgradeData)
            Text(
              'No upgrades are available for this kit.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _upgradeProducts.length,
              itemBuilder: (context, index) {
                final item = _upgradeProducts[index];
                final selectedSubIndex =
                    _selectedSubProductIndex[item.id] ?? -1;

                return Column(
                  children: [
                    _buildUpgradeProductCard(item, index, selectedSubIndex),
                    if (item.subProducts.isNotEmpty)
                      ...item.subProducts.asMap().entries.map((entry) {
                        final subIndex = entry.key;
                        final subProduct = entry.value;
                        return _buildSubProductCard(
                          item,
                          index,
                          subProduct,
                          subIndex,
                          selectedSubIndex,
                        );
                      }),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUpgradeProductCard(
    UpgradeProduct item,
    int index,
    int selectedSubIndex,
  ) {
    final imageUrl = _resolveImageUrl(item.photo);
    final isSelected = _selectedUpgradeIndex == index && selectedSubIndex == -1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Radio<String>(
            value: 'main_$index',
            groupValue: _selectedUpgradeIndex == index && selectedSubIndex == -1
                ? 'main_$index'
                : (_selectedUpgradeIndex == index && selectedSubIndex >= 0
                      ? 'sub_${index}_$selectedSubIndex'
                      : null),
            activeColor: Colors.blue,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: item.outOfStock == 1
                ? null
                : (value) {
                    setState(() {
                      _selectedUpgradeIndex = index;
                      _selectedSubProductIndex[item.id] = -1;
                      _hasUserManuallySelectedUpgrade =
                          true; // Mark as manually selected
                      // Price will update automatically via _calculateFinalPrice()
                    });
                  },
          ),
          const SizedBox(width: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 52,
                      height: 52,
                      color: Colors.grey[200],
                      child: const Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 52,
                      height: 52,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image,
                        color: Colors.grey[500],
                        size: 18,
                      ),
                    ),
                  )
                : Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.image, color: Colors.grey[500], size: 18),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: item.outOfStock == 1
                              ? Colors.grey
                              : const Color(0xFF151D51),
                          decoration: item.outOfStock == 1
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (item.outOfStock == 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'OUT OF STOCK',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.sku,
                  style: TextStyle(
                    fontSize: 12,
                    color: item.outOfStock == 1
                        ? Colors.grey
                        : Colors.blue[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Base Price: \$${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: item.outOfStock == 1 ? Colors.grey : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Qty: ${item.productBaseQuantity}',
                      style: TextStyle(
                        fontSize: 12,
                        color: item.outOfStock == 1
                            ? Colors.grey
                            : const Color(0xFF151D51),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.upgradeShortDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: item.outOfStock == 1
                        ? Colors.grey
                        : Colors.grey[700],
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubProductCard(
    UpgradeProduct parentItem,
    int parentIndex,
    SubProduct subProduct,
    int subIndex,
    int selectedSubIndex,
  ) {
    final imageUrl = _resolveImageUrl(subProduct.photo);
    final isSelected =
        _selectedUpgradeIndex == parentIndex && selectedSubIndex == subIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 10, left: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Radio<String>(
            value: 'sub_${parentIndex}_$subIndex',
            groupValue:
                _selectedUpgradeIndex == parentIndex && selectedSubIndex >= 0
                ? 'sub_${parentIndex}_$selectedSubIndex'
                : (_selectedUpgradeIndex == parentIndex &&
                          selectedSubIndex == -1
                      ? 'main_$parentIndex'
                      : null),
            activeColor: Colors.blue,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: subProduct.outOfStock == 1
                ? null
                : (value) {
                    setState(() {
                      _selectedUpgradeIndex = parentIndex;
                      _selectedSubProductIndex[parentItem.id] = subIndex;
                      _hasUserManuallySelectedUpgrade =
                          true; // Mark as manually selected
                      // Price will update automatically via _calculateFinalPrice()
                    });
                  },
          ),
          const SizedBox(width: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[200],
                      child: const Center(
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image,
                        color: Colors.grey[500],
                        size: 16,
                      ),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.image, color: Colors.grey[500], size: 16),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subProduct.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF151D51),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subProduct.sku,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Base Price: \$${subProduct.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Qty: ${subProduct.productBaseQuantity}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF151D51),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subProduct.upgradeShortDescription,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddOnItems() {
    if (_addonProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_addOnSelections.length != _addonProducts.length ||
        _addOnQuantities.length != _addonProducts.length) {
      _addOnSelections = List<bool>.filled(_addonProducts.length, false);
      _addOnQuantities = List<int>.filled(_addonProducts.length, 1);
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Add-On Items (Discounted when purchased along with this Kit)',
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _addonProducts.length,
            itemBuilder: (context, index) {
              final item = _addonProducts[index];
              final isSelected =
                  index < _addOnSelections.length && _addOnSelections[index];
              final quantity = index < _addOnQuantities.length
                  ? _addOnQuantities[index]
                  : 1;
              final imageUrl = _resolveImageUrl(item.photo);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.scale(
                        scale: 0.9,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: item.outOfStock == 1
                              ? null
                              : (value) {
                                  setState(() {
                                    _addOnSelections[index] = value ?? false;
                                    // Price will update automatically via _calculateFinalPrice()
                                  });
                                },
                          activeColor: Colors.blue,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 55,
                                height: 55,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 55,
                                  height: 55,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 55,
                                  height: 55,
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.image,
                                    color: Colors.grey[500],
                                    size: 18,
                                  ),
                                ),
                              )
                            : Container(
                                width: 55,
                                height: 55,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[500],
                                  size: 18,
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: item.outOfStock == 1
                                          ? Colors.grey
                                          : const Color(0xFF151D51),
                                      height: 1.35,
                                      decoration: item.outOfStock == 1
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (item.outOfStock == 1) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      'OUT OF STOCK',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.sku,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.upgradeShortDescription,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 85,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: quantity,
                                  isDense: true,
                                  items: List.generate(10, (i) {
                                    final qty = i + 1;
                                    return DropdownMenuItem<int>(
                                      value: qty,
                                      child: Text(
                                        '$qty',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }),
                                  onChanged: (val) {
                                    setState(() {
                                      _addOnQuantities[index] = val ?? 1;
                                      // Price will update automatically via _calculateFinalPrice()
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Unit Price',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF151D51),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '\$${item.unitPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            if (item.originalPrice != null) ...[
                              const SizedBox(height: 1),
                              Text(
                                '\$${item.originalPrice!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 9,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper methods to get tracked data for API submission

  List<Map<String, dynamic>> getCustomiseKitData() =>
      _createPayloadBuilder()?.getCustomiseKitData() ?? [];

  Map<String, dynamic>? getSelectedUpgradeData() =>
      _createPayloadBuilder()?.getSelectedUpgradeData();

  List<Map<String, dynamic>> getSelectedAddOnData() =>
      _createPayloadBuilder()?.getSelectedAddOnData() ?? [];

  Future<Map<String, dynamic>> getAllKitCustomizationData() async {
    final builder = _createPayloadBuilder();
    if (builder == null) {
      return {};
    }
    return builder.buildPayload();
  }

  Future<void> _handleAddToCart() async {
    if (_isAddingToCart) return;
    setState(() {
      _isAddingToCart = true;
    });

    try {
      final payload = await getAllKitCustomizationData();
      final prettyPayload = const JsonEncoder.withIndent('  ').convert(payload);
      final requestUrl =
          '${ApiEndpoints.baseUrl}${ApiEndpoints.addCartProducts}';
      debugPrint('Add-to-cart URL: $requestUrl');
      debugPrint('Add-to-cart payload:\n$prettyPayload');

      final response = await _cartService.addProducts(payload);
      final prettyResponse = const JsonEncoder.withIndent(
        '  ',
      ).convert(response);
      debugPrint('Add-to-cart response:\n$prettyResponse');

      // Mark add-on items with parent relationship
      final enrichedResponse = _enrichCartResponseWithParentInfo(
        response,
        payload,
      );

      await StorageService.saveCartData(enrichedResponse);
      NavigationService.instance.refreshCartCount();
      NavigationService.instance.refreshCartItems();

      if (!mounted) return;
      NavigationService.instance.switchToTab(
        2,
      ); // Cart is now at index 2 (after removing wishlist)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint('Add-to-cart failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to add to cart: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      } else {
        _isAddingToCart = false;
      }
    }
  }

  Map<String, dynamic> _enrichCartResponseWithParentInfo(
    Map<String, dynamic> response,
    Map<String, dynamic> payload,
  ) {
    final enrichedResponse = Map<String, dynamic>.from(response);
    final cartData = enrichedResponse['cart'];

    if (cartData is! Map<String, dynamic>) {
      return enrichedResponse;
    }

    final enrichedCart = Map<String, dynamic>.from(cartData);
    final addonItemsIds = payload['addon_items_id'] as List?;

    if (addonItemsIds == null || addonItemsIds.isEmpty) {
      return enrichedResponse;
    }

    // Find the main product cart key (most recently added, usually last entry)
    String? mainProductCartKey;
    final mainProductId = payload['id'];

    for (final entry in enrichedCart.entries) {
      final itemData = entry.value as Map<String, dynamic>?;
      if (itemData != null) {
        final productDetails = itemData['item'] as Map<String, dynamic>?;
        final productId = productDetails?['id'];

        if (productId == mainProductId) {
          mainProductCartKey = entry.key;
          break;
        }
      }
    }

    if (mainProductCartKey != null) {
      // Mark add-on items with parent cart key
      for (final entry in enrichedCart.entries) {
        final itemData = entry.value as Map<String, dynamic>?;
        if (itemData != null) {
          final productDetails = itemData['item'] as Map<String, dynamic>?;
          final productId = productDetails?['id'];

          if (addonItemsIds.contains(productId)) {
            itemData['is_addon'] = 1;
            itemData['parent_cart_key'] = mainProductCartKey;
          }
        }
      }
    }

    enrichedResponse['cart'] = enrichedCart;
    return enrichedResponse;
  }

  Widget _buildProductInformation() {
    // Process HTML content to handle {file}...{/file} tags
    String? processedHtml = _product?.details;
    if (processedHtml != null) {
      // Convert {file}...{/file} tags to styled spans
      processedHtml = processedHtml.replaceAllMapped(
        RegExp(r'\{file\}(.*?)\{/file\}', dotAll: true),
        (match) {
          final fileContent = match.group(1) ?? '';
          return '<span style="font-family: monospace; background-color: #f0f0f0; padding: 2px 6px; border-radius: 3px; font-weight: 600; color: #151D51;">$fileContent</span>';
        },
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Product Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151D51),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [Colors.yellow[600]!, Colors.grey[300]!],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (processedHtml != null && processedHtml.isNotEmpty)
            Html(
              data: processedHtml,
              style: {
                'body': Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(13.0),
                  color: const Color(0xFF151D51),
                  lineHeight: const LineHeight(1.4),
                ),
                'p': Style(
                  margin: Margins.only(bottom: 8),
                  padding: HtmlPaddings.zero,
                ),
                'h4': Style(
                  margin: Margins.only(top: 12, bottom: 8),
                  fontSize: FontSize(16.0),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF151D51),
                ),
                'h5': Style(
                  margin: Margins.only(top: 10, bottom: 6),
                  fontSize: FontSize(14.0),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF151D51),
                ),
                'ul': Style(
                  margin: Margins.only(top: 8, bottom: 8, left: 16),
                  padding: HtmlPaddings.zero,
                ),
                'li': Style(
                  margin: Margins.only(bottom: 4),
                  padding: HtmlPaddings.zero,
                ),
                'span': Style(display: Display.inline),
              },
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'No product information available.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
