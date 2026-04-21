import 'package:flutter/material.dart';
import '../../../data/services/homepage_service.dart';
import '../../../data/models/categories_model.dart';
import '../../../core/utils/logger.dart';
import '../../../services/navigation_service.dart';
import 'subcategory_page.dart';
import '../productlist_view/productlist.dart';
import '../widget/category_tile.dart';
import '../webview_view/webview_page.dart';

class CategoriesGridScreen extends StatefulWidget {
  const CategoriesGridScreen({super.key});

  @override
  State<CategoriesGridScreen> createState() => _CategoriesGridScreenState();
}

class _CategoriesGridScreenState extends State<CategoriesGridScreen> {
  final HomepageService _homepageService = HomepageService();
  List<CategoryFull> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Logger.info('Fetching all categories for grid view');
      final categories = await _homepageService.getAllCategories();

      setState(() {
        _categories = categories;
        _isLoading = false;
      });

      Logger.info('Loaded ${_categories.length} categories');
    } catch (e) {
      Logger.error('Failed to load categories', e);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load categories. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Categories',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFF2F0EF),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchCategories,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return const Center(
        child: Text(
          'No categories available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;
    final int crossAxisCount = isTablet ? 3 : 2;
    
    // Relative padding and spacing
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);
    final gridSpacing = (screenWidth * 0.04).clamp(12.0, 16.0);
    
    // Dynamic height calculation for childAspectRatio to avoid overflow
    final itemWidth = (screenWidth - (horizontalPadding * 2) - (gridSpacing * (crossAxisCount - 1))) / crossAxisCount;
    final double labelFontSize = (screenWidth * 0.035).clamp(11.0, 14.0);
    final double textAreaHeight = (labelFontSize * 1.2 * 2) + 16;
    final itemHeight = itemWidth + textAreaHeight;
    final childAspectRatio = itemWidth / itemHeight;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: GridView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 80),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: gridSpacing,
              mainAxisSpacing: gridSpacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return CategoryTile(
                name: category.name,
                image: category.image,
                onTap: () => _navigateToCategory(category),
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToCategory(CategoryFull category) {
    Logger.info(
      'Category tapped: ${category.name} (ID: ${category.id}) - pageOpen: ${category.pageOpen}',
    );

    // Handle Installation Manuals special navigation
    final normalizedName = category.name.toLowerCase().trim();
    if (normalizedName.contains('installation manuals')) {
      NavigationService.instance.switchToTab(3);
      // If we are on a pushed screen, pop back to main navigation
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

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
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL missing for this category'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Default to subcategory view for landing pages and any other values when subs exist
    if (category.subs.isNotEmpty || normalizedPageOpen == 'landing_page') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubCategoryPage(
            categoryId: category.id,
            categoryName: category.name,
            categoryData: category, // Pass the full category data
          ),
        ),
      );
      return;
    }

    // Fallback: navigate to product listing if no subcategories available
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
