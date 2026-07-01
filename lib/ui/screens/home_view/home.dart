import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../categories_view/subcategory_page.dart';
import '../drawer_view/drawer.dart';
import '../widget/listing_product_card.dart';
import '../productlist_view/sale_products.dart';
import '../productlist_view/productlist.dart';
import '../../../services/user_role_service.dart';
import '../../../services/storage_service.dart';
import '../../../data/services/settings_service.dart';
import '../../../data/models/settings_model.dart';
import '../../../data/models/homepage_model.dart';
import '../../../data/models/categories_model.dart';
import '../../../data/services/homepage_service.dart';
import '../../../providers/homepage_provider.dart';
import '../../../core/services/categories_cache_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/product_card_mapper.dart';
import '../../../services/navigation_service.dart';
import '../../../core/network/network_checker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import '../../../services/route_observer.dart';
import '../webview_view/webview_page.dart';
import '../../../services/custom_menu_service.dart';
import '../../widgets/content_loading_overlay.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;
  final int cartCount;
  final bool isActive;
  final bool initialOpenDrawer;

  const HomeScreen({
    super.key,
    this.onSearchTap,
    this.cartCount = 0,
    this.isActive = true,
    this.initialOpenDrawer = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  final PageController _bannerController = PageController();
  // Mid banner state
  int _currentMidBannerIndex = 0;
  Timer? _midBannerTimer;
  final PageController _midBannerController = PageController();

  // Auto-scroll for Latest Products
  int _currentProductIndex = 0;
  Timer? _productTimer;
  final PageController _productController = PageController();

  // Trader status
  bool _isTrader = false;

  // Settings data
  SettingsModel? _settings;
  final SettingsService _settingsService = SettingsService();

  // Homepage data moved to HomepageProvider
  final HomepageService _homepageService = HomepageService();

  // Avoid noisy logs on every rebuild
  bool _didLogCategoriesOnce = false;
  bool _didLogBannersOnce = false;

  // Track whether this route is visible (not covered by another route)
  bool _isRouteVisible = true;

  int _drawerSelectionResetNonce = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncTimers();
    }
  }

  @override
  void didPushNext() {
    // Another route is pushed on top of Home (e.g. Checkout).
    _isRouteVisible = false;
    _syncTimers();
  }

  @override
  void didPopNext() {
    // Returned back to Home.
    _isRouteVisible = true;
    _syncTimers();
    _reopenDrawerIfNeeded();
  }

  void _reopenDrawerIfNeeded() {
    if (!NavigationService.instance.takeDrawerReopenOnReturn()) return;

    setState(() {
      _drawerSelectionResetNonce++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scaffold.of(context).openDrawer();
    });
  }

  void _syncTimers() {
    final shouldRun = widget.isActive && _isRouteVisible;
    if (shouldRun) {
      _startBannerTimer();
      _startProductTimer();
      _startMidBannerTimer();
    } else {
      _stopBannerTimer();
      _stopProductTimer();
      _stopMidBannerTimer();
    }
  }

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

    if (widget.initialOpenDrawer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Scaffold.of(context).openDrawer();
      });
    }

    // Timers are controlled via _syncTimers() so they pause when Home isn't visible.
    _checkTraderStatus();
    _fetchSettings();
    // Load homepage data via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProvider = Provider.of<HomepageProvider>(
        context,
        listen: false,
      );
      homeProvider
          .loadHomepageData()
          .then((_) {
            if (mounted) _syncTimers();
          })
          .catchError((error) {
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
    _syncTimers();
  }

  Future<void> _onRefreshHome() async {
    final hasInternet = await NetworkChecker.hasConnection();
    if (!hasInternet) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please try again.'),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    final homeProvider = Provider.of<HomepageProvider>(context, listen: false);

    try {
      // Refresh all homepage provider data in parallel.
      await homeProvider.refresh();

      // Refresh categories cache used by SubCategoryPage (landing pages).
      await _homepageService.getAllCategories();
    } catch (e) {
      Logger.error('Home refresh failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to refresh. Please try again.')),
        );
      }
    }
  }

  /// Fetch settings — cache-first, only calls the API when nothing is cached.
  ///
  /// This is the single place in the app responsible for populating the
  /// settings cache: it runs once per Home load and is skipped entirely if
  /// settings already exist in SharedPreferences. The cache is only cleared
  /// on logout (`StorageService.clearAllData()`), so this will naturally
  /// re-fetch fresh settings the next time Home loads after a logout,
  /// regardless of whether the user logs back in or continues as guest.
  Future<void> _fetchSettings() async {
    try {
      final cachedSettings = await StorageService.getSettings();
      if (cachedSettings != null) {
        if (mounted) {
          setState(() {
            _settings = cachedSettings;
          });
        }
        Logger.info('Settings already cached, skipping API call');
        return;
      }

      Logger.info('No cached settings found, fetching from API');
      final settings = await _settingsService.getSettings();
      await StorageService.saveSettings(settings);

      if (mounted) {
        setState(() {
          _settings = settings;
        });
      }
      Logger.info('Settings fetched and saved successfully');
    } catch (e) {
      Logger.error('Failed to load settings', e);
      // Don't show error toast for settings — Home should still render
      // using whatever is cached (or without settings) if the API fails.
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
    if (_bannerTimer?.isActive == true) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_bannerController.hasClients) {
        final homeProvider = Provider.of<HomepageProvider>(
          context,
          listen: false,
        );
        final apiSliders = homeProvider.sliders;
        final itemCount = apiSliders.isNotEmpty
            ? apiSliders.length
            : banners.length;

        if (itemCount == 0) return;

        final next = (_currentBannerIndex + 1) % itemCount;
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        if (mounted) setState(() => _currentBannerIndex = next);
      }
    });
  }

  void _stopBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = null;
  }

  void _startProductTimer() {
    if (_productTimer?.isActive == true) return;
    _productTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_productController.hasClients && products.isNotEmpty) {
        final next = (_currentProductIndex + 1) % products.length;
        _productController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        if (mounted) setState(() => _currentProductIndex = next);
      }
    });
  }

  void _stopProductTimer() {
    _productTimer?.cancel();
    _productTimer = null;
  }

  void _startMidBannerTimer() {
    if (_midBannerTimer?.isActive == true) return;
    _midBannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_midBannerController.hasClients) {
        final homeProvider = Provider.of<HomepageProvider>(
          context,
          listen: false,
        );
        final allBanners = homeProvider.allBanners;
        if (allBanners.isNotEmpty) {
          final next = (_currentMidBannerIndex + 1) % allBanners.length;
          _midBannerController.animateToPage(
            next,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
          if (mounted) setState(() => _currentMidBannerIndex = next);
        }
      }
    });
  }

  void _stopMidBannerTimer() {
    _midBannerTimer?.cancel();
    _midBannerTimer = null;
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _stopBannerTimer();
    _bannerController.dispose();
    _stopProductTimer();
    _productController.dispose();
    _stopMidBannerTimer();
    _midBannerController.dispose();
    super.dispose();
  }

  /// Get settings data (for use in the app)
  SettingsModel? get settings => _settings;

  @override
  Widget build(BuildContext context) {
    final cartCount = widget.cartCount;
    return Consumer<HomepageProvider>(
      builder: (context, homeProvider, _) {
        final showLoadingOverlay = homeProvider.shouldShowLoadingOverlay;

        return Scaffold(
          drawer: AppDrawer(selectionResetNonce: _drawerSelectionResetNonce),
          drawerEnableOpenDragGesture: !showLoadingOverlay,
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F8F8),
            elevation: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Home',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.visible,
                ),
                if (_isTrader) ...[
                  const SizedBox(width: 8),
                  _buildTradeBadge(),
                ],
              ],
            ),
            titleSpacing: 0,
            centerTitle: false,
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          backgroundColor: Colors.grey[50],
          body: Stack(
            children: [
              SafeArea(
                child: RefreshIndicator.adaptive(
                  onRefresh: _onRefreshHome,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                                  NavigationService.instance.switchToTab(
                                    2,
                                  ); // Cart is now at index 2 (after removing wishlist)
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

                        // Collections Section
                        _buildCollectionsSection(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              if (showLoadingOverlay) const ContentLoadingOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTradeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business_center, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            'TRADE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection() {
    return Consumer<HomepageProvider>(
      builder: (context, homeProvider, _) {
        final apiSliders = homeProvider.sliders;
        final bool hasApiSliders = apiSliders.isNotEmpty;
        final int itemCount = hasApiSliders
            ? apiSliders.length
            : banners.length;

        if (itemCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              // Use a wider aspect ratio so backend images (which are often landscape
              // but not perfectly 2:1) aren't cropped on the sides.
              final double aspectRatio = width > 600 ? 21 / 9 : 16 / 7;

              return AspectRatio(
                aspectRatio: aspectRatio,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _bannerController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentBannerIndex = index;
                        });
                      },
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        // Use API sliders if available, otherwise fall back to local assets
                        if (hasApiSliders) {
                          final slider = apiSliders[index];
                          return Container(
                            margin: EdgeInsets.zero,
                            decoration: const BoxDecoration(),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.zero,
                                    child: GestureDetector(
                                      onTap: () async {
                                        if (slider.link != null &&
                                            slider.link!.isNotEmpty) {
                                          final uri = Uri.parse(slider.link!);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri);
                                          }
                                        }
                                      },
                                      child: CachedNetworkImage(
                                        imageUrl: slider.photo,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child: Icon(
                                                Icons.image,
                                                color: Colors.white54,
                                                size: 60,
                                              ),
                                            ),
                                          );
                                        },
                                        placeholder: (context, url) =>
                                            Container(
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Existing static banners (fallback)
                          final banner = banners[index];
                          return Container(
                            margin: EdgeInsets.zero,
                            decoration: const BoxDecoration(),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.zero,
                                    child: Image.asset(
                                      banner['image'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    banner['backgroundColor'],
                                                    banner['backgroundColor']
                                                        .withValues(alpha: 0.8),
                                                  ],
                                                ),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.image,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.5),
                                                  size: 60,
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
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
                          itemCount,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentBannerIndex == index
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoriesSection() {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;

    // Adaptive grid parameters
    final bool isTablet = screenWidth > 600;
    final bool isSmall = screenWidth < 360;
    // Force categories grid to 2 columns on Home page as requested
    final int crossAxisCount = 2;

    // Relative padding and spacing
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);
    final gridSpacing = (screenWidth * 0.03).clamp(8.0, 16.0);

    // Dynamic height calculation for childAspectRatio
    // We target a square image area + space for full text (up to 3 lines to prevent clipping)
    final itemWidth =
        (screenWidth -
            (horizontalPadding * 2) -
            (gridSpacing * (crossAxisCount - 1))) /
        crossAxisCount;
    final double labelFontSize = (screenWidth * 0.032).clamp(10.0, 13.0);
    // Height for text area: Support up to 4 lines of text + vertical padding
    final double textAreaHeight =
        (labelFontSize * 1.3 * 4) + (isSmall ? 14 : 20);
    final itemHeight = itemWidth + textAreaHeight;
    final childAspectRatio = itemWidth / itemHeight;

    return Consumer<HomepageProvider>(
      builder: (context, homeProvider, _) {
        final isLoadingHomepage = homeProvider.isLoading;
        final homepageData = homeProvider.homepageData;

        if (kDebugMode && !_didLogCategoriesOnce) {
          Logger.info(
            'Building categories section - isLoading: $isLoadingHomepage, hasData: ${homepageData != null}, categoriesCount: ${homepageData?.categories.length ?? 0}',
          );
        }

        if (isLoadingHomepage) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: (screenWidth * 0.05).clamp(18.0, 24.0),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF151D51),
                  ),
                ),
                SizedBox(height: gridSpacing),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: gridSpacing,
                    mainAxisSpacing: gridSpacing,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
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

        final rawCategories = homepageData?.categories ?? [];
        List<Category> categories;
        try {
          categories = List<Category>.from(rawCategories)
            ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        } catch (_) {
          categories = List<Category>.from(rawCategories);
        }

        // Debug log
        if (kDebugMode && !_didLogCategoriesOnce) {
          if (categories.isEmpty) {
            Logger.info(
              'No categories received from API - homepageData is null: ${homepageData == null}',
            );
            if (homepageData != null) {
              Logger.info('Homepage data exists but categories array is empty');
              final keys = homepageData.toJson().keys.join(", ");
              Logger.info('Available keys: $keys');
            }
          } else {
            Logger.info('Received ${categories.length} categories from API');
            categories.asMap().forEach((index, cat) {
              if (index < 3) {
                Logger.info(
                  'Category $index: name="${cat.name}", photo="${cat.photo}"',
                );
              }
            });
          }
          _didLogCategoriesOnce = true;
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
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Categories',
                style: TextStyle(
                  fontSize: (screenWidth * 0.05).clamp(18.0, 24.0),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF151D51),
                ),
              ),
              SizedBox(height: gridSpacing),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: gridSpacing,
                  mainAxisSpacing: gridSpacing,
                  childAspectRatio: childAspectRatio,
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
                      if (category.slug == 'sale') {
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
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Image section with fixed AspectRatio
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child:
                                  category.image != null &&
                                      category.image!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: category.image!,
                                      width: double.infinity,
                                      fit: BoxFit.contain, // Scale proportional
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
                                          Image.asset(
                                            'assets/images/no_image.png',
                                            width: double.infinity,
                                            fit: BoxFit.contain,
                                          ),
                                    )
                                  : Image.asset(
                                      'assets/images/no_image.png',
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                    ),
                            ),
                          ),
                          // Category name - grows to fit full text
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02,
                                vertical: isSmall ? 5 : 7,
                              ),
                              child: Center(
                                child: Text(
                                  category.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 4,
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: labelFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF151D51),
                                    height: 1.3,
                                  ),
                                ),
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
      },
    );
  }

  Widget _buildLatestProductsSection() {
    final homeProvider = Provider.of<HomepageProvider>(context);
    final displayProducts = homeProvider.latestProducts.isNotEmpty
        ? homeProvider.latestProducts
        : null;
    final itemCount = displayProducts?.length ?? products.length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Latest Product',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF151D51),
            ),
          ),
          const SizedBox(height: 16),
          homeProvider.isLoadingLatestProducts
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SizedBox(
                  height: 320,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (displayProducts != null) {
                        final apiProduct = displayProducts[index];
                        final mapped =
                            ProductCardMapper.mapLatestProductForListingCard(
                              product: apiProduct,
                              isTradeUser: _isTrader,
                              descriptionFallback:
                                  'Latest product — description coming soon.',
                            );
                        return SizedBox(
                          width: MediaQuery.of(context).size.width * 0.47,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ListingProductCard(product: mapped),
                          ),
                        );
                      }
                      final product = products[index];
                      final mapped =
                          ProductCardMapper.mapLegacyProductMapForListingCard(
                            product: product,
                            isTradeUser: _isTrader,
                          );
                      return SizedBox(
                        width: 180,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ListingProductCard(product: mapped),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildMidBanner() {
    return Consumer<HomepageProvider>(
      builder: (context, homeProvider, child) {
        final allBanners = homeProvider.allBanners;

        if (kDebugMode && !_didLogBannersOnce) {
          debugPrint('Banner count: ${allBanners.length}');
          if (allBanners.isNotEmpty) {
            debugPrint('First banner photo: ${allBanners[0].photo}');
          }
          _didLogBannersOnce = true;
        }

        // If no banners from API, show a placeholder or nothing
        if (allBanners.isEmpty) {
          if (kDebugMode) {
            debugPrint('No banners available - hiding banner section');
          }
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              // A ratio of 16 / 6.5 (2.46) on mobile scales nicely. For tablets,
              // we can use a wider ratio like 21 / 7 (3.0) to keep it compact.
              final double aspectRatio = width > 600 ? 21 / 7 : 16 / 6.5;

              return AspectRatio(
                aspectRatio: aspectRatio,
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
                        itemCount: allBanners.length,
                        itemBuilder: (context, index) {
                          final banner = allBanners[index];
                          return GestureDetector(
                            onTap: () {
                              if (banner.link != null &&
                                  banner.link!.isNotEmpty) {
                                launchUrl(Uri.parse(banner.link!));
                              }
                            },
                            child: CachedNetworkImage(
                              imageUrl: banner.photo,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Indicators (small, subtle)
                    if (allBanners.length > 1)
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            allBanners.length,
                            (index) => Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentMidBannerIndex == index
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSaleProductsSection() {
    return Consumer<HomepageProvider>(
      builder: (context, homeProvider, _) {
        final saleProducts = homeProvider.saleProducts;
        final isLoading = homeProvider.isLoadingSaleProducts;
        final double sectionHeight = isLoading
            ? 320
            : saleProducts.isEmpty
            ? 90
            : 320;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sale Product',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151D51),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: sectionHeight,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : saleProducts.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: const Center(
                          child: Text(
                            'No data found',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: saleProducts.length,
                        itemBuilder: (context, index) {
                          final apiProduct = saleProducts[index];
                          final mapped =
                              ProductCardMapper.mapLatestProductForListingCard(
                                product: apiProduct,
                                isTradeUser: _isTrader,
                                descriptionFallback:
                                    'On sale — description coming soon.',
                              );
                          return SizedBox(
                            width: MediaQuery.of(context).size.width * 0.47,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ListingProductCard(product: mapped),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
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
                          color: Colors.grey.withValues(alpha: 0.08),
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
                          color: Colors.grey.withValues(alpha: 0.08),
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
                          color: Colors.grey.withValues(alpha: 0.08),
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
                          color: Colors.grey.withValues(alpha: 0.08),
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

    // --- Step 1: Check custom_menus by category ID (dynamic, backend-driven) ---
    final customMenu = await CustomMenuService.getMenuForCategory(category.id);
    if (customMenu != null) {
      Logger.info(
        'custom_menus match for ID ${category.id}: type=${customMenu.type}',
      );
      if (customMenu.isCustomNative) {
        // type == "custom" → open native Installation Manuals screen (tab 3)
        NavigationService.instance.switchToTab(3);
        return;
      }
      if (customMenu.isForm && customMenu.url.isNotEmpty) {
        // type == "form" → open WebView with the given URL
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                WebViewPage(url: customMenu.url, title: category.name),
          ),
        );
        return;
      }
    }

    final normalizedPageOpen = category.pageOpen.toLowerCase().trim();

    void showCategoryLoadError([String? debugReason]) {
      Logger.warning(
        'Category navigation blocked. categoryId=${category.id}, pageOpen="$normalizedPageOpen", reason=${debugReason ?? "unknown"}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "We couldn’t load this category. Please try again. If the issue continues, close and restart the app.",
          ),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              // ignore: discarded_futures
              unawaited(_navigateToCategory(category));
            },
          ),
        ),
      );
    }

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

      // If full category data isn't available, don't navigate further.
      if (categoryData == null) {
        showCategoryLoadError('CategoryFull not found in cache/all categories');
        return;
      }

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

    if (normalizedPageOpen == 'other_page') {
      if (category.categorySlugUrl != null &&
          category.categorySlugUrl!.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewPage(
              url: category.categorySlugUrl!,
              title: category.name,
            ),
          ),
        );
      } else {
        showCategoryLoadError('URL missing for other_page');
      }
      return;
    }

    // page_open is missing/unknown/unsupported (e.g., "other") — block navigation.
    if (normalizedPageOpen.isEmpty || normalizedPageOpen == 'other') {
      showCategoryLoadError('Unsupported page_open value');
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
      showCategoryLoadError('Failed to fetch category details');
      return;
    }
  }
}
