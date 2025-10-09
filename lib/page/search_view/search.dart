import 'package:flutter/material.dart';
import '../productlist_view/productlist.dart';
import '../widget/product_card.dart';
import '../../main_navigation.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  // Sample products for search
  final List<Map<String, dynamic>> _allProducts = [
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
      'name': 'Gas Automation Kit',
      'description': 'Complete gas automation solution for gates',
      'currentPrice': '\$89',
      'originalPrice': '\$120',
      'image': 'assets/images/product1.png',
      'onSale': true,
    },
    {
      'name': 'Gate & Fencing Hardware',
      'description': 'Professional grade gate and fencing hardware',
      'currentPrice': '\$45',
      'originalPrice': '\$65',
      'image': 'assets/images/product2.png',
      'onSale': true,
    },
    {
      'name': 'Brushless Electric Gate Kit',
      'description': 'High-performance brushless electric gate system',
      'currentPrice': '\$199',
      'originalPrice': '\$250',
      'image': 'assets/images/product3.png',
      'onSale': true,
    },
    {
      'name': 'Custom Made Gate',
      'description': 'Custom designed gate solutions',
      'currentPrice': '\$299',
      'originalPrice': '\$350',
      'image': 'assets/images/product4.png',
      'onSale': true,
    },
    {
      'name': 'Telescopic Linear Actuator - Heavy Duty',
      'sku': 'APC-TLA-HD',
      'description': 'Heavy duty linear actuator for industrial applications',
      'currentPrice': '\$13',
      'originalPrice': '\$42',
      'image': 'assets/images/1.png',
      'onSale': true,
    },
    {
      'name': 'Farm Gate Opener Kit',
      'sku': 'APC-FGO-001',
      'description': 'Complete farm gate automation solution',
      'currentPrice': '\$59',
      'originalPrice': '\$79',
      'image': 'assets/images/3.png',
      'onSale': true,
    },
  ];

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = _allProducts.where((product) {
        final name = product['name']?.toString().toLowerCase() ?? '';
        final description =
            product['description']?.toString().toLowerCase() ?? '';
        final sku = product['sku']?.toString().toLowerCase() ?? '';
        final category = product['category']?.toString().toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();

        return name.contains(searchQuery) ||
            description.contains(searchQuery) ||
            sku.contains(searchQuery) ||
            category.contains(searchQuery);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Search Products',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFF2F0EF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products, SKU, or categories...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF151D51)),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _performSearch,
              onSubmitted: _performSearch,
            ),
          ),

          // Search Results or Empty State
          Expanded(child: _buildSearchContent()),
        ],
      ),
    );
  }

  Widget _buildSearchContent() {
    if (!_isSearching && _searchController.text.isEmpty) {
      return _buildEmptyState();
    }

    if (_isSearching && _searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    return _buildSearchResults();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Search Products',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter keywords to find products, SKUs, or categories',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TabBarWrapper(
                    showTabBar: true,
                    child: ProductListScreen(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF151D51),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Browse All Products'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or browse all products',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Found ${_searchResults.length} result${_searchResults.length != 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF151D51),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.45,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return ProductCard(product: product);
            },
          ),
        ),
      ],
    );
  }
}
