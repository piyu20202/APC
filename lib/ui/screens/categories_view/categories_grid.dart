import 'package:flutter/material.dart';
import '../../../data/services/homepage_service.dart';
import '../../../data/models/categories_model.dart';
import '../../../core/utils/logger.dart';
import 'subcategory_page.dart';
import '../productlist_view/productlist.dart';
import '../widget/category_tile.dart';

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

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.95,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return CategoryTile(
                name: category.name,
                image: category.image, // Use image for grid display
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

    final normalizedPageOpen = category.pageOpen.toLowerCase();

    if (normalizedPageOpen == 'product_listing_page') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProductListScreen(categoryId: category.id, title: category.name),
        ),
      );
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
        builder: (context) =>
            ProductListScreen(categoryId: category.id, title: category.name),
      ),
    );
  }
}
