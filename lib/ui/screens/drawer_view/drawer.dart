import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../categories_view/categories_grid.dart';
import '../productlist_view/sale_products.dart';
import '../productlist_view/productlist.dart';
import '../categories_view/subcategory_page.dart';
import '../../../providers/homepage_provider.dart';
import '../../../data/models/homepage_model.dart';
import '../../../data/models/categories_model.dart';
import '../../../data/services/homepage_service.dart';
import '../../../core/services/categories_cache_service.dart';
import '../../../core/utils/logger.dart';
import '../webview_view/webview_page.dart';
import '../../../services/navigation_service.dart';
import '../../../services/custom_menu_service.dart';
import '../../widgets/content_loading_overlay.dart';
import '../manuals/manuals_menu.dart';

class AppDrawer extends StatefulWidget {
  final int selectionResetNonce;

  const AppDrawer({super.key, this.selectionResetNonce = 0});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? _selectedTitle;
  String _appVersion = '';
  final HomepageService _homepageService = HomepageService();

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  @override
  void didUpdateWidget(covariant AppDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectionResetNonce != oldWidget.selectionResetNonce &&
        _selectedTitle != null) {
      setState(() {
        _selectedTitle = null;
      });
    }
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  /// Find category by slug from homepage data
  Category? _findCategoryBySlug(String slug) {
    final homeProvider = Provider.of<HomepageProvider>(context, listen: false);
    final homepageData = homeProvider.homepageData;

    if (homepageData == null || homepageData.categories.isEmpty) {
      Logger.warning('No categories available in homepage data');
      return null;
    }

    try {
      return homepageData.categories.firstWhere((cat) => cat.slug == slug);
    } catch (e) {
      Logger.warning('Category slug "$slug" not found in homepage data');
      return null;
    }
  }

  /// Find category by name from homepage data
  Category? _findCategoryByName(String categoryName) {
    final homeProvider = Provider.of<HomepageProvider>(context, listen: false);
    final homepageData = homeProvider.homepageData;

    if (homepageData == null || homepageData.categories.isEmpty) {
      Logger.warning('No categories available in homepage data');
      return null;
    }

    // Try exact match first
    try {
      return homepageData.categories.firstWhere(
        (cat) =>
            cat.name.toLowerCase().trim() == categoryName.toLowerCase().trim(),
      );
    } catch (e) {
      // Try partial match
      try {
        return homepageData.categories.firstWhere(
          (cat) =>
              cat.name.toLowerCase().contains(categoryName.toLowerCase()) ||
              categoryName.toLowerCase().contains(cat.name.toLowerCase()),
        );
      } catch (e2) {
        Logger.warning('Category "$categoryName" not found in homepage data');
        return null;
      }
    }
  }

  /// Navigate by known category ID — checks custom_menus first, then falls back
  /// to slug lookup + normal routing. Use this for drawer items where you know
  /// the exact backend category ID.
  Future<void> _navigateByCategoryId(int categoryId, String displayName) async {
    // Step 1: Check custom_menus by ID (same logic as home page)
    final customMenu = await CustomMenuService.getMenuForCategory(categoryId);
    if (customMenu != null) {
      Logger.info(
        'Drawer custom_menus match for ID $categoryId: type=${customMenu.type}',
      );
      if (customMenu.isCustomNative) {
        // Open Installation Manuals page
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManualsMenuPage()),
          );
        }
        return;
      }
      if (customMenu.isForm && customMenu.url.isNotEmpty) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  WebViewPage(url: customMenu.url, title: displayName),
            ),
          );
        }
        return;
      }
    }

    // Step 2: No custom_menus entry — find the category and use normal routing
    final homeProvider = Provider.of<HomepageProvider>(context, listen: false);
    final homepageData = homeProvider.homepageData;
    Category? category;
    if (homepageData != null) {
      try {
        category = homepageData.categories.firstWhere(
          (cat) => cat.id == categoryId,
        );
      } catch (_) {}
    }

    if (category != null) {
      await _navigateWithCategory(category);
    } else {
      Logger.warning('Category ID $categoryId not found in homepage data');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$displayName category not found'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Navigate to category by slug (for items without a known fixed ID)
  Future<void> _navigateToCategoryBySlug(String slug) async {
    Navigator.pop(context); // Close drawer first

    final category = _findCategoryBySlug(slug);
    if (category != null) {
      await _navigateWithCategory(category);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category not found'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Navigate to category by name (legacy support)
  Future<void> _navigateToCategoryByName(String categoryName) async {
    Navigator.pop(context); // Close drawer first

    // Handle Installation Manuals special navigation via name check (fallback)
    if (categoryName.toLowerCase().contains('installation manuals')) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ManualsMenuPage()),
        );
      }
      return;
    }

    final category = _findCategoryByName(categoryName);
    if (category == null) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$categoryName" not found'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    await _navigateWithCategory(category);
  }

  /// Internal helper for shared navigation logic
  Future<void> _navigateWithCategory(Category category) async {
    Logger.info(
      'Navigating to category: ${category.name} (ID: ${category.id}, Slug: ${category.slug}) - pageOpen: ${category.pageOpen}',
    );

    // --- Step 1: Check custom_menus by category ID (dynamic, backend-driven) ---
    final customMenu = await CustomMenuService.getMenuForCategory(category.id);
    if (customMenu != null) {
      Logger.info(
        'Drawer custom_menus match for ID ${category.id}: type=${customMenu.type}',
      );
      if (customMenu.isCustomNative) {
        // type == "custom" → open native screen (e.g., Installation Manuals page)
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManualsMenuPage()),
          );
        }
        return;
      }
      if (customMenu.isForm && customMenu.url.isNotEmpty) {
        // type == "form" → open WebView
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  WebViewPage(url: customMenu.url, title: category.name),
            ),
          );
        }
        return;
      }
    }

    final normalizedPageOpen = category.pageOpen.toLowerCase();

    if (normalizedPageOpen == 'product_listing_page') {
      if (mounted) {
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
      return;
    }

    if (normalizedPageOpen == 'landing_page') {
      final cacheService = CategoriesCacheService();
      CategoryFull? categoryData = cacheService.getCategoryById(category.id);

      if (categoryData == null) {
        try {
          final categories = await _homepageService.getAllCategories();
          categoryData = categories.firstWhere((cat) => cat.id == category.id);
        } catch (e) {
          Logger.warning(
            'Category ID ${category.id} not found in full category list',
          );
        }
      }

      if (mounted) {
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
      }
      return;
    }

    if (normalizedPageOpen == 'other_page') {
      if (category.categorySlugUrl != null &&
          category.categorySlugUrl!.isNotEmpty) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewPage(
                url: category.categorySlugUrl!,
                title: category.name,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('URL missing for this category'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      return;
    }

    // Default: try to get category details and navigate
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

      // Fallback: navigate to product list
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

  @override
  Widget build(BuildContext context) {
    return Consumer<HomepageProvider>(
      builder: (context, homeProvider, _) {
        final showLoadingOverlay = homeProvider.shouldShowLoadingOverlay;

        return Drawer(
          child: Stack(
            children: [
              Container(
                color: const Color(0xFFF8F8F8),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(0, 5, 16, 5),
                        children: [
                          SizedBox(
                            height: 60,
                            child: DrawerHeader(
                              margin: EdgeInsets.zero,
                              padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8F8F8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CategoriesGridScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Categories',
                                      style: TextStyle(
                                        color: Color(0xFF101010),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Color(0xFF101010),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildSeparator(),

                          // Dynamic Categories from API
                          Consumer<HomepageProvider>(
                            builder: (context, homeProvider, _) {
                              if (homeProvider.shouldShowLoadingOverlay) {
                                return const SizedBox.shrink();
                              }

                              final categories =
                                  List<Category>.from(homeProvider.categories)
                                    ..sort(
                                      (a, b) => a.displayOrder.compareTo(
                                        b.displayOrder,
                                      ),
                                    );

                              // Filter out categories that are already handled as special items (if any)
                              // For now, we'll show all categories from API.

                              return Column(
                                children: categories.map((category) {
                                  // Check if this category should be skipped because it's handled separately
                                  // e.g., if Installation Manuals is in the category list
                                  if (category.id == 14)
                                    return const SizedBox.shrink();

                                  return Column(
                                    children: [
                                      _buildItem(
                                        imageUrl: category.photo,
                                        title: category.name,
                                        onTap: () =>
                                            _navigateWithCategory(category),
                                      ),
                                      _buildSeparator(),
                                    ],
                                  );
                                }).toList(),
                              );
                            },
                          ),

                          _buildItem(
                            title: 'Installation Manuals',
                            onTap: () => _navigateByCategoryId(
                              14,
                              'Installation Manuals',
                            ),
                          ),
                          _buildSeparator(),
                          _buildItem(
                            title: '+ see all categories',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CategoriesGridScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    _buildVersionFooter(),
                  ],
                ),
              ),
              if (showLoadingOverlay) const ContentLoadingOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVersionFooter() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Text(
          _appVersion.isEmpty ? '' : 'Version $_appVersion',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildItem({
    String? imageUrl,
    required String title,
    required VoidCallback onTap,
  }) {
    final bool isSelected = _selectedTitle == title;

    Widget? leading;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      leading = SizedBox(
        width: 24,
        height: 24,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => const SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Image.asset(
            'assets/images/no_image.png',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return Container(
      color: isSelected ? const Color(0xFFFFC107) : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: leading,
        title: Text(
          title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? Colors.black : const Color(0xFF101010),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isSelected ? Colors.black54 : const Color(0xFF101010),
        ),
        onTap: () {
          setState(() {
            _selectedTitle = title;
          });
          NavigationService.instance.markDrawerMenuNavigation();
          onTap();
        },
      ),
    );
  }

  Widget _buildSeparator() {
    return const Divider(color: Color(0xFF101010), height: 1);
  }
}
