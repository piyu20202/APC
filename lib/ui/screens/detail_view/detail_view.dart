import 'package:flutter/material.dart';
import '../cart_view/cart.dart';
import 'dart:async';
import '../widget/product_card.dart';
import '../../../main_navigation.dart';

class DetailView extends StatefulWidget {
  const DetailView({super.key});

  @override
  State<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;
  Timer? _imageTimer;

  final List<String> productImages = [
    'assets/images/product.jpg',
    'assets/images/product0.png',
    'assets/images/product1.png',
    'assets/images/product2.png',
    'assets/images/product3.png',
  ];

  // Footer state
  int kitQuantity = 1;
  double totalPrice = 2005.00;

  @override
  void initState() {
    super.initState();
    _startImageAutoSlide();
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _imageController.dispose();
    super.dispose();
  }

  void _startImageAutoSlide() {
    _imageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
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
          'Detail Page',
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
                            Container(
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
                            Container(
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
                              '\$${totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Add to Cart Button
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TabBarWrapper(
                                      showTabBar: true,
                                      child: CartPage(),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
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
                          children: const [
                            Text(
                              'Have Questions?',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Talk to the Experts',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '1800 694 283',
                              style: TextStyle(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images Section
            _buildProductImagesSection(),

            // Product Details
            _buildProductDetails(),

            // Kit Includes
            _buildKitIncludes(),

            // Customise your Kit
            _buildCustomiseYourKit(),

            // Upgrades section
            _buildUpgrades(),

            // Add-On Items section
            _buildAddOnItems(),

            // Product Information section
            _buildProductInformation(),

            // Footer content moved into scrollable area
            _buildScrollableFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImagesSection() {
    return Container(
      height: 300,
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
              itemCount: productImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      productImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Image Indicators
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                productImages.length,
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
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: productImages.length,
              itemBuilder: (context, index) {
                return Container(
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
                    child: Image.asset(productImages[index], fit: BoxFit.cover),
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
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MacBook Pro 16 M4 512 GB Space Black',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Product SKU: APC-790-FMLA-SOL-FGEK',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'In Stock',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              const SizedBox(width: 12),
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
              const Text(
                '\$1,345.00',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '\$1,575.00',
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
              ),
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
              const Text(
                '\$312.25',
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
          const Text(
            'Single Swing Solar Powered Farm Gate Opener Suitable for Square Posts up to 125mm and gates up to 3.5 Metre, 250kg',
            style: TextStyle(fontSize: 14, color: Colors.black, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedProducts() {
    final suggestedProducts = [
      {
        'name': 'Apple MacBook Air 13-inch (M3, 8GB...)',
        'description': 'Latest M3 chip with exceptional performance',
        'currentPrice': '\$1000',
        'originalPrice': '\$1200',
        'image': 'assets/images/product1.png',
        'onSale': true,
      },
      {
        'name': 'Apple MacBook Pro 14-inch (M3 Pro, 1...)',
        'description': 'Professional grade laptop for power users',
        'currentPrice': '\$1815',
        'originalPrice': '\$2000',
        'image': 'assets/images/product2.png',
        'onSale': true,
      },
    ];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggested products',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 320,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: suggestedProducts.length,
              itemBuilder: (context, index) {
                final product = suggestedProducts[index];
                return ProductCard(
                  product: product,
                  width: 160,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableFooter() {
    int kitQuantity = 1;
    double totalPrice = 2005.00;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: Column(
        children: [
          // Kit Summary Section
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

                // Kit Items
                Row(
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
                    const Expanded(
                      child: Text(
                        'Upgraded to 24v 40 Watts Solar Panel With Solar Panel Post & Bracket',
                        style: TextStyle(fontSize: 13, color: Colors.green),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
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
                    const Expanded(
                      child: Text(
                        'Add On 1x Universal Galvanized Farm Gate Bracket ( Suitable with',
                        style: TextStyle(fontSize: 13, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom padding for scroll
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildKitIncludes() {
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
                'Kit Includes',
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
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKitItem(
                '01',
                'APC-T700TL Top Limit Actuator Kit',
                'QTY: 1',
              ),
              _buildKitItem(
                '02',
                'APC Weatherproof Control Box with Built in Battery Compartment',
                'QTY: 1',
              ),
              _buildKitItem('03', 'APC Four Button Keyring Remote', 'QTY: 2'),
              _buildKitItem('04', '9aH High Capacity Battery', 'QTY: 2'),
              _buildKitItem('05', '24v 20 Watts Solar Panel', 'QTY: 1'),
              _buildKitItem(
                '06',
                'Solar Panel Fence Post & Bracket for APC 20 Watt Solar Panels',
                'QTY: 1',
              ),
              _buildKitItem(
                '07',
                'APC Four Button Long Distance Remote',
                'QTY: 1',
              ),
              _buildKitItem(
                '08',
                '433MHZ Booster Antenna for Gate Automation Remotes, Garage Doors, Access Controls With 6.5 dBi Gain, Supplied With Bracket and Pre-Connected 5m cable',
                'QTY: 1',
              ),
              _buildKitItem(
                '09',
                'APC Retro Reflective Safety Sensor - for gate opening system safety Retro Reflective Gate Sensor',
                'QTY: 1',
              ),
              _buildKitItem(
                '10',
                'Two FREE Sunvisor Remote Controls (Promotion) with every Electric Gate Automation Kit order.',
                'QTY: 2',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKitItem(String number, String description, String quantity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 14, color: Color(0xFF151D51)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($quantity)',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF151D51),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomiseYourKit() {
    final List<Map<String, dynamic>> customiseProducts = [
      {
        'name': 'APC Four Button Keyring Remote',
        'code': 'APC-RC4s',
        'description':
            'Compact and Light key ring remote with easy to use buttons',
        'image': 'assets/images/product1.png',
        'quantity': 2,
      },
      {
        'name': 'APC Four Button Long Distance Remote',
        'code': 'APC-RC450s',
        'description': 'Long distance remote with extended range capability',
        'image': 'assets/images/product2.png',
        'quantity': 1,
      },
      {
        'name': 'Two FREE Sunvisor Remote Controls (Promotion)',
        'code': 'APC-RC4-SV-GR-Free',
        'description':
            'Two FREE Sunvisor Remote Controls (Promotion) for APC Electric Gate Motors',
        'image': 'assets/images/product3.png',
        'quantity': 2,
      },
    ];

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
                'Customise your Kit',
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
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: customiseProducts.length,
            itemBuilder: (context, index) {
              final product = customiseProducts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        (product['image'] as String?) ??
                            'assets/images/product1.png',
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (product['name'] as String?) ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF151D51),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (product['code'] as String?) ?? '',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.blue[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (product['description'] as String?) ?? '',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Quantity (compact, fixed width)
                    SizedBox(
                      width: 72,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Qty',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF151D51),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: (product['quantity'] as int?) ?? 1,
                                isDense: true,
                                isExpanded: true,
                                iconSize: 16,
                                selectedItemBuilder: (context) {
                                  return List.generate(10, (i) {
                                    final qty = i + 1;
                                    return Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '$qty',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 9),
                                      ),
                                    );
                                  });
                                },
                                items: List.generate(10, (i) {
                                  final qty = i + 1;
                                  final int price = qty > 2
                                      ? (qty - 2) * 40
                                      : 0;
                                  return DropdownMenuItem<int>(
                                    value: qty,
                                    child: Text(
                                      '$qty (+\$$price.00)',
                                      style: const TextStyle(fontSize: 9),
                                    ),
                                  );
                                }),
                                onChanged: (val) {},
                              ),
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

  int _selectedUpgradeIndex = -1; // -1 means no selection

  Widget _buildUpgrades() {
    final List<Map<String, dynamic>> upgradeItems = [
      {
        'name': 'Solar Panel Upgrade to 40W',
        'code': 'APC-SP40W',
        'description': 'Upgrade your solar panel to 40W for better performance',
        'price': '+\$150.00',
        'image': 'assets/images/product1.png',
      },
      {
        'name': 'Premium Remote Control Set',
        'code': 'APC-PRC-SET',
        'description':
            'Premium remote controls with extended range and features',
        'price': '+\$80.00',
        'image': 'assets/images/product2.png',
      },
      {
        'name': 'Advanced Safety Sensor Package',
        'code': 'APC-ASS-PKG',
        'description': 'Enhanced safety sensors for maximum protection',
        'price': '+\$120.00',
        'image': 'assets/images/product3.png',
      },
    ];

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
                'Upgrades are available for following items',
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
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: upgradeItems.length,
            itemBuilder: (context, index) {
              final item = upgradeItems[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: _selectedUpgradeIndex == index
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Radio Button
                      Radio<int>(
                        value: index,
                        groupValue: _selectedUpgradeIndex,
                        onChanged: (value) {
                          setState(() {
                            _selectedUpgradeIndex = value!;
                          });
                        },
                        activeColor: Colors.blue,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                      // Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          (item['image'] as String?) ??
                              'assets/images/product1.png',
                          width: 45,
                          height: 45,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 45,
                              height: 45,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image,
                                color: Colors.grey[500],
                                size: 18,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Details - takes most space
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              (item['name'] as String?) ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF151D51),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (item['code'] as String?) ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (item['description'] as String?) ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Price and Quantity - compact, keep price single line
                      SizedBox(
                        width: 78,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              (item['price'] as String?) ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Qty: 2',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF151D51),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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

  final List<bool> _addOnSelections = [true, true]; // Track checkbox states
  final List<int> _addOnQuantities = [1, 1]; // Track quantities

  Widget _buildAddOnItems() {
    final List<Map<String, dynamic>> addOnItems = [
      {
        'name':
            'Universal Galvanized Farm Gate Bracket (Suitable with MONOS4, 700,750,790, 800,850,890 Motors)',
        'code': 'APC-FGB2532-GB',
        'description': 'Suitable for 25mm to 32mm round gate tube',
        'image': 'assets/images/product1.png',
        'unitPrice': 49.00,
        'originalPrice': null,
        'savings': null,
      },
      {
        'name':
            'Universal Automatic Gate Safety Light and Antenna KIT (Including Cables)',
        'code': 'APC-ULA-KIT',
        'description':
            'Universal 12-265V AC/DC LED with Antenna **All cables included**',
        'image': 'assets/images/product2.png',
        'unitPrice': 69.00,
        'originalPrice': 85.00,
        'savings': 16.00,
      },
    ];

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
                'Add-On Items (Discounted when purchased along with this Kit)',
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
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: addOnItems.length,
            itemBuilder: (context, index) {
              final item = addOnItems[index];
              final isSelected = _addOnSelections[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: Colors.blue, width: 1)
                      : Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Checkbox - compact
                      Transform.scale(
                        scale: 0.9,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              _addOnSelections[index] = value ?? false;
                            });
                          },
                          activeColor: Colors.blue,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Image - smaller
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          (item['image'] as String?) ??
                              'assets/images/product1.png',
                          width: 45,
                          height: 45,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 45,
                              height: 45,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image,
                                color: Colors.grey[500],
                                size: 18,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Details - optimized
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              (item['name'] as String?) ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF151D51),
                                height: 1.2,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (item['code'] as String?) ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (item['description'] as String?) ?? '',
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
                      // Right side - compact layout, fixed width to avoid wrapping
                      SizedBox(
                        width: 96,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Quantity dropdown - smaller
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _addOnQuantities[index],
                                  isDense: true,
                                  items: List.generate(10, (i) {
                                    final qty = i + 1;
                                    return DropdownMenuItem<int>(
                                      value: qty,
                                      child: Text(
                                        '$qty',
                                        style: const TextStyle(fontSize: 11),
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
                            const SizedBox(height: 6),
                            // Unit Price - compact
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
                              "\$${(item['unitPrice'] as double).toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            // Pricing info - compact
                            if (item['originalPrice'] != null) ...[
                              const SizedBox(height: 1),
                              Text(
                                "\$${(item['originalPrice'] as double).toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 9,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                "Save \$${(item['savings'] as double).toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            // View Details - smaller
                            GestureDetector(
                              onTap: () {
                                // Handle view details
                              },
                              child: const Text(
                                'View Details ≫',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
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

  Widget _buildProductInformation() {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Expanded(
                flex: 1,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/product.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Product Information Text
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Heavy Duty 24V Motor with powerful and quiet operation Sleek European design with a compact and neat appearance Easy to use manual override via the supplied keys in a emergency situation. The system can handle light and heavy gates up to 250kg maximum weight or up to 3.5m maximum length.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF151D51),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Easy to Adjust Top Limit Switches ensure precise setting of the open and closed positions along with a less strenuous life for the actuator.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF151D51),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Note: This will be replaced with HTML content later
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.yellow[300]!),
                      ),
                      child: const Text(
                        'Note: This section will display HTML content in the future implementation.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.grey[600],
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.blue : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
