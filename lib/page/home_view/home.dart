import 'package:flutter/material.dart';
import '../categories_view/categories_grid.dart';
import '../drawer_view/drawer.dart';
import '../detail_view/detail_view.dart';
import '../widget/product_card.dart';
import '../cart_view/cart.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBannerIndex = 0;
  late Timer _bannerTimer;
  final PageController _bannerController = PageController();
  // Mid banner state
  int _currentMidBannerIndex = 0;
  late Timer _midBannerTimer;
  final PageController _midBannerController = PageController();
  String? _selectedDrawerItem;
  
  // Auto-scroll for Latest Products
  int _currentProductIndex = 0;
  late Timer _productTimer;
  final PageController _productController = PageController();

  final List<Map<String, dynamic>> banners = [
    {
      'image': 'assets/images/banner1.jpg',
      'backgroundColor': const Color(0xFFE91E63),
    },
    {
      'image': 'assets/images/banner2.jpg',
      'backgroundColor': const Color(0xFFF44336),
    },
    {
      'image': 'assets/images/banner3.jpg',
      'backgroundColor': const Color(0xFF2196F3),
    },
  ];

  final List<Map<String, dynamic>> products = [
    {
      'image': 'assets/images/1.png',
      'name': 'Telescopic Linear Actuator - Heavy Duty',
      'sku': 'APC-TLA-HD',
      'description': 'Heavy duty linear actuator for industrial applications',
      'currentPrice': '\$13',
      'originalPrice': '\$42',
      'onSale': true,
    },
    {
      'image': 'assets/images/2.png',
      'name': 'Robust Cast Alloy Casing Kit',
      'sku': 'APC-RCAK-001',
      'description': 'Durable cast alloy casing for long-lasting performance',
      'currentPrice': '\$74',
      'originalPrice': '\$99',
      'onSale': true,
    },
    {
      'image': 'assets/images/3.png',
      'name': 'Farm Gate Opener Kit',
      'sku': 'APC-FGO-001',
      'description': 'Complete farm gate automation solution',
      'currentPrice': '\$59',
      'originalPrice': '\$79',
      'onSale': true,
    },
  ];

  final List<Map<String, dynamic>> featuredProducts = [
    {
      'image': 'assets/images/product1.png',
      'name': 'Gas Automation Kit',
      'description': 'Complete gas automation solution for gates',
      'currentPrice': '\$89',
      'originalPrice': '\$120',
      'onSale': true,
    },
    {
      'image': 'assets/images/product2.png',
      'name': 'Gate & Fencing Hardware',
      'description': 'Professional grade gate and fencing hardware',
      'currentPrice': '\$45',
      'originalPrice': '\$65',
      'onSale': true,
    },
    {
      'image': 'assets/images/product3.png',
      'name': 'Brushless Electric Gate Kit',
      'description': 'High-performance brushless electric gate system',
      'currentPrice': '\$199',
      'originalPrice': '\$250',
      'onSale': true,
    },
    {
      'image': 'assets/images/product4.png',
      'name': 'Custom Made Gate',
      'description': 'Custom designed gate solutions',
      'currentPrice': '\$299',
      'originalPrice': '\$350',
      'onSale': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
    _startProductTimer();
    _startMidBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerController.hasClients) {
        final next = (_currentBannerIndex + 1) % banners.length;
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        setState(() => _currentBannerIndex = next);
      }
    });
  }

  void _startProductTimer() {
    _productTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_productController.hasClients && products.isNotEmpty) {
        final next = (_currentProductIndex + 1) % products.length;
        _productController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() => _currentProductIndex = next);
      }
    });
  }

  void _startMidBannerTimer() {
    _midBannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_midBannerController.hasClients) {
        final next = (_currentMidBannerIndex + 1) % banners.length;
        _midBannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        setState(() => _currentMidBannerIndex = next);
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer.cancel();
    _bannerController.dispose();
    _productTimer.cancel();
    _productController.dispose();
    _midBannerTimer.cancel();
    _midBannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        title: const Text(
          'Home',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              
              // Search and Cart Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Search Bar
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Icon(Icons.search, color: Colors.grey[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Search products...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Cart Icon
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CartPage()),
                        );
                      },
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(Icons.shopping_cart, color: Colors.grey[600], size: 20),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                '13',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Banner Section
              _buildBannerSection(),

              const SizedBox(height: 20),

              // Categories Section
              _buildCategoriesSection(),

              const SizedBox(height: 20),

              // Latest Products Section
              _buildLatestProductsSection(),

               const SizedBox(height: 20),

              // Banner below Latest Products
              _buildMidBanner(),

              const SizedBox(height: 20),

              // Featured Products Section
              _buildFeaturedProductsSection(),

              const SizedBox(height: 20),

              // Recent Products Section
              _buildRecentProductsSection(),

              const SizedBox(height: 20),

              // Collections Section
              _buildCollectionsSection(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Stack(
        children: [
          PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Background Image - Full Size
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          banner['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    banner['backgroundColor'],
                                    banner['backgroundColor'].withOpacity(0.8),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.image,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 60,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // Overlay for better text readability
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Banner Indicators
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentBannerIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
      {'name': 'Sale', 'icon': 'assets/images/product0.png', 'color': const Color(0xFF002e5b), 'isImage': true},
      {'name': 'Gas Automation Kits', 'icon': 'assets/images/product1.png', 'color': const Color(0xFF002e5b), 'isImage': true},
      {'name': 'Gate & Fencing Hardware', 'icon': 'assets/images/product2.png', 'color': const Color(0xFF002e5b), 'isImage': true},
      {'name': 'Brushless Electric Gate Kits', 'icon': 'assets/images/product3.png', 'color': const Color(0xFF002e5b), 'isImage': true},
      {'name': 'Custom Made Gates', 'icon': 'assets/images/product8.png', 'color': const Color(0xFF002e5b), 'isImage': true},
      {'name': 'See all categories', 'icon': Icons.add, 'color': const Color(0xFF002e5b), 'isImage': false, 'isDarkCard': true, 'plainIcon': true},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF151D51),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return GestureDetector(
                onTap: () {
                  if (category['name'] == 'See all categories') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CategoriesGridScreen()),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(category['isImage'] == true ? 8 : 12),
                        decoration: category['isImage'] == true
                            ? BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              )
                            : (category['plainIcon'] == true
                                ? BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  )
                                : BoxDecoration(
                                    color: (category['color'] as Color).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  )),
                        child: category['isImage'] == true
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  category['icon'] as String,
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.image,
                                      color: Colors.white,
                                      size: 24,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                category['icon'] as IconData,
                                color: category['plainIcon'] == true ? Colors.black : category['color'] as Color,
                                size: category['plainIcon'] == true ? 28 : 24,
                              ),
                      ),
                      const SizedBox(height: 0),
                      Text(
                        category['name'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: category['isImage'] == true ? 13 : 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF151D51),
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

  Widget _buildLatestProductsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Latest Product',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151D51),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 330,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMidBanner() {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PageView.builder(
              controller: _midBannerController,
              onPageChanged: (index) {
                setState(() {
                  _currentMidBannerIndex = index;
                });
              },
              itemCount: banners.length,
              itemBuilder: (context, index) {
                final banner = banners[index];
                return Image.asset(
                  banner['image'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.blue[50],
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.image, color: Colors.blueGrey, size: 20),
                            SizedBox(width: 8),
                            Text('Promotional Banner', style: TextStyle(color: Colors.blueGrey)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Indicators (small, subtle)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (index) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentMidBannerIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProductsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Featured Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151D51),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 340,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: featuredProducts.length,
               itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                );
              },
            ),
          ),
        ],
      ),
    );
  }



   Widget _buildRecentProductsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151D51),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 340,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: featuredProducts.length,
               itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionsSection() {
    final collections = [
      {'image': 'assets/images/product0.png'},
      {'image': 'assets/images/product1.png'},
      {'image': 'assets/images/product2.png'},
      {'image': 'assets/images/product3.png'},
      {'image': 'assets/images/logo.png'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Brands',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151D51),
                ),
              ),
              const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: collections.length,
              itemBuilder: (context, index) {
                final collection = collections[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.white,
                      child: Center(
                        child: Image.asset(
                          collection['image'] as String,
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image,
                              color: Colors.grey[300],
                              size: 40,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}