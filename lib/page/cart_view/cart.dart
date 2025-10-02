import 'package:flutter/material.dart';
import '../widget/cart_item_card.dart';
import '../drawer_view/drawer.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartItems = [
    {
      'id': 1,
      'type': 'kit',
      'name': 'Wi-Fi Gate Automation APP Control Kit wi...',
      'sku': 'APC-PT-5000-DC-S24-WF',
      'image': 'assets/images/1.png',
      'price': 1525.00,
      'originalPrice': null,
      'quantity': 3,
      'inStock': true,
      'kitItems': [
        {'num': '01', 'name': 'APC Proteous 5000 Italian Made Super Duty...', 'qty': 1},
        {'num': '02', 'name': 'APC Simply 24V Universal Control Box', 'qty': 1},
        {'num': '03', 'name': 'Standard AC/DC Powered with 2m Cable for...', 'qty': 1},
        {'num': '04', 'name': 'APC Four Button Keyring Remote', 'qty': 2},
        {'num': '05', 'name': 'APC Link 2 WiFi Switch - DUAL Relay WiFi...', 'qty': 1},
        {'num': '06', 'name': 'APC Retro Reflective Safety Sensor - fo...', 'qty': 1},
        {'num': '07', 'name': 'Two FREE Sunvisor Remote Controls (Promo...', 'qty': 2},
      ],
    },
    {
      'id': 2,
      'type': 'single',
      'name': 'Apple Sony PlayStation 5 Pro, 2TB Standard White',
      'sku': 'APC-PS5PRO-2TB',
      'image': 'assets/images/2.png',
      'price': 420.00,
      'originalPrice': 600.00,
      'quantity': 1,
      'inStock': true,
    },
  ];

  double deliveryCost = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        title: const Text(
          'Cart',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: null,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: cartItems.isEmpty ? _buildEmptyCart() : _buildCartWithItems(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Looks like you haven\'t added anything yet.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to catalog/home
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF151D51),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Go to catalog',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartWithItems() {
    double subtotal = cartItems.fold(0.0, (sum, item) => sum + ((item['price'] as num?)?.toDouble() ?? 0.0) * ((item['quantity'] as int?) ?? 1));
    double total = subtotal + deliveryCost;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cart Items
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return CartItemCard(
                      item: item,
                      index: index,
                      onQuantityDecrease: () {
                        if (item['quantity'] > 1) {
                          setState(() {
                            cartItems[index]['quantity']--;
                          });
                        }
                      },
                      onQuantityIncrease: () {
                        setState(() {
                          cartItems[index]['quantity']++;
                        });
                      },
                      onDelete: () {
                        setState(() {
                          cartItems.removeAt(index);
                        });
                      },
                    );
                  },
                ),
                
                
               
                
              ],
            ),
          ),
        ),

         // Order Summary
          _buildOrderSummary(subtotal, total),
          const SizedBox(height: 20),
        
        // Checkout Button
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to checkout page
                  Navigator.pushNamed(context, '/checkout');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF151D51),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildOrderSummary(double subtotal, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total cost (GST Incl)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Main', false),
          _buildNavItem(Icons.search, 'Search', false),
          _buildNavItem(Icons.shopping_cart, 'Cart', true),
          _buildNavItem(Icons.favorite, 'Favourites', false),
          _buildNavItem(Icons.person, 'Profile', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isSelected ? const Color(0xFF151D51) : Colors.grey[600],
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? const Color(0xFF151D51) : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
