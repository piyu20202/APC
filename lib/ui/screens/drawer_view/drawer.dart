import 'package:flutter/material.dart';
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

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? _selectedTitle;
  final HomepageService _homepageService = HomepageService();

  /// Find category by slug from homepage data
  Category? _findCategoryBySlug(String slug) {
    final homeProvider = Provider.of<HomepageProvider>(context, listen: false);
    final homepageData = homeProvider.homepageData;

    if (homepageData == null || homepageData.categories.isEmpty) {
      Logger.warning('No categories available in homepage data');
      return null;
    }

    try {
      return homepageData.categories.firstWhere(
        (cat) => cat.slug == slug,
      );
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
    Navigator.pop(context); // Close drawer first

    // Step 1: Check custom_menus by ID (same logic as home page)
    final customMenu = await CustomMenuService.getMenuForCategory(categoryId);
    if (customMenu != null) {
      Logger.info(
        'Drawer custom_menus match for ID $categoryId: type=${customMenu.type}',
      );
      if (customMenu.isCustomNative) {
        NavigationService.instance.switchToTab(3);
        return;
      }
      if (customMenu.isForm && customMenu.url.isNotEmpty) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewPage(
                url: customMenu.url,
                title: displayName,
              ),
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
      NavigationService.instance.switchToTab(3);
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
        // type == "custom" → open native screen (e.g., Installation Manuals tab)
        NavigationService.instance.switchToTab(3);
        return;
      }
      if (customMenu.isForm && customMenu.url.isNotEmpty) {
        // type == "form" → open WebView
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewPage(
                url: customMenu.url,
                title: category.name,
              ),
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
    return Drawer(
      child: Container(
        color: const Color(0xFFF8F8F8),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 5, 16, 5),
          children: [
            SizedBox(
              height: 60,
              child: DrawerHeader(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
                decoration: const BoxDecoration(color: Color(0xFFF8F8F8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CategoriesGridScreen(),
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
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF101010)),
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
                final categories = List<Category>.from(homeProvider.categories)
                  ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

                // Filter out categories that are already handled as special items (if any)
                // For now, we'll show all categories from API.
                
                return Column(
                  children: categories.map((category) {
                    // Check if this category should be skipped because it's handled separately
                    // e.g., if Installation Manuals is in the category list
                    if (category.id == 14) return const SizedBox.shrink();

                    return Column(
                      children: [
                        _buildItem(
                          icon: _getIconForCategory(category),
                          imageUrl: category.photo,
                          title: category.name,
                          onTap: () => _navigateWithCategory(category),
                        ),
                        _buildSeparator(),
                      ],
                    );
                  }).toList(),
                );
              },
            ),

            _buildItem(
              icon: Icons.menu_book,
              title: 'Installation Manuals',
              onTap: () => _navigateByCategoryId(14, 'Installation Manuals'),
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.add_circle_outline,
              title: '+ see all categories',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoriesGridScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(Category category) {
    final slug = category.slug?.toLowerCase() ?? '';
    final name = category.name.toLowerCase();

    if (slug.contains('automation') || name.contains('automation')) {
      return Icons.settings_input_component;
    }
    if (slug.contains('fencing') || name.contains('fencing') || name.contains('hardware')) {
      return Icons.home_repair_service;
    }
    if (slug.contains('brushless') || name.contains('brushless')) {
      return Icons.electric_bolt;
    }
    if (slug.contains('premium') || name.contains('premium')) {
      return Icons.handyman;
    }
    if (slug.contains('combo') || name.contains('combo')) {
      return Icons.auto_awesome_mosaic;
    }
    if (slug.contains('gates-gate-frames') || name.contains('frames')) {
      return Icons.door_sliding;
    }
    if (slug.contains('custom') || name.contains('custom')) {
      return Icons.build_circle;
    }
    if (slug.contains('boom') || name.contains('boom')) {
      return Icons.traffic;
    }
    if (slug.contains('intercom') || name.contains('intercom') || name.contains('surveillance')) {
      return Icons.videocam;
    }
    if (slug.contains('remote') || name.contains('remote')) {
      return Icons.settings_remote;
    }
    if (slug.contains('access') || name.contains('access')) {
      return Icons.security;
    }
    if (slug.contains('parts') || name.contains('parts') || name.contains('cable') || name.contains('power')) {
      return Icons.power;
    }
    if (slug.contains('solar') || name.contains('solar')) {
      return Icons.solar_power;
    }

    return Icons.category; // Default icon
  }

  Widget _buildItem({
    IconData? icon,
    String? imageUrl,
    required String title,
    required VoidCallback onTap,
  }) {
    final bool isSelected = _selectedTitle == title;
    
    Widget leading;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      leading = Container(
        width: 24,
        height: 24,
        color: Colors.transparent,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => Icon(
            icon ?? Icons.category,
            size: 24,
            color: isSelected ? Colors.black : const Color(0xFF101010),
          ),
          errorWidget: (context, url, error) => Icon(
            icon ?? Icons.category,
            size: 24,
            color: isSelected ? Colors.black : const Color(0xFF101010),
          ),
        ),
      );
    } else {
      leading = Icon(
        icon ?? Icons.category,
        color: isSelected ? Colors.black : const Color(0xFF101010),
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
          onTap();
        },
      ),
    );
  }

  Widget _buildSeparator() {
    return const Divider(color: Color(0xFF101010), height: 1);
  }
}
