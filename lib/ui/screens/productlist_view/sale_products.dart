import 'package:flutter/material.dart';
import '../../../data/repositories/homepage_repository.dart';
import '../../../data/models/homepage_model.dart';
import '../../screens/widget/sale_product_listing_card.dart';
import '../../../core/utils/logger.dart';

enum SortOption { popular, lowestPrice, highestPrice, latest, oldest }

class SaleProductsScreen extends StatefulWidget {
  const SaleProductsScreen({super.key});

  @override
  State<SaleProductsScreen> createState() => _SaleProductsScreenState();
}

class _SaleProductsScreenState extends State<SaleProductsScreen> {
  final HomepageRepository _repository = HomepageRepository();
  bool _isLoading = true;
  String? _error;
  List<LatestProduct> _products = [];
  List<LatestProduct> _originalProducts = [];
  SortOption _selectedSort = SortOption.popular;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      Logger.info('Loading sale products...');
      final items = await _repository.getSaleProducts();
      setState(() {
        _products = items;
        _originalProducts = List.from(items);
        _isLoading = false;
      });
      _applySorting();
    } catch (e) {
      Logger.error('Failed to load sale products', e);
      setState(() {
        _error = 'Failed to load sale products. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _applySorting() {
    final sortedProducts = List<LatestProduct>.from(_originalProducts);

    switch (_selectedSort) {
      case SortOption.lowestPrice:
        sortedProducts.sort((a, b) {
          final priceA = a.price;
          final priceB = b.price;
          return priceA.compareTo(priceB);
        });
        break;
      case SortOption.highestPrice:
        sortedProducts.sort((a, b) {
          final priceA = a.price;
          final priceB = b.price;
          return priceB.compareTo(priceA);
        });
        break;
      case SortOption.latest:
        sortedProducts.sort((a, b) {
          return b.id.compareTo(a.id); // Higher ID = newer (assuming)
        });
        break;
      case SortOption.oldest:
        sortedProducts.sort((a, b) {
          return a.id.compareTo(b.id); // Lower ID = older (assuming)
        });
        break;
      case SortOption.popular:
        // Keep original order for popular
        break;
    }

    setState(() {
      _products = sortedProducts;
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
        title: const Text(
          'Sale Products',
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text(
          'No sale products available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Sort By Section
        Container(
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
        // Products Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.49,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final p = _products[index];
              final mapped = {
                'id': p.id,
                'image': p.thumbnail,
                'thumbnail': p.thumbnail,
                'name': p.name,
                'sku': p.sku,
                'price': p.price,
                'previous_price': p.previousPrice,
                'currentPrice': p.price.toString(),
                'originalPrice': p.previousPrice.toString(),
                // Use dynamic short_description from API, with fallback
                'description': p.shortDescription ?? 'On sale — limited time offer.',
                'onSale': true,
                'out_of_stock': p.outOfStock,
              };
              return SaleProductListingCard(product: mapped);
            },
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
              _applySorting();
            }
          },
        ),
      ),
    );
  }
}
