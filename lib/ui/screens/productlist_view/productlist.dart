import 'package:flutter/material.dart';
import '../widget/listing_product_card.dart';
import '../../../data/services/homepage_service.dart';
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
  bool _isLoading = true;
  String? _errorMessage;
  SortOption _selectedSort = SortOption.popular;

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
    },
    {
      'id': 3004,
      'name': '5m Double Ring Top Gates (2.5x2m)',
      'description':
          'Large Scale Ring Top Gate, Industrial Grade Steel, Professional Installation Ready',
      'currentPrice': '\$1,250.00',
      'originalPrice': '\$1,450.00',
      'image': 'assets/images/2.png',
      'category': 'RING 5M',
      'onSale': true,
      'freightDelivery': true,
    },
    {
      'id': 3005,
      'name': '2m Ring Top Gate Kit',
      'description':
          'Complete Gate Kit with Hardware, Easy Installation, Residential Grade',
      'currentPrice': '\$450.00',
      'originalPrice': '\$550.00',
      'image': 'assets/images/2.png',
      'category': 'RING 2M',
      'onSale': true,
      'freightDelivery': false,
    },
  ];

  /// Map UI sort options to API `sort` query parameter values
  /// Supported API values: date_desc, date_asc, price_desc, price_asc
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
        // Let backend fall back to its default sort (price_asc)
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
          const SnackBar(content: Text('No internet connection. Please try again.')),
        );
      }
      return;
    }
    await _loadProducts(sortParam: _mapSortToApiSort(_selectedSort));
  }

  Future<void> _loadProducts({String? sortParam}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // If category IDs are provided, fetch from API
      if (widget.categorySlug != null && widget.categoryType != null) {
        Logger.info(
          'Fetching products - slug: ${widget.categorySlug}, type: ${widget.categoryType}',
        );

        final apiProducts = await _homepageService.getProductsByCategory(
          categorySlug: widget.categorySlug,
          categoryType: widget.categoryType,
          page: widget.page,
          perPage: widget.perPage,
          categoryId: widget.categoryId,
          subcategoryId: widget.subcategoryId,
          childcategoryId: widget.childcategoryId,
          subchildcategoryId: widget.subchildcategoryId,
          sort: sortParam,
        );

        // Convert API products to map format for ProductCard
        products = apiProducts.map((p) {
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
            'freightDelivery': false,
            'out_of_stock': p.outOfStock,
          };
        }).toList();

        Logger.info('Loaded ${products.length} products from API');
      } else if (widget.categoryId != null ||
          widget.subcategoryId != null ||
          widget.childcategoryId != null ||
          widget.subchildcategoryId != null) {
        Logger.info(
          'Fetching products using ID fallback - categoryId: ${widget.categoryId}, subcategoryId: ${widget.subcategoryId}, childcategoryId: ${widget.childcategoryId}, subchildcategoryId: ${widget.subchildcategoryId}',
        );

        final apiProducts = await _homepageService.getProductsByCategory(
          categoryId: widget.categoryId,
          subcategoryId: widget.subcategoryId,
          childcategoryId: widget.childcategoryId,
          subchildcategoryId: widget.subchildcategoryId,
          sort: sortParam,
        );

        products = apiProducts.map((p) {
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
            'freightDelivery': false,
            'out_of_stock': p.outOfStock,
          };
        }).toList();
      } else {
        // Use dummy products if no category IDs provided
        products = List.from(_dummyProducts);
        Logger.info('Using dummy products: ${products.length}');
      }

      // Use backend sorted data directly
      _originalProducts = List.from(products);

      // Apply client-side price sorting as fallback only for price-based sorting
      // This ensures price sorting works even if backend sorting fails
      if (_selectedSort == SortOption.lowestPrice ||
          _selectedSort == SortOption.highestPrice) {
        _applyPriceSorting();
      } else {
        // For other sorts (Latest/Oldest/Popular), use backend sorted data as-is
        setState(() {
          products = List.from(_originalProducts);
        });
      }

      setState(() {
        _isLoading = false;
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

  /// Apply client-side price sorting as fallback
  /// Only used when backend sorting fails or for price-based sorting
  void _applyPriceSorting() {
    final sortedProducts = List<Map<String, dynamic>>.from(_originalProducts);

    switch (_selectedSort) {
      case SortOption.lowestPrice:
        sortedProducts.sort((a, b) {
          final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
          final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;
          return priceA.compareTo(priceB);
        });
        break;
      case SortOption.highestPrice:
        sortedProducts.sort((a, b) {
          final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
          final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;
          return priceB.compareTo(priceA);
        });
        break;
      case SortOption.latest:
      case SortOption.oldest:
      case SortOption.popular:
        // For non-price sorting, keep original order (backend should handle)
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
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: _onRefresh,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // Always return a scrollable so pull-to-refresh works on loading/error/empty.
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Sort By Section
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
              onPrimaryAction: () => _loadProducts(
                sortParam: _mapSortToApiSort(_selectedSort),
              ),
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.60,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = products[index];
                  return ListingProductCard(product: product);
                },
                childCount: products.length,
              ),
            ),
          ),
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
              });
              // Re-fetch products from API with the selected sort option
              _loadProducts(sortParam: _mapSortToApiSort(newValue));
            }
          },
        ),
      ),
    );
  }
}
