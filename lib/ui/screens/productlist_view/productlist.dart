import 'package:flutter/material.dart';
import '../widget/listing_product_card.dart';
import '../../../data/services/homepage_service.dart';
import '../../../data/models/homepage_model.dart';
import '../../../core/utils/logger.dart';
import '../../../core/network/network_checker.dart';
import '../widget/app_state_view.dart';

class ProductListScreen extends StatefulWidget {
  final int? categoryId;
  final int? subcategoryId;
  final int? childcategoryId;
  final int? subchildcategoryId;
  final String? title;
  final String? categorySlug;
  final String? categoryType;
  final int? page;
  final int? perPage;

  const ProductListScreen({
    super.key,
    this.categoryId,
    this.subcategoryId,
    this.childcategoryId,
    this.subchildcategoryId,
    this.title,
    this.categorySlug,
    this.categoryType,
    this.page,
    this.perPage,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

enum SortOption { popular, lowestPrice, highestPrice, latest, oldest }

class _ProductListScreenState extends State<ProductListScreen> {
  final HomepageService _homepageService = HomepageService();
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> _originalProducts =
      []; // Store original for sorting
  int _currentPage = 1;
  int _lastPage = 1;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  String? _errorMessage;
  SortOption _selectedSort = SortOption.popular;
  bool _isGridView = true;

  // Dummy products for fallback
  final List<Map<String, dynamic>> _dummyProducts = [
    {
      'id': 3001,
      'name': '3m Double Ring Top Gates (2x1.5m)',
      'sku': 'APC-RCTG-001',
      'description':
          'Classic Design Ring Top Gate, Satin Black Powdercoating, Robust 80x40 - 40x40 Steel + 19mm Pickets',
      'currentPrice': '\$825.00',
      'originalPrice': '\$999.00',
      'image': 'assets/images/2.png',
      'category': 'RING 3M',
      'onSale': true,
      'freightDelivery': true,
      'display_features': [
        'AUSTRALIA\'S FAVOURITE FARM GATE',
        'SUITABLE FOR 3M GATE',
      ],
    },
    {
      'id': 3002,
      'name': '4m Double Ring Top Gates (2x2m)',
      'sku': 'APC-RCTG-002',
      'description':
          'Premium Ring Top Gate Design, Black Powdercoating, Heavy Duty Steel Construction',
      'currentPrice': '\$950.00',
      'originalPrice': '\$1,199.00',
      'image': 'assets/images/2.png',
      'category': 'RING 4M',
      'onSale': true,
      'freightDelivery': true,
      'display_features': ['4 Meter Boom Gate'],
    },
    {
      'id': 3003,
      'name': '3m Single Ring Top Gate',
      'sku': 'APC-RCTG-003',
      'description':
          'Elegant Single Ring Design, Weather Resistant Coating, Durable Steel Frame',
      'currentPrice': '\$650.00',
      'originalPrice': '\$750.00',
      'image': 'assets/images/2.png',
      'category': 'RING 3M',
      'onSale': false,
      'freightDelivery': true,
      'display_features': [],
    },
  ];

  /// Core Helper function to safely extract and parse features (handles both String and Array)
  List<String> _parseFeatures(dynamic jsonValue) {
    if (jsonValue == null) return [];
    if (jsonValue is List) {
      return jsonValue
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (jsonValue is String && jsonValue.trim().isNotEmpty) {
      return [jsonValue.trim()];
    }
    return [];
  }

  /// Core Helper function to safely extract and parse colors (handles both String and Array)
  List<String> _parseColors(dynamic jsonValue) {
    if (jsonValue == null) return [];
    if (jsonValue is List) {
      return jsonValue
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (jsonValue is String && jsonValue.trim().isNotEmpty) {
      return [jsonValue.trim()];
    }
    return [];
  }

  String? _mapSortToApiSort(SortOption option) {
    switch (option) {
      case SortOption.lowestPrice:
        return 'price_asc';
      case SortOption.highestPrice:
        return 'price_desc';
      case SortOption.latest:
        return 'date_desc';
      case SortOption.oldest:
        return 'date_asc';
      case SortOption.popular:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProducts(sortParam: _mapSortToApiSort(_selectedSort));
  }

  Future<void> _onRefresh() async {
    final hasInternet = await NetworkChecker.hasConnection();
    if (!hasInternet) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please try again.'),
          ),
        );
      }
      return;
    }
    _currentPage = 1;
    await _loadProducts(sortParam: _mapSortToApiSort(_selectedSort), page: 1);
  }

  Future<void> _loadProducts({String? sortParam, int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final int effectivePerPage = widget.perPage ?? 40;
      print('📦 Listing perPage: $effectivePerPage (page: $page)');

      if (widget.categorySlug != null && widget.categoryType != null) {
        Logger.info(
          'Fetching products - slug: ${widget.categorySlug}, type: ${widget.categoryType}',
        );

        final result = await _homepageService.getProductsByCategory(
          categorySlug: widget.categorySlug,
          categoryType: widget.categoryType,
          page: page,
          perPage: effectivePerPage,
          categoryId: widget.categoryId,
          subcategoryId: widget.subcategoryId,
          childcategoryId: widget.childcategoryId,
          subchildcategoryId: widget.subchildcategoryId,
          sort: sortParam,
        );

        final apiProducts = List<LatestProduct>.from(result['products']);
        _currentPage = result['currentPage'];
        _lastPage = result['lastPage'];

        products = apiProducts.map<Map<String, dynamic>>((p) {
          // Dynamic check for trade vs normal properties on model
          dynamic rawFeatures;
          dynamic rawTradeFeatures;
          dynamic rawColors;
          try {
            rawTradeFeatures = (p as dynamic).trade_features;
          } catch (_) {
            rawTradeFeatures = null;
          }
          try {
            rawFeatures = (p as dynamic).features;
          } catch (_) {
            rawFeatures = null;
          }
          try {
            rawColors = (p as dynamic).colors;
          } catch (_) {
            rawColors = null;
          }

          // If still null, try to pull from toJson() map
          if ((rawFeatures == null ||
              rawTradeFeatures == null ||
              rawColors == null)) {
            try {
              final m = (p as dynamic).toJson();
              rawFeatures ??= m['features'];
              rawTradeFeatures ??= m['trade_features'];
              rawColors ??= m['colors'];
            } catch (_) {}
          }

          List<String> displayFeaturesList =
              _parseFeatures(rawTradeFeatures).isNotEmpty
              ? _parseFeatures(rawTradeFeatures)
              : _parseFeatures(rawFeatures);

          List<String> displayColorsList = _parseColors(rawColors);

          return {
            'id': p.id,
            'name': p.name,
            'sku': p.sku,
            'description': p.shortDescription ?? '',
            'currentPrice': p.price.toString(),
            'originalPrice': p.previousPrice.toString(),
            'price': p.price,
            'previous_price': p.previousPrice,
            'image': p.thumbnail,
            'thumbnail': p.thumbnail,
            'category': widget.title ?? '',
            'onSale': p.previousPrice > 0 && p.previousPrice > p.price,
            'show_freight_cost_icon': p.showFreightCostIcon,
            'show_free_shipping_icon': p.showFreeShippingIcon,
            'show_price': p.showPrice,
            'show_add_to_cart': p.showAddToCart,
            'out_of_stock': p.outOfStock,
            'onsale_line': p.onSaleLine,
            'display_features': displayFeaturesList, // Passed to listing cards
            'display_feature_colors':
                displayColorsList, // Per-feature background colors
          };
        }).toList();

        print(
          '📦 Listing grid products received: ${products.length} | perPage: $effectivePerPage | Page: $_currentPage/$_lastPage',
        );
        Logger.info(
          'Loaded ${products.length} products from API. Page: $_currentPage/$_lastPage',
        );
      } else if (widget.categoryId != null ||
          widget.subcategoryId != null ||
          widget.childcategoryId != null ||
          widget.subchildcategoryId != null) {
        Logger.info('Fetching products using ID fallback');

        final result = await _homepageService.getProductsByCategory(
          categoryId: widget.categoryId,
          subcategoryId: widget.subcategoryId,
          childcategoryId: widget.childcategoryId,
          subchildcategoryId: widget.subchildcategoryId,
          sort: sortParam,
          page: page,
          perPage: effectivePerPage,
        );

        final apiProducts = List<LatestProduct>.from(result['products']);
        _currentPage = result['currentPage'];
        _lastPage = result['lastPage'];

        products = apiProducts.map<Map<String, dynamic>>((p) {
          dynamic rawFeatures;
          dynamic rawTradeFeatures;
          dynamic rawColors;
          try {
            rawTradeFeatures = (p as dynamic).trade_features;
          } catch (_) {
            rawTradeFeatures = null;
          }
          try {
            rawFeatures = (p as dynamic).features;
          } catch (_) {
            rawFeatures = null;
          }
          try {
            rawColors = (p as dynamic).colors;
          } catch (_) {
            rawColors = null;
          }
          if ((rawFeatures == null ||
              rawTradeFeatures == null ||
              rawColors == null)) {
            try {
              final m = (p as dynamic).toJson();
              rawFeatures ??= m['features'];
              rawTradeFeatures ??= m['trade_features'];
              rawColors ??= m['colors'];
            } catch (_) {}
          }

          List<String> displayFeaturesList =
              _parseFeatures(rawTradeFeatures).isNotEmpty
              ? _parseFeatures(rawTradeFeatures)
              : _parseFeatures(rawFeatures);

          List<String> displayColorsList = _parseColors(rawColors);

          return {
            'id': p.id,
            'name': p.name,
            'sku': p.sku,
            'description': p.shortDescription ?? '',
            'currentPrice': p.price.toString(),
            'originalPrice': p.previousPrice.toString(),
            'price': p.price,
            'previous_price': p.previousPrice,
            'image': p.thumbnail,
            'thumbnail': p.thumbnail,
            'category': widget.title ?? '',
            'onSale': p.previousPrice > 0 && p.previousPrice > p.price,
            'show_freight_cost_icon': p.showFreightCostIcon,
            'show_free_shipping_icon': p.showFreeShippingIcon,
            'show_price': p.showPrice,
            'show_add_to_cart': p.showAddToCart,
            'out_of_stock': p.outOfStock,
            'onsale_line': p.onSaleLine,
            'display_features': displayFeaturesList,
            'display_feature_colors':
                displayColorsList, // Per-feature background colors
          };
        }).toList();

        print(
          '📦 Listing grid products received: ${products.length} | perPage: $effectivePerPage | Page: $_currentPage/$_lastPage',
        );
      } else {
        products = List.from(_dummyProducts);
        Logger.info('Using dummy products: ${products.length}');
      }

      _originalProducts = List.from(products);

      if (_selectedSort == SortOption.lowestPrice ||
          _selectedSort == SortOption.highestPrice) {
        _applyPriceSorting();
      } else {
        setState(() {
          products = List.from(_originalProducts);
        });
      }

      setState(() {
        _isLoading = false;
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      Logger.error('Failed to load products', e);
      setState(() {
        products = [];
        _originalProducts = [];
        _isLoading = false;
        _errorMessage = 'Failed to load products. Please try again.';
      });
    }
  }

  void _applyPriceSorting() {
    final sortedProducts = List<Map<String, dynamic>>.from(_originalProducts);
    switch (_selectedSort) {
      case SortOption.lowestPrice:
        sortedProducts.sort(
          (a, b) => ((a['price'] as num?)?.toDouble() ?? 0.0).compareTo(
            (b['price'] as num?)?.toDouble() ?? 0.0,
          ),
        );
        break;
      case SortOption.highestPrice:
        sortedProducts.sort(
          (a, b) => ((b['price'] as num?)?.toDouble() ?? 0.0).compareTo(
            (a['price'] as num?)?.toDouble() ?? 0.0,
          ),
        );
        break;
      default:
        break;
    }
    setState(() {
      products = sortedProducts;
    });
  }

  String _getSortOptionLabel(SortOption option) {
    switch (option) {
      case SortOption.popular:
        return 'Popular Products';
      case SortOption.lowestPrice:
        return 'Lowest Price';
      case SortOption.highestPrice:
        return 'Highest Price';
      case SortOption.latest:
        return 'Latest Product';
      case SortOption.oldest:
        return 'Oldest Product';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Product List',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFF2F0EF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() {
              _isGridView = !_isGridView;
            }),
          ),
        ],
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: _onRefresh,
        child: _buildBody(),
      ),
      bottomNavigationBar: products.isNotEmpty ? _buildPagination() : null,
    );
  }

  Widget _buildPagination() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _currentPage > 1
                  ? () => _loadProducts(
                      sortParam: _mapSortToApiSort(_selectedSort),
                      page: _currentPage - 1,
                    )
                  : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Prev'),
              style: TextButton.styleFrom(
                foregroundColor: _currentPage > 1
                    ? const Color(0xFF151D51)
                    : Colors.grey,
              ),
            ),
            Text(
              'Page $_currentPage of $_lastPage',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            TextButton(
              onPressed: _currentPage < _lastPage
                  ? () => _loadProducts(
                      sortParam: _mapSortToApiSort(_selectedSort),
                      page: _currentPage + 1,
                    )
                  : null,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text('Next'), Icon(Icons.chevron_right)],
              ),
              style: TextButton.styleFrom(
                foregroundColor: _currentPage < _lastPage
                    ? const Color(0xFF151D51)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                const Text(
                  'Sort By :',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildSortDropdown()),
              ],
            ),
          ),
        ),
        if (_isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: AppStateView(state: AppViewState.loading),
          )
        else if (_errorMessage != null && products.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppStateView(
              state: AppViewState.error,
              title: 'Failed to load products',
              message: _errorMessage,
              primaryActionLabel: 'Retry',
              onPrimaryAction: () =>
                  _loadProducts(sortParam: _mapSortToApiSort(_selectedSort)),
            ),
          )
        else if (products.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: AppStateView(
              state: AppViewState.empty,
              title: 'No products found',
              message: 'Pull down to refresh and try again.',
            ),
          )
        else
          (_isGridView
              ? (() {
                  print(
                    '📦 Listing grid showing: ${products.length} products | perPage: ${widget.perPage ?? 40}',
                  );
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.60,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            ListingProductCard(product: products[index]),
                        childCount: products.length,
                      ),
                    ),
                  );
                })()
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        ProductListCard(product: products[index]),
                    childCount: products.length,
                  ),
                )),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SortOption>(
          value: _selectedSort,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[700]),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          items: SortOption.values.map((SortOption option) {
            final isSelected = option == _selectedSort;
            return DropdownMenuItem<SortOption>(
              value: option,
              child: Row(
                children: [
                  if (isSelected) ...[
                    Icon(Icons.check, size: 18, color: const Color(0xFF151D51)),
                    const SizedBox(width: 8),
                  ] else ...[
                    const SizedBox(width: 26),
                  ],
                  Expanded(
                    child: Text(
                      _getSortOptionLabel(option),
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? const Color(0xFF151D51)
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (SortOption? newValue) {
            if (newValue != null && newValue != _selectedSort) {
              setState(() {
                _selectedSort = newValue;
                _currentPage = 1;
              });
              _loadProducts(sortParam: _mapSortToApiSort(newValue), page: 1);
            }
          },
        ),
      ),
    );
  }
}
