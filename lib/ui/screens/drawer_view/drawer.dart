import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? _selectedTitle;
  final HomepageService _homepageService = HomepageService();

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
        (cat) => cat.name.toLowerCase().trim() == categoryName.toLowerCase().trim(),
      );
    } catch (e) {
      // Try partial match
      try {
        return homepageData.categories.firstWhere(
          (cat) => cat.name.toLowerCase().contains(categoryName.toLowerCase()) ||
              categoryName.toLowerCase().contains(cat.name.toLowerCase()),
        );
      } catch (e2) {
        Logger.warning('Category "$categoryName" not found in homepage data');
        return null;
      }
    }
  }

  /// Navigate to category (same logic as home page)
  Future<void> _navigateToCategoryByName(String categoryName) async {
    Navigator.pop(context); // Close drawer first

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

    Logger.info(
      'Navigating to category: ${category.name} (ID: ${category.id}) - pageOpen: ${category.pageOpen}',
    );

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
          Logger.warning('Category ID ${category.id} not found in full category list');
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

    // Default: try to get category details and navigate
    try {
      final categoryDetails = await _homepageService.getCategoryDetails(category.id);
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
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 96,
              child: DrawerHeader(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(color: Color(0xFFF8F8F8)),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoriesGridScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Categories',
                              style: TextStyle(
                                color: Color(0xFF101010),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF101010),
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            _buildItem(
              icon: Icons.local_fire_department,
              title: 'Sale',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SaleProductsScreen(),
                  ),
                );
              },
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.settings_input_component,
              title: 'Gate Automation Kits',
              onTap: () => _navigateToCategoryByName('Gate Automation Kits'),
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.home_repair_service,
              title: 'Gate & Fencing Hardware',
              onTap: () => _navigateToCategoryByName('Gate & Fencing Hardware'),
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.electric_bolt,
              title: 'Brushless Electric Gate Kits',
              onTap: () => _navigateToCategoryByName('Brushless Electric Gate Kits'),
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.handyman,
              title: 'Premium Hardware for Cantilever, Sliding & Swing Gates',
              onTap: () => _navigateToCategoryByName('Premium Hardware for Cantilever, Sliding & Swing Gates'),
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.auto_awesome_mosaic,
              title: 'Gate, Automation & Hardware Combos',
              onTap: () => _navigateToCategoryByName('Gate, Automation & Hardware Combos'),
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.door_sliding,
              title: 'Gates & Gate Frames',
              onTap: () => _navigateToCategoryByName('Gates & Gate Frames'),
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.build_circle,
              title: 'Custom Made Gates',
              onTap: () => _navigateToCategoryByName('Custom Made Gates'),
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.traffic,
              title: 'Boom Gates',
              onTap: () => _navigateToCategoryByName('Boom Gates'),
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.videocam,
              title: 'Video Intercoms and Surveillance Systems',
              onTap: () => _navigateToCategoryByName('Video Intercoms and Surveillance Systems'),
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.settings_remote,
              title: 'Remotes',
              onTap: () => _navigateToCategoryByName('Remotes'),
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.security,
              title: 'Access Control & Accessories',
              onTap: () => _navigateToCategoryByName('Access Control & Accessories'),
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.power,
              title: 'Replacement Parts, Power Supplies & Cables',
              onTap: () => _navigateToCategoryByName('Replacement Parts, Power Supplies & Cables'),
            ),
            _buildSeparator(),
            _buildItem(
              icon: Icons.solar_power,
              title: 'Solar Equipment',
              onTap: () => _navigateToCategoryByName('Solar Equipment'),
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

  Widget _buildItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final bool isSelected = _selectedTitle == title;
    return Container(
      color: isSelected ? const Color(0xFFFFC107) : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.black : Color(0xFF101010),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : Color(0xFF101010),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isSelected ? Colors.black54 : Color(0xFF101010),
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
