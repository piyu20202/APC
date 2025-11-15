import 'package:flutter/material.dart';
import '../widget/product_card.dart';
import '../../../data/services/homepage_service.dart';
import '../../../core/utils/logger.dart';

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

class _ProductListScreenState extends State<ProductListScreen> {
  final HomepageService _homepageService = HomepageService();
  List<Map<String, dynamic>> products = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Dummy products for fallback
  final List<Map<String, dynamic>> _dummyProducts = [
    {
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

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
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
        );

        products = apiProducts.map((p) {
          return {
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

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Failed to load products', e);
      // Fallback to dummy products on error
      products = List.from(_dummyProducts);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load products. Showing sample products.';
      });
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (products.isEmpty) {
      return const Center(
        child: Text(
          'No products available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.45,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(product: product);
      },
    );
  }
}
