import 'package:flutter/material.dart';
import '../../../data/repositories/homepage_repository.dart';
import '../../../data/models/homepage_model.dart';
import '../../screens/widget/product_card.dart';
import '../../../core/utils/logger.dart';

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
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Failed to load sale products', e);
      setState(() {
        _error = 'Failed to load sale products. Please try again.';
        _isLoading = false;
      });
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

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.45,
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
          // Use dynamic short_description from API, with fallback
          'description': p.shortDescription ?? 'On sale — limited time offer.',
          'onSale': true,
        };
        return ProductCard(product: mapped);
      },
    );
  }
}
