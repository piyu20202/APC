import 'package:flutter/material.dart';
import '../widget/wishlist_product_card.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final List<Map<String, dynamic>> wishlistProducts = [
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
      'name': 'Gas Automation Kit',
      'description': 'Complete gas automation solution for gates',
      'currentPrice': '\$89',
      'originalPrice': '\$120',
      'image': 'assets/images/product1.png',
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
      'name': 'Telescopic Linear Actuator - Heavy Duty',
      'sku': 'APC-TLA-HD',
      'description': 'Heavy duty linear actuator for industrial applications',
      'currentPrice': '\$13',
      'originalPrice': '\$42',
      'image': 'assets/images/1.png',
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
      'name': 'Farm Gate Opener Kit',
      'sku': 'APC-FGO-001',
      'description': 'Complete farm gate automation solution',
      'currentPrice': '\$59',
      'originalPrice': '\$79',
      'image': 'assets/images/3.png',
      'onSale': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Wishlist',
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
      body: wishlistProducts.isEmpty
          ? _buildEmptyWishlist()
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.45,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: wishlistProducts.length,
              itemBuilder: (context, index) {
                final product = wishlistProducts[index];
                return WishlistProductCard(product: product);
              },
            ),
    );
  }

  Widget _buildEmptyWishlist() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Your Wishlist is Empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products to your wishlist to save them for later',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate back to home or product list
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF151D51),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }
}
