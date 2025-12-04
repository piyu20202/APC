import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../categories_view/subcategory_page.dart';
import '../drawer_view/drawer.dart';
import '../widget/product_card.dart';
import '../productlist_view/sale_products.dart';
import '../productlist_view/productlist.dart';
import '../signup_view/trader_upgrade_flow.dart';
import '../../../services/user_role_service.dart';
import '../../../services/storage_service.dart';
// import '../../../data/services/settings_service.dart'; // Not using API call for now
import '../../../data/models/settings_model.dart';
import '../../../data/models/homepage_model.dart';
import '../../../data/models/categories_model.dart';
import '../../../data/services/homepage_service.dart';
import '../../../providers/homepage_provider.dart';
import '../../../core/services/categories_cache_service.dart';
import '../../../core/utils/logger.dart';
import '../../../services/navigation_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;
  final int cartCount;

  const HomeScreen({super.key, this.onSearchTap, this.cartCount = 0});

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

  // Auto-scroll for Latest Products
  int _currentProductIndex = 0;
  late Timer _productTimer;
  final PageController _productController = PageController();

  // Trader status
  bool _isTrader = false;

  // Settings data
  SettingsModel? _settings;
  // final SettingsService _settingsService = SettingsService(); // Commented out - only using cached settings

  // Homepage data moved to HomepageProvider
  final HomepageService _homepageService = HomepageService();

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
      'id': 1001,
      'image': 'assets/images/1.png',
      'name': 'Telescopic Linear Actuator - Heavy Duty',
      'sku': 'APC-TLA-HD',
      'description': 'Heavy duty linear actuator for industrial applications',
      'currentPrice': '\$13',
      'originalPrice': '\$42',
      'onSale': true,
    },
    {
      'id': 1002,
      'image': 'assets/images/2.png',
      'name': 'Robust Cast Alloy Casing Kit',
      'sku': 'APC-RCAK-001',
      'description': 'Durable cast alloy casing for long-lasting performance',
      'currentPrice': '\$74',
      'originalPrice': '\$99',
      'onSale': true,
    },
    {
      'id': 1003,
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
      'id': 2001,
      'image': 'assets/images/product1.png',
      'name': 'Gas Automation Kit',
      'description': 'Complete gas automation solution for gates',
      'currentPrice': '\$89',
      'originalPrice': '\$120',
      'onSale': true,
    },
    {
      'id': 2002,
      'image': 'assets/images/product2.png',
      'name': 'Gate & Fencing Hardware',
      'description': 'Professional grade gate and fencing hardware',
      'currentPrice': '\$45',
      'originalPrice': '\$65',
      'onSale': true,
    },
    {
      'id': 2003,
      'image': 'assets/images/product3.png',
      'name': 'Brushless Electric Gate Kit',
      'description': 'High-performance brushless electric gate system',
      'currentPrice': '\$199',
      'originalPrice': '\$250',
      'onSale': true,
    },
    {
      'id': 2004,
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
    debugPrint('HomeScreen initState called');
    _startBannerTimer();
    _startProductTimer();
    _startMidBannerTimer();
    _checkTraderStatus();
    _fetchSettings();
    // Load homepage data via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProvider = Provider.of<HomepageProvider>(
        context,
        listen: false,
      );
      homeProvider.loadHomepageData().catchError((error) {
        debugPrint('CATCH ERROR loadHomepageData: $error');
        Logger.error('Error in loadHomepageData', error);
      });
      homeProvider.loadLatestProducts().catchError((error) {
        debugPrint('CATCH ERROR loadLatestProducts: $error');
        Logger.error('Error in loadLatestProducts', error);
      });
      homeProvider.loadSaleProducts().catchError((error) {
        debugPrint('CATCH ERROR loadSaleProducts: $error');
        Logger.error('Error in loadSaleProducts', error);
      });
    });
  }

  /// Fetch settings from API and save to SharedPreferences
  Future<void> _fetchSettings() async {
    try {
      // Check if settings already exist in local storage
      final cachedSettings = await StorageService.getSettings();
      if (cachedSettings != null) {
        setState(() {
          _settings = cachedSettings;
        });
      }

      // Skip fetching settings from API for now - only focus on homepage categories
      Logger.info('Settings loading skipped - using cached settings only');
    } catch (e) {
      Logger.error('Failed to load settings', e);
      // Don't show error toast for settings
    }
  }

  // Data fetching moved to HomepageProvider

  Future<void> _checkTraderStatus() async {
    final isTrader = await UserRoleService.isTraderUser();
    setState(() {
      _isTrader = isTrader;
    });
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

  /// Get settings data (for use in the app)
  SettingsModel? get settings => _settings;

  @override
  Widget build(BuildContext context) {
    final cartCount = widget.cartCount;
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
          overflow: TextOverflow.visible,
        ),
        titleSpacing: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Phone Call Button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () async {
              final phoneNumber =
                  _settings?.generalSettings.headerPhone.isNotEmpty == true
                  ? _settings!.generalSettings.headerPhone
                  : _settings?.pageSettings.phone.isNotEmpty == true
                  ? _settings!.pageSettings.phone
                  : null;

              if (phoneNumber != null) {
                final uri = Uri.parse('tel:$phoneNumber');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to make phone call'),
                      ),
                    );
                  }
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone number not available')),
                  );
                }
              }
            },
            icon: const Icon(Icons.phone, color: Colors.black, size: 22),
            tooltip: 'Call Us',
          ),
          // Trader upgrade button (only for non-traders)
          if (!_isTrader)
            Padding(
              padding: const EdgeInsets.only(right: 8, left: 4),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TraderUpgradeFlow(isExistingUser: true),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.business,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Become Trade User',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
        ],
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
                      child: GestureDetector(
                        onTap: () {
                          NavigationService.instance.switchToTab(1);
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Icon(
                                Icons.search,
                                color: Colors.grey[600],
                                size: 20,
                              ),
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
                    ),

                    const SizedBox(width: 12),

                    // Cart Icon
                    GestureDetector(
                      onTap: () {
                        NavigationService.instance.switchToTab(3);
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.shopping_cart,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ),
                          if (cartCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$cartCount',
                                  style: const TextStyle(
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

              // Sale Products Section
              _buildSaleProductsSection(),

              const SizedBox(height: 20),

              // Services Section
              _buildServicesSection(),

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
    final homeProvider = Provider.of<HomepageProvider>(context);
    final _isLoadingHomepage = homeProvider.isLoading;
    final _homepageData = homeProvider.homepageData;

    Logger.info(
      'Building categories section - isLoading: $_isLoadingHomepage, hasData: ${_homepageData != null}, categoriesCount: ${_homepageData?.categories.length ?? 0}',
    );

    if (_isLoadingHomepage) {
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
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(
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
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ],
        ),
      );
    }

    final categories = _homepageData?.categories ?? [];

    // Debug log
    if (categories.isEmpty) {
      Logger.info(
        'No categories received from API - _homepageData is null: ${_homepageData == null}',
      );
      if (_homepageData != null) {
        Logger.info('Homepage data exists but categories array is empty');
        final keys = _homepageData.toJson().keys.join(", ");
        Logger.info('Available keys: $keys');
      }
    } else {
      Logger.info('Received ${categories.length} categories from API');
      categories.asMap().forEach((index, cat) {
        if (index < 3) {
          Logger.info(
            'Category $index: name="${cat.name}", image="${cat.image}"',
          );
        }
      });
    }

    // Show all categories - NO "See All" button, NO limit
    if (categories.isEmpty) {
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
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No categories available',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }

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
            itemCount: categories.length, // ALL categories - no limit
            itemBuilder: (context, index) {
              // All category items from API - no "See All" button
              final category = categories[index];

              // Debug: Log category data
              if (index == 0) {
                Logger.info(
                  'First category: name=${category.name}, id=${category.id}, image=${category.image}',
                );
              }

              return GestureDetector(
                onTap: () {
                  final name = (category.name).toLowerCase();
                  if (name == 'sale') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SaleProductsScreen(),
                      ),
                    );
                  } else {
                    _navigateToCategory(category);
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Expanded image section to fill most of the card
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child:
                              category.image != null &&
                                  category.image!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: category.image!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: double.infinity,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        width: double.infinity,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                          size: 32,
                                        ),
                                      ),
                                )
                              : Container(
                                  width: double.infinity,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.category,
                                    color: Colors.grey,
                                    size: 32,
                                  ),
                                ),
                        ),
                      ),
                      // Category name at the bottom
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Text(
                          category.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF151D51),
                          ),
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
    // Use API latest products if available, otherwise fall back to mock data
    final homeProvider = Provider.of<HomepageProvider>(context);
    final displayProducts = homeProvider.latestProducts.isNotEmpty
        ? homeProvider.latestProducts
        : null;

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
            height: 310,
            child: homeProvider.isLoadingLatestProducts
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: displayProducts?.length ?? products.length,
                    itemBuilder: (context, index) {
                      if (displayProducts != null) {
                        final apiProduct = displayProducts[index];
                        // Map API product to ProductCard expected map shape
                        final mapped = {
                          'id': apiProduct.id,
                          'image': apiProduct.thumbnail, // may be null
                          'name': apiProduct.name,
                          'sku': apiProduct.sku,
                          // Use dynamic short_description from API, with fallback
                          'description':
                              apiProduct.shortDescription ??
                              'Latest product — description coming soon.',
                          'price': apiProduct.price,
                          'previous_price': apiProduct.previousPrice,
                          'thumbnail': apiProduct.thumbnail,
                        };
                        return ProductCard(
                          product: mapped,
                          width: 160,
                          margin: const EdgeInsets.only(right: 12),
                        );
                      }

                      // Fall back to mock data
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
                            Text(
                              'Promotional Banner',
                              style: TextStyle(color: Colors.blueGrey),
                            ),
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

  Widget _buildSaleProductsSection() {
    final homeProvider = Provider.of<HomepageProvider>(context);
    final saleProducts = homeProvider.saleProducts.isNotEmpty
        ? homeProvider.saleProducts
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Sale Product',
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
            height: 310,
            child: homeProvider.isLoadingSaleProducts
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: saleProducts?.length ?? featuredProducts.length,
                    itemBuilder: (context, index) {
                      if (saleProducts != null) {
                        final apiProduct = saleProducts[index];
                        final mapped = {
                          'image': apiProduct.thumbnail,
                          'thumbnail': apiProduct.thumbnail,
                          'id': apiProduct.id,
                          'name': apiProduct.name,
                          'sku': apiProduct.sku,
                          'price': apiProduct.price,
                          'previous_price': apiProduct.previousPrice,
                          'description':
                              apiProduct.shortDescription ??
                              'On sale — description coming soon.',
                          'onSale': true,
                        };
                        return ProductCard(
                          product: mapped,
                          width: 160,
                          margin: const EdgeInsets.only(right: 12),
                        );
                      }

                      final product = featuredProducts[index];
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

  Widget _buildServicesSection() {
    // Use services from API if available
    final homeProvider = Provider.of<HomepageProvider>(context);
    final services = homeProvider.services;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Services',
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
              itemCount: services.isNotEmpty ? services.length : 5,
              itemBuilder: (context, index) {
                if (services.isEmpty) {
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
                    child: const Center(
                      child: Icon(
                        Icons.engineering,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  );
                }

                final service = services[index];
                return GestureDetector(
                  onTap: () {
                    // TODO: Handle service tap
                    Logger.info('Service tapped: ID ${service.id}');
                  },
                  child: Container(
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: service.photo.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: service.photo,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                        Icons.engineering,
                                        color: Colors.grey,
                                        size: 24,
                                      ),
                                )
                              : const Icon(
                                  Icons.engineering,
                                  color: Colors.grey,
                                  size: 24,
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            service.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF151D51),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildCollectionsSection() {
    // Use partners from API if available
    final homeProvider = Provider.of<HomepageProvider>(context);
    final partners = homeProvider.partners;

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
              itemCount: partners.isNotEmpty ? partners.length : 5,
              itemBuilder: (context, index) {
                if (partners.isEmpty) {
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
                    child: const Center(
                      child: Icon(Icons.business, color: Colors.grey, size: 40),
                    ),
                  );
                }

                final partner = partners[index];
                return GestureDetector(
                  onTap: () {
                    // TODO: Handle partner tap
                    Logger.info('Brand tapped: ID ${partner.id}');
                  },
                  child: Container(
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
                          child: partner.photo.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: partner.photo,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.business,
                                    color: Colors.grey[300],
                                    size: 40,
                                  ),
                                )
                              : Icon(
                                  Icons.business,
                                  color: Colors.grey[300],
                                  size: 40,
                                ),
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

  Future<CategoryFull?> _loadFullCategoryData(int categoryId) async {
    final cacheService = CategoriesCacheService();
    final cached = cacheService.getCategoryById(categoryId);
    if (cached != null) {
      return cached;
    }

    try {
      final categories = await _homepageService.getAllCategories();
      return categories.firstWhere((cat) => cat.id == categoryId);
    } on StateError {
      Logger.warning('Category ID $categoryId not found in full category list');
      return null;
    } catch (error, stackTrace) {
      Logger.error('Failed to load full category data', error, stackTrace);
      return null;
    }
  }

  Future<void> _navigateToCategory(Category category) async {
    Logger.info(
      'Category tapped: ${category.name} (ID: ${category.id}) - pageOpen: ${category.pageOpen}',
    );

    final normalizedPageOpen = category.pageOpen.toLowerCase();

    if (normalizedPageOpen == 'product_listing_page') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductListScreen(
            categoryId: category.id,
            categorySlug: category.slug,
            categoryType: 'category',
            title: category.name,
          ),
        ),
      );
      return;
    }

    if (normalizedPageOpen == 'landing_page') {
      final categoryData = await _loadFullCategoryData(category.id);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubCategoryPage(
            categoryId: category.id,
            categoryName: category.name,
            categoryData: categoryData,
          ),
        ),
      );
      return;
    }

    try {
      final categoryDetails = await _homepageService.getCategoryDetails(
        category.id,
      );
      if (!mounted) return;

      if (categoryDetails.hasSubcategories) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubCategoryPage(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductListScreen(
              categoryId: category.id,
              categorySlug: category.slug,
              categoryType: 'category',
              title: category.name,
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      Logger.error('Failed to fetch category details', error, stackTrace);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductListScreen(
            categoryId: category.id,
            categorySlug: category.slug,
            categoryType: 'category',
            title: category.name,
          ),
        ),
      );
    }
  }
}
