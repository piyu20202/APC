import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:marquee/marquee.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/settings_service.dart';
import '../../../data/services/cart_service.dart';
import '../../../data/services/cart_payload_builder.dart';
import '../../../services/navigation_service.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../data/models/product_details_model.dart';
import '../../../data/models/product_detail_response.dart';
import 'addon_detail_screen.dart';
import '../../../data/models/settings_model.dart';
import '../../../services/storage_service.dart';
import '../../../core/exceptions/api_exception.dart';
import '../widget/cart_feedback_overlay.dart';
import 'get_more_info_modal.dart';

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
  final GlobalKey _upgradeAddonKey = GlobalKey();
  final GlobalKey _productInfoKey = GlobalKey();

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
  bool _isPriceUpdating =
      false; // shows a brief loader while price recalculates

  // Settings state
  SettingsModel? _settings;

  // Footer state
  int kitQuantity = 1;

  final Map<int, int> _selectedQtyForCustomise = {};

  // Multi-upgrade selection state:
  // Each upgrade product tracks independently:
  //   _upgradeMainSelected[upgradeProductId] = true  → main product is selected
  //   _selectedSubProductIndex[upgradeProductId] = N → sub-product N is selected
  //                                                    (-1 = no sub selected)
  // An upgrade product can have EITHER its main product selected OR a sub-product,
  // but not both (mutual exclusion within the same upgrade product row).
  // Different upgrade product rows are fully independent.
  final Map<int, bool> _upgradeMainSelected = {};
  // upgradeProductId -> subProductIndex (-1 means no sub selected)
  final Map<int, int> _selectedSubProductIndex = {};

  List<bool> _addOnSelections = [];
  List<int> _addOnQuantities = [];
  bool _hasUserManuallySelectedUpgrade =
      false; // Track if user manually selected upgrade

  // ---------------------------------------------------------------------------
  // Compatibility shim: CartPayloadBuilder and other helpers still reference
  // _selectedUpgradeIndex. We keep it as a computed property pointing to the
  // first selected upgrade product index for backwards compat. When all
  // upgrades are fully decoupled from CartPayloadBuilder this can be removed.
  // ---------------------------------------------------------------------------
  int get _selectedUpgradeIndex {
    for (int i = 0; i < _upgradeProducts.length; i++) {
      final id = _upgradeProducts[i].id;
      if (_upgradeMainSelected[id] == true) return i;
      final subIdx = _selectedSubProductIndex[id] ?? -1;
      if (subIdx >= 0) return i;
    }
    return -1;
  }

  bool get _isKitProduct => (_product?.isKIT?.toLowerCase() ?? '') == 'yes';

  /// True when product data is loaded successfully; false when loading, error, or null.
  bool get _isProductLoaded => _product != null && _errorMessage == null;

  /// Special quote-only product: hide pricing/cart UI and show custom footer.
  bool get _isSpecialQuoteProduct =>
      _product != null &&
      (_product!.showPrice ?? 1) == 0 &&
      (_product!.showAddToCart ?? 1) == 0;

  bool get _isProductOutOfStock => (_product?.outOfStock ?? 0) == 1;

  String get _tradeUserProductContent =>
      _settings?.generalSettings.tradeUserProductContent.trim() ?? '';

  bool get _showTradeUserProductFooter =>
      _isSpecialQuoteProduct && _tradeUserProductContent.isNotEmpty;

  /// Determines if the Upgrades section should be shown at all.
  ///
  /// We always show the section for kit products, even if there are
  /// no upgrade items, so that we can explicitly tell the user that
  /// no upgrades are available for this kit.
  bool get _shouldShowUpgradesSection => _isKitProduct;

  /// Checks if user has made any customization (quantities, upgrades, or add-ons)
  bool get _hasUserMadeCustomizations {
    final customiseData = getCustomiseKitData();
    final upgradeData = getSelectedUpgradeData();
    final addOnData = getSelectedAddOnData();

    // Check if quantities were changed from base
    final hasCustomise = customiseData.any((item) {
      final itemData = _qtyUpgradeProducts.firstWhere(
        (p) => p.id == item['id'],
        orElse: () => _qtyUpgradeProducts.first,
      );
      final selectedQty = item['qty'] as int;
      final baseQty = itemData.productBaseQuantity;
      return selectedQty > baseQty;
    });

    // Check if user manually selected an upgrade (not auto-selected default)
    final hasUpgrade =
        _hasUserManuallySelectedUpgrade &&
        upgradeData != null &&
        (upgradeData['isUpgrade'] as bool? ?? false) &&
        (upgradeData['price'] as num) > 0;

    // Check if any add-ons were selected
    final hasAddOn = addOnData.isNotEmpty;

    return hasCustomise || hasUpgrade || hasAddOn;
  }

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
    final minQty =
        (item.minQuantity > 0 ? item.minQuantity : item.productBaseQuantity)
            .clamp(1, 9999);
    final maxQty = item.maxQuantity >= minQty
        ? item.maxQuantity.clamp(minQty, 9999)
        : minQty;
    final totalOptions = (maxQty - minQty + 1).clamp(1, 9999);
    return List<int>.generate(totalOptions, (index) => minQty + index);
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

  /// Shows a brief spinner on the price display while the widget tree settles
  /// after an upgrade selection change. Call this instead of plain setState
  /// whenever a selection that affects price is toggled.
  void _triggerPriceUpdate(VoidCallback stateChange) {
    setState(() {
      _isPriceUpdating = true;
      stateChange();
    });
    // One post-frame callback is enough — the price is already correct by then,
    // we just need the spinner to render for at least one visible frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isPriceUpdating = false);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _resolveSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
    });
  }

  /// Reads `/settings` from SharedPreferences and refreshes from API when needed.
  Future<SettingsModel?> _resolveSettings() async {
    var settings = await StorageService.getSettings();
    final cachedPhone = settings?.pageSettings.phone.trim() ?? '';
    final tradeContent =
        settings?.generalSettings.tradeUserProductContent.trim() ?? '';
    if (cachedPhone.isNotEmpty && tradeContent.isNotEmpty) return settings;

    try {
      settings = await SettingsService().getSettings();
      await StorageService.saveSettings(settings);
      return settings;
    } catch (_) {
      return settings;
    }
  }

  String _prepareTradeUserProductHtml(String raw) {
    var html = raw.replaceAll('\r\n', '').trim();
    html = html.replaceAllMapped(
      RegExp(
        r'''<a[^>]*togglePopup\s*\(\s*['"]contactPopup['"]\s*\)[^>]*>(.*?)</a>''',
        caseSensitive: false,
        dotAll: true,
      ),
      (match) => '<a href="app-call-us">${match.group(1) ?? ''}</a>',
    );
    html = html.replaceAllMapped(
      RegExp(
        r'''<a[^>]*togglePopup\s*\(\s*['"]inquiryPopup['"]\s*\)[^>]*>(.*?)</a>''',
        caseSensitive: false,
        dotAll: true,
      ),
      (match) => '<a href="app-inquiry-form">${match.group(1) ?? ''}</a>',
    );
    html = html.replaceAll(
      RegExp(r'\s*onclick="[^"]*"', caseSensitive: false),
      '',
    );
    html = html.replaceAll(
      RegExp(r"\s*onclick='[^']*'", caseSensitive: false),
      '',
    );
    return html;
  }

  void _handleTradeUserProductLinkTap(String? url) {
    if (url == null || url.isEmpty) return;

    final normalized = url.toLowerCase();
    final isCallUsLink =
        normalized.contains('contactpopup') || normalized == 'app-call-us';
    final isInquiryLink =
        normalized.contains('inquirypopup') || normalized == 'app-inquiry-form';

    if (!isCallUsLink && !isInquiryLink) return;

    Navigator.pop(context);
    NavigationService.instance.switchToTab(4);
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
            detailResponse.qtyUpgradeProducts.map((item) {
              // Use the first valid option (minQuantity or productBaseQuantity)
              final minQty = item.minQuantity > 0
                  ? item.minQuantity
                  : item.productBaseQuantity;
              final startQty = minQty.clamp(1, 9999);
              return MapEntry(item.id, startQty);
            }),
          );

        // Default state: ALL upgrade products start with their main product
        // selected. Each upgrade product row is fully independent — the user can
        // select main OR one of its sub-products, but not both.
        _upgradeMainSelected.clear();
        _selectedSubProductIndex.clear();
        for (final up in detailResponse.upgradeProducts) {
          _upgradeMainSelected[up.id] =
              true; // main product selected by default
          _selectedSubProductIndex[up.id] = -1; // no sub-product selected
        }
        _hasUserManuallySelectedUpgrade =
            detailResponse.upgradeProducts.isNotEmpty;
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
    } on ApiException catch (e) {
      String message;
      if (e.statusCode == 500) {
        message = 'Server error. Please try again later.';
      } else if (e.statusCode == 404) {
        message =
            'This product is currently unavailable. Please try another product.';
      } else if (e.statusCode == 401) {
        message = 'Unauthorized. Please check your credentials.';
      } else {
        message = e.message.isNotEmpty
            ? e.message
            : 'Failed to load product details. Please try again.';
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.red[700],
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
    } catch (e) {
      const message = 'An unexpected error occurred. Please try again.';
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(message),
                backgroundColor: Colors.red[700],
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _imageController.dispose();
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

  void _scrollToCustomizationSection() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildGetMoreInfoButton() {
    return GestureDetector(
      onTap: _showGetMoreInfoModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: Colors.black, size: 14),
            SizedBox(width: 4),
            Text(
              'Get More Info',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGetMoreInfoModal() {
    final product = _product;
    if (product == null) return;

    GetMoreInfoModal.show(
      context,
      productId: product.id,
      sku: product.sku,
      productTitle: product.name,
    );
  }

  void _showCustomizationBottomSheet() {
    final customiseData = getCustomiseKitData();
    final upgradeData = getSelectedUpgradeData();
    final addOnData = getSelectedAddOnData();

    final hasCustomise = customiseData.any((item) {
      final itemData = _qtyUpgradeProducts.firstWhere(
        (p) => p.id == item['id'],
        orElse: () => _qtyUpgradeProducts.first,
      );
      return (item['qty'] as int) > itemData.productBaseQuantity;
    });

    final hasUpgrade =
        _hasUserManuallySelectedUpgrade &&
        upgradeData != null &&
        (upgradeData['isUpgrade'] as bool? ?? false) &&
        (upgradeData['price'] as num) > 0;

    final hasAddOn = addOnData.isNotEmpty;
    final hasAny = hasCustomise || hasUpgrade || hasAddOn;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Color(0xFF2E7D32),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Your Customised Kit Includes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF151D51),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey[200]),
                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      20 + bottomPadding,
                    ),
                    child: hasAny
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasCustomise)
                                ...customiseData
                                    .where((item) {
                                      final itemData = _qtyUpgradeProducts
                                          .firstWhere(
                                            (p) => p.id == item['id'],
                                            orElse: () =>
                                                _qtyUpgradeProducts.first,
                                          );
                                      return (item['qty'] as int) >
                                          itemData.productBaseQuantity;
                                    })
                                    .map((item) {
                                      final itemData = _qtyUpgradeProducts
                                          .firstWhere(
                                            (p) => p.id == item['id'],
                                            orElse: () =>
                                                _qtyUpgradeProducts.first,
                                          );
                                      return _buildBottomSheetRow(
                                        'Customise: ${itemData.name} - Qty: ${item['qty']}',
                                      );
                                    }),
                              if (hasUpgrade)
                                _buildBottomSheetRow(
                                  'Upgrade: ${_getUpgradeName(upgradeData)} - Qty: ${upgradeData!['qty']}',
                                ),
                              if (hasAddOn)
                                ...addOnData.map((item) {
                                  final itemData = _addonProducts.firstWhere(
                                    (p) => p.id == item['id'],
                                    orElse: () => _addonProducts.first,
                                  );
                                  return _buildBottomSheetRow(
                                    'Add-On: ${itemData.name} - Qty: ${item['qty']}',
                                  );
                                }),
                            ],
                          )
                        : Column(
                            children: [
                              const SizedBox(height: 20),
                              Icon(
                                Icons.tune_rounded,
                                size: 52,
                                color: Colors.grey[200],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No customizations yet',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Select upgrades or add-ons to\nsee your customization here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[400],
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetRow(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
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
      bottomNavigationBar: (_isProductLoaded && _showTradeUserProductFooter)
          ? _buildSpecialQuoteFooter()
          : SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Scroll to Top + View Customization buttons (kit products only)
                  if (_isKitProduct && _isProductLoaded)
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Scroll to Top - left
                          GestureDetector(
                            onTap: _scrollToTop,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.keyboard_arrow_up,
                                  size: 16,
                                  color: Colors.orange[700],
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Scroll to Top',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // View Customization - right
                          GestureDetector(
                            onTap: _isProductOutOfStock
                                ? null
                                : _showCustomizationBottomSheet,
                            child: Opacity(
                              opacity: _isProductOutOfStock ? 0.45 : 1,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.visibility_outlined,
                                    size: 16,
                                    color: _hasUserMadeCustomizations
                                        ? const Color(0xFF2E7D32)
                                        : Colors.grey[500],
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'View Customization',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _hasUserMadeCustomizations
                                          ? const Color(0xFF2E7D32)
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_isKitProduct && _isProductLoaded)
                    Divider(height: 1, color: Colors.grey[200]),
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
                              Text(
                                _isKitProduct ? 'Kit Quantity:' : 'Quantity',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Minus button (disabled when product not loaded / error)
                                  GestureDetector(
                                    onTap:
                                        _isProductLoaded &&
                                            !_isProductOutOfStock
                                        ? () {
                                            if (kitQuantity > 1) {
                                              setState(() {
                                                kitQuantity--;
                                              });
                                            }
                                          }
                                        : null,
                                    child: Opacity(
                                      opacity:
                                          _isProductLoaded &&
                                              !_isProductOutOfStock
                                          ? 1.0
                                          : 0.5,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey[400]!,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.remove,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Quantity
                                  Opacity(
                                    opacity:
                                        _isProductLoaded &&
                                            !_isProductOutOfStock
                                        ? 1.0
                                        : 0.5,
                                    child: Container(
                                      width: 28,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey[400]!,
                                        ),
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
                                  ),
                                  const SizedBox(width: 6),
                                  // Plus button (disabled when product not loaded / error)
                                  GestureDetector(
                                    onTap:
                                        _isProductLoaded &&
                                            !_isProductOutOfStock
                                        ? () {
                                            setState(() {
                                              kitQuantity++;
                                            });
                                          }
                                        : null,
                                    child: Opacity(
                                      opacity:
                                          _isProductLoaded &&
                                              !_isProductOutOfStock
                                          ? 1.0
                                          : 0.5,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey[400]!,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
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
                                  if (_isPriceUpdating)
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.orange[700],
                                      ),
                                    )
                                  else
                                    Text(
                                      '\$${_formatCurrency(_calculateFinalPrice())}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  // Add to Cart Button (disabled when product not loaded / error)
                                  GestureDetector(
                                    onTap:
                                        (_isAddingToCart ||
                                            !_isProductLoaded ||
                                            (_product?.outOfStock ?? 0) == 1)
                                        ? null
                                        : _handleAddToCart,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            !_isProductLoaded ||
                                                (_product?.outOfStock ?? 0) == 1
                                            ? Colors.grey[400]
                                            : Colors.orange,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: !_isProductLoaded
                                          ? const Text(
                                              'Add',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : (_product?.outOfStock ?? 0) == 1
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
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
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
                                                  'Add',
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
                                    _settings?.pageSettings.phone ??
                                        '1800 694 283',
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
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  'Business Day',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
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
      body: Stack(
        children: [
          // ── Main page content ──────────────────────────────────────────────
          // Always built so the Scaffold layout is stable; the overlay sits on
          // top while the API call is in flight.
          if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    size: 72,
                    color: Color(0xFFBDBDBD),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Oops! Product Unavailable',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Go Back'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _fetchProductDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else if (_product == null && !_isLoading)
            const Center(child: Text('Product not found'))
          else if (_product != null)
            SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Images Section
                  _buildProductImagesSection(),

                  // Product Details
                  _buildProductDetails(),

                  if (_isKitProduct && !_isSpecialQuoteProduct) ...[
                    _buildKitIncludes(),
                    _buildCustomiseYourKit(),
                    if (_shouldShowUpgradesSection)
                      _buildUpgrades(key: _upgradeAddonKey),
                    if (_addonProducts.isNotEmpty)
                      _buildAddOnItems(
                        key: _shouldShowUpgradesSection
                            ? null
                            : _upgradeAddonKey,
                      ),
                  ],

                  // Product Information section
                  _buildProductInformation(),

                  // Footer content moved into scrollable area
                  _buildScrollableFooter(),
                ],
              ),
            ),

          // ── Loading overlay ────────────────────────────────────────────────
          // A soft translucent white sheet covers the entire page while the API
          // call is in flight. Sits above content so layout doesn't jump.
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.82),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF151D51),
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Loading product...',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF151D51),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String? _detailSaleLabel() {
    final label = _product?.onSaleLine;
    if (label == null) return null;
    final trimmed = label.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Widget _buildDetailSaleTopBannerLabel(String text) {
    const fontSize = 12.0;
    final style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: fontSize,
      height: 1.2,
    );
    final lineHeight = fontSize * 1.2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        if (painter.width <= constraints.maxWidth) {
          return SizedBox(
            height: lineHeight,
            width: double.infinity,
            child: Center(
              child: Text(
                text,
                style: style,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

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
      },
    );
  }

  Widget _buildDetailOutOfStockBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
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
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProductImagesSection() {
    final images = productImages;
    if (images.isEmpty) {
      return Container(
        height: 320,
        color: Colors.white,
        child: const Center(
          child: Icon(Icons.image, size: 50, color: Colors.grey),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Image + Badges
          SizedBox(
            height: 280,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _imageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          final imageUrl = images[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullScreenImageGallery(
                                        images: images,
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                },
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                        Icons.error_outline,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_detailSaleLabel() case final saleLine?)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
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
                              horizontal: 10,
                              vertical: 7,
                            ),
                            child: _buildDetailSaleTopBannerLabel(saleLine),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isProductOutOfStock)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _buildDetailOutOfStockBadge(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _buildGetMoreInfoButton(),
          ),
          const SizedBox(height: 16),
          // Indicator Dots
          if (images.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? const Color(0xFF151D51)
                        : Colors.grey[300],
                  ),
                );
              }),
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
          if (hasAddonOrUpgrade && !_isSpecialQuoteProduct) ...[
            Opacity(
              opacity: isInStock ? 1 : 0.5,
              child: AbsorbPointer(
                absorbing: !isInStock,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      final keyContext = _upgradeAddonKey.currentContext;
                      if (keyContext != null) {
                        Scrollable.ensureVisible(
                          keyContext,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          alignment: 0.0,
                        );
                      } else if (_scrollController.hasClients) {
                        final pos = _scrollController.position;
                        _scrollController.animateTo(
                          pos.maxScrollExtent,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.orange.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'ADD-ON & UPGRADE ITEMS AVAILABLE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          Text(
            _product!.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          // `View Customization` button moved to Add-On Items section
          if (_isKitProduct) const SizedBox(height: 4),
          Text(
            'Product SKU: ${_product!.sku}',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          if (!_isSpecialQuoteProduct) ...[
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
            // Shipping Display Section
            if ((_product?.showFreeShippingIcon ?? 0) == 1 ||
                (_product?.showFreightCostIcon ?? 0) == 1) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  // Free Shipping Badge
                  if ((_product?.showFreeShippingIcon ?? 0) == 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9), // Light green
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF2E7D32),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Free Shipping',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Freight Delivery Badge
                  if ((_product?.showFreightCostIcon ?? 0) == 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF6), // Light navy
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF151D51).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.local_shipping_outlined,
                            color: Color(0xFF151D51),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Freight Delivery',
                            style: TextStyle(
                              color: Color(0xFF151D51),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF151D51),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
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
            /*
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE802),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'ZIP',
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
          */
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
            // Feature Badges
            _buildFeatureBadges(),
          ],
        ],
      ),
    );
  }

  /// Builds feature badge tiles below the short description.
  /// Shows `trade_features` for trade customers, `features` for normal customers.
  /// Background color is driven by the `colors` field from the API (index-matched).
  /// Fallback: dark green #006400 with white text.
  Widget _buildFeatureBadges() {
    if (_product == null) return const SizedBox.shrink();

    // customerType field directly se pata chalta hai — 'trade' ya 'normal'
    final isTradeCustomer =
        _product!.customerType.toLowerCase().trim() == 'trade';

    // Trade customer ko tradeFeatures, normal ko features
    final dynamic rawFeatures = isTradeCustomer
        ? _product!.tradeFeatures
        : _product!.features;

    if (rawFeatures == null) return const SizedBox.shrink();

    // Parse features: supports String, List<dynamic>
    List<String> badges;
    if (rawFeatures is String) {
      final s = rawFeatures.trim();
      if (s.isEmpty) return const SizedBox.shrink();
      badges = [s];
    } else if (rawFeatures is List) {
      badges = rawFeatures
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      return const SizedBox.shrink();
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    // Safely try to read `colors` from the model's JSON map (field may not exist in model yet)
    List<String> featureColors = [];
    try {
      final json = _product!.toJson();
      final rawColors = json['colors'];
      if (rawColors is List) {
        featureColors = rawColors
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (rawColors is String && rawColors.trim().isNotEmpty) {
        featureColors = [rawColors.trim()];
      }
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: badges.asMap().entries.map((entry) {
          final idx = entry.key;
          String display = entry.value;

          // Strip surrounding brackets e.g. [CONTROL WITH YOUR PHONE]
          display = display.replaceAll(RegExp(r'^\[|\]$'), '').trim();

          // Dynamic color from API, fallback to dark green #006400
          const Color fallbackColor = Color(0xFF006400);
          Color bgColor = fallbackColor;

          if (idx < featureColors.length) {
            final hexStr = featureColors[idx].replaceAll('#', '').trim();
            if (hexStr.length == 6 || hexStr.length == 8) {
              final fullHex = hexStr.length == 6 ? 'FF$hexStr' : hexStr;
              final parsed = int.tryParse(fullHex, radix: 16);
              if (parsed != null) bgColor = Color(parsed);
            }
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              display.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScrollableFooter() {
    // Bottom padding for scroll area — buttons are now in fixed footer
    return const SizedBox(height: 16);
  }

  Widget _buildSpecialQuoteFooter() {
    final html = _prepareTradeUserProductHtml(_tradeUserProductContent);
    if (html.isEmpty) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade300, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade800, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Html(
                  data: html,
                  onLinkTap: (url, _, __) =>
                      _handleTradeUserProductLinkTap(url),
                  style: {
                    'body': Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(14.0),
                      color: const Color(0xFF5D4037),
                      lineHeight: const LineHeight(1.5),
                      fontWeight: FontWeight.w500,
                    ),
                    'p': Style(
                      margin: Margins.only(bottom: 8),
                      padding: HtmlPaddings.zero,
                    ),
                    'a': Style(
                      color: const Color(0xFF151D51),
                      fontWeight: FontWeight.bold,
                      textDecoration: TextDecoration.underline,
                    ),
                    'strong': Style(fontWeight: FontWeight.bold),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
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

  /// Gets a unified selection key for the current upgrade selection (compat shim).
  String? get _currentUpgradeSelectionKey {
    final idx = _selectedUpgradeIndex;
    if (idx < 0 || idx >= _upgradeProducts.length) return null;
    return _upgradeSelectionKeyFor(_upgradeProducts[idx].id, idx);
  }

  /// Returns the radio groupValue for the upgrade product at [index] with [id].
  /// - 'main_N'   → main product of row N is selected
  /// - 'sub_N_M'  → sub-product M of row N is selected
  /// - null       → nothing selected in this row
  String? _upgradeSelectionKeyFor(int upgradeProductId, int index) {
    if (_upgradeMainSelected[upgradeProductId] == true) {
      return 'main_$index';
    }
    final subIdx = _selectedSubProductIndex[upgradeProductId] ?? -1;
    if (subIdx >= 0) return 'sub_${index}_$subIdx';
    return null;
  }

  Widget _buildKitIncludes() {
    if (!_isKitProduct) {
      return const SizedBox.shrink();
    }

    if (_kitIncludesOne.isEmpty && _kitIncludesTwo.isEmpty) {
      return const SizedBox.shrink();
    }

    final allItems = [..._kitIncludesOne, ..._kitIncludesTwo];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Kit Includes'),
          const SizedBox(height: 12),
          ...allItems.asMap().entries.map((entry) {
            final item = entry.value;
            final displayNumber = entry.key + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
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
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 3),
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
          }),
        ],
      ),
    );
  }

  Widget _buildCustomiseYourKit() {
    if (!_isKitProduct || _qtyUpgradeProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return AbsorbPointer(
      absorbing: _isProductOutOfStock,
      child: Opacity(
        opacity: _isProductOutOfStock ? 0.5 : 1,
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Customise your Kit'),
              const SizedBox(height: 12),
              Column(
                children: List.generate(_qtyUpgradeProducts.length, (index) {
                  final item = _qtyUpgradeProducts[index];
                  final selectedQty =
                      _selectedQtyForCustomise[item.id] ??
                      item.productBaseQuantity;
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
                                  errorWidget: (context, url, error) =>
                                      Container(
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
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                  SizedBox(
                                    width: 160,
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          value: () {
                                            if (quantityOptions.isEmpty)
                                              return null;
                                            return quantityOptions.contains(
                                                  selectedQty,
                                                )
                                                ? selectedQty
                                                : quantityOptions.first;
                                          }(),
                                          isDense: true,
                                          isExpanded: true,
                                          iconSize: 14,
                                          items: quantityOptions.map((qty) {
                                            final optionExtra =
                                                _calculateExtraCost(item, qty);
                                            final formattedExtra =
                                                _formatCurrency(optionExtra);
                                            final displayText =
                                                optionExtra == 0.0
                                                ? 'Qty: $qty'
                                                : 'Qty: $qty (+\$$formattedExtra)';
                                            return DropdownMenuItem<int>(
                                              value: qty,
                                              child: Text(
                                                displayText,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            if (value == null) return;
                                            setState(() {
                                              _selectedQtyForCustomise[item
                                                      .id] =
                                                  value;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '+\$${_formatCurrency(extraCost)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: extraCost > 0
                                            ? Colors.green[700]
                                            : Colors.black38,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpgrades({Key? key}) {
    // Only relevant for kit products
    if (!_shouldShowUpgradesSection) {
      return const SizedBox.shrink();
    }

    final hasUpgradeData =
        _qtyUpgradeProducts.any((item) => item.isUpgradeQty) &&
        _upgradeProducts.isNotEmpty;

    return AbsorbPointer(
      absorbing: _isProductOutOfStock,
      child: Opacity(
        opacity: _isProductOutOfStock ? 0.5 : 1,
        child: Container(
          key: key,
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
                Column(
                  children: List.generate(_upgradeProducts.length, (index) {
                    final item = _upgradeProducts[index];
                    final selectedSubIndex =
                        _selectedSubProductIndex[item.id] ?? -1;

                    return Column(
                      children: [
                        _buildUpgradeProductCard(item, index, selectedSubIndex),
                        if (item.subProducts.isNotEmpty)
                          Column(
                            children: item.subProducts
                                .asMap()
                                .entries
                                .map(
                                  (entry) => _buildSubProductCard(
                                    item,
                                    index,
                                    entry.value,
                                    entry.key,
                                    selectedSubIndex,
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    );
                  }),
                ),
            ],
          ), // closes outer Column
        ),
      ),
    ); // closes Container wrapper
  }

  Widget _buildUpgradeProductCard(
    UpgradeProduct item,
    int index,
    int selectedSubIndex,
  ) {
    final imageUrl = _resolveImageUrl(item.photo);
    final isSelected = _upgradeMainSelected[item.id] == true;

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
            // Each upgrade product has its own radio group (keyed by product id),
            // so rows are independent — selecting main here doesn't affect others.
            groupValue: _upgradeSelectionKeyFor(item.id, index),
            activeColor: Colors.blue,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: item.outOfStock == 1 || _isProductOutOfStock
                ? null
                : (value) {
                    _triggerPriceUpdate(() {
                      // Select main product → deselect any sub-product for this row
                      _upgradeMainSelected[item.id] = true;
                      _selectedSubProductIndex[item.id] = -1;
                      _hasUserManuallySelectedUpgrade = true;
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
    // Sub-product is selected when its own row's sub-index matches
    final isSelected =
        (_selectedSubProductIndex[parentItem.id] ?? -1) == subIndex;

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
            // Scoped to the parent upgrade product's own group — independent of other rows
            groupValue: _upgradeSelectionKeyFor(parentItem.id, parentIndex),
            activeColor: Colors.blue,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: subProduct.outOfStock == 1 || _isProductOutOfStock
                ? null
                : (value) {
                    _triggerPriceUpdate(() {
                      // Selecting a sub-product deselects the main product for this row
                      _upgradeMainSelected[parentItem.id] = false;
                      _selectedSubProductIndex[parentItem.id] = subIndex;
                      _hasUserManuallySelectedUpgrade = true;
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

  Widget _buildAddOnItems({Key? key}) {
    if (_addonProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_addOnSelections.length != _addonProducts.length ||
        _addOnQuantities.length != _addonProducts.length) {
      _addOnSelections = List<bool>.filled(_addonProducts.length, false);
      _addOnQuantities = List<int>.filled(_addonProducts.length, 1);
    }

    return AbsorbPointer(
      absorbing: _isProductOutOfStock,
      child: Opacity(
        opacity: _isProductOutOfStock ? 0.5 : 1,
        child: Container(
          key: key,
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
              Column(
                children: List.generate(_addonProducts.length, (index) {
                  final item = _addonProducts[index];
                  final inStock = item.isInStock;
                  final showSave = item.savePrice > 0;
                  final isSelected =
                      index < _addOnSelections.length &&
                      _addOnSelections[index];
                  final storedQuantity = index < _addOnQuantities.length
                      ? _addOnQuantities[index]
                      : 1;
                  final maxQty = item.maxQuantity > 0 ? item.maxQuantity : 1;
                  final quantity = storedQuantity.clamp(1, maxQty);
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // Changed from start to center for better alignment without IntrinsicHeight
                      children: [
                        Transform.scale(
                          scale: 0.9,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: inStock && !_isProductOutOfStock
                                ? (value) {
                                    setState(() {
                                      _addOnSelections[index] = value ?? false;
                                      // Price will update automatically via _calculateFinalPrice()
                                    });
                                  }
                                : null,
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
                                  errorWidget: (context, url, error) =>
                                      Container(
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
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  // Out-of-stock: muted grey only — no strikethrough
                                  // so the title stays fully readable
                                  color: inStock
                                      ? const Color(0xFF151D51)
                                      : Colors.grey,
                                  height: 1.35,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
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
                              if (!inStock) ...[
                                const SizedBox(height: 4),
                                const Text(
                                  'Out of Stock',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Right-side: qty dropdown + price stacked, fixed width
                        SizedBox(
                          width: 100,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (inStock)
                                Container(
                                  width: 100,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: quantity,
                                      isDense: true,
                                      isExpanded: true,
                                      items: List.generate(maxQty, (i) {
                                        final qty = i + 1;
                                        return DropdownMenuItem<int>(
                                          value: qty,
                                          child: Text(
                                            'Qty: $qty',
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                        );
                                      }),
                                      onChanged: (val) {
                                        setState(() {
                                          _addOnQuantities[index] = val ?? 1;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              if (inStock) const SizedBox(height: 5),
                              // Unit price label
                              const Text(
                                'Unit Price',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF151D51),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 1),
                              // Price — always fits since parent width is fixed
                              FittedBox(
                                alignment: Alignment.centerRight,
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '\$${item.addonCurrentPrice.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF151D51),
                                  ),
                                ),
                              ),
                              if (showSave) ...[
                                const SizedBox(height: 1),
                                Text(
                                  '\$${item.addonPreviousPrice.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Save \$${item.savePrice.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              // Bottom-right: compact View Details button
                              TextButton(
                                onPressed:
                                    (item.details != null &&
                                        item.details!.isNotEmpty)
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddonDetailScreen(
                                              htmlContent: item.details ?? '',
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: Colors.blue,
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: const Text(
                                  'View Details',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
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

      await StorageService.saveCartDataWithProductHints(
        enrichedResponse,
        listingProduct: _product?.toJson() ?? {},
      );
      NavigationService.instance.refreshCartCount();
      NavigationService.instance.refreshCartItems();

      if (!mounted) return;
      if (mounted) {
        CartFeedbackOverlay.showSuccess(context);
      }
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
      key: _productInfoKey,
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

class FullScreenImageGallery extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageGallery({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Icon(Icons.image, color: Colors.white54, size: 64)),
      );
    }

    final clampedInitialIndex = initialIndex.clamp(0, images.length - 1);
    final pageController = PageController(initialPage: clampedInitialIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: images.length,
        itemBuilder: (context, index) {
          final imageUrl = images[index];
          final isNetwork = imageUrl.startsWith('http');

          return InteractiveViewer(
            child: Center(
              child: isNetwork
                  ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain)
                  : Image.asset(imageUrl, fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
