import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/categories_model.dart';
import '../../../core/services/categories_cache_service.dart';
import '../../../core/utils/logger.dart';
import '../productlist_view/productlist.dart';

class SubCategoryPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final CategoryFull? categoryData; // Optional cached category data

  const SubCategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.categoryData,
  });

  @override
  State<SubCategoryPage> createState() => _SubCategoryPageState();
}

class _SubCategoryPageState extends State<SubCategoryPage> {
  CategoryFull? _categoryData;
  List<SubCategoryFull> _subcategories = [];
  Map<int, bool> _expandedSubcategories =
      {}; // Track expanded state for subcategories
  Map<int, bool> _expandedChildCategories =
      {}; // Track expanded state for childs
  bool _isLoading = true;
  String? _errorMessage;
  int? _selectedChildSubId;

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
  }

  void _loadSubcategories() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Logger.info(
        'Loading subcategories for category ID: ${widget.categoryId}',
      );
      Logger.info('Category data provided: ${widget.categoryData != null}');

      // Use provided category data if available, otherwise get from cache
      final category =
          widget.categoryData ??
          CategoriesCacheService().getCategoryById(widget.categoryId);

      if (category == null) {
        Logger.error('Category not found - ID: ${widget.categoryId}');
        throw Exception('Category not found in cache');
      }

      Logger.info(
        'Category loaded: ${category.name}, Subcategories count: ${category.subs.length}',
      );
      Logger.info(
        'Subcategories: ${category.subs.map((s) => s.name).toList()}',
      );

      setState(() {
        _categoryData = category;
        _subcategories = category.subs;
        _isLoading = false;
      });

      Logger.info('Loaded ${_subcategories.length} subcategories from cache');
    } catch (e) {
      Logger.error('Failed to load subcategories', e);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load subcategories: ${e.toString()}';
      });
    }
  }

  void _navigateToSubcategory(SubCategoryFull subcategory) {
    // If subcategory has childs, show them inline (already shown)
    // Otherwise, navigate directly to product listing
    if (subcategory.childs.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductListScreen(
            categoryId: widget.categoryId,
            subcategoryId: subcategory.id,
            categorySlug: subcategory.slug,
            categoryType: 'subcategory',
            title: subcategory.name,
          ),
        ),
      );
    }
  }

  void _navigateToChild(ChildCategoryFull child) {
    // If child has childsubs, they're already shown inline
    // Otherwise, navigate to product listing
    if (child.childsubs.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductListScreen(
            categoryId: widget.categoryId,
            subcategoryId: child.subcategoryId,
            childcategoryId: child.id,
            categorySlug: child.slug,
            categoryType: 'childcategory',
            title: child.name,
          ),
        ),
      );
    }
  }

  void _navigateToChildSub(
    ChildCategoryFull child,
    ChildSubCategoryFull childSub,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductListScreen(
          categoryId: widget.categoryId,
          subcategoryId: child.subcategoryId,
          childcategoryId: child.id,
          subchildcategoryId: childSub.id,
          categorySlug: childSub.slug,
          categoryType: 'childsubcategory',
          title: childSub.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _categoryData?.name ?? widget.categoryName,
          style: const TextStyle(
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
              onPressed: _loadSubcategories,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // If no subcategories, show message
    if (_subcategories.isEmpty) {
      return Container(
        color: Colors.grey[50],
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No subcategories available',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[50],
      child: SafeArea(
        child: ListView(
          children: [
            // Subcategories list
            _buildMainCategoryContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCategoryContainer() {
    if (_categoryData == null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFB800), width: 2.5),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Category data not available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _subcategories.map((subcategory) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSubcategoryItem(subcategory),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryImage(String? imageUrl, {double size = 100}) {
    final isFullWidth = size == double.infinity;
    final imageHeight = isFullWidth ? 200.0 : size;
    // Use BoxFit.contain for full-width images to ensure entire image is visible
    final imageFit = isFullWidth ? BoxFit.contain : BoxFit.cover;

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: isFullWidth ? double.infinity : size,
        height: imageHeight,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: isFullWidth
              ? BorderRadius.zero
              : BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image, size: 48, color: Colors.grey),
        ),
      );
    }

    // Check if it's a network URL
    if (imageUrl.startsWith('http')) {
      return Container(
        width: isFullWidth ? double.infinity : size,
        height: imageHeight,
        color: Colors.white,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: isFullWidth ? double.infinity : size,
          height: imageHeight,
          fit: imageFit,
          placeholder: (context, url) => Container(
            width: isFullWidth ? double.infinity : size,
            height: imageHeight,
            color: Colors.grey[200],
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: isFullWidth ? double.infinity : size,
            height: imageHeight,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: isFullWidth
                  ? BorderRadius.zero
                  : BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.image, size: 48, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // Asset image
    return Container(
      width: isFullWidth ? double.infinity : size,
      height: imageHeight,
      color: Colors.white,
      child: Image.asset(
        imageUrl,
        width: isFullWidth ? double.infinity : size,
        height: imageHeight,
        fit: imageFit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: isFullWidth ? double.infinity : size,
            height: imageHeight,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: isFullWidth
                  ? BorderRadius.zero
                  : BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.image, size: 48, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubcategoryItem(SubCategoryFull subcategory) {
    final isExpanded = _expandedSubcategories[subcategory.id] ?? false;
    final hasChildren = subcategory.childs.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFB800), // Orange border
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subcategory Image and Name - Clickable/Expandable
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: hasChildren
                  ? () => _toggleSubcategory(subcategory.id)
                  : () => _navigateToSubcategory(subcategory),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Subcategory Image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11),
                      topRight: Radius.circular(11),
                    ),
                    child: _buildCategoryImage(
                      subcategory.subImage,
                      size: double.infinity,
                    ),
                  ),
                  // Subcategory Name
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFFFB800),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              subcategory.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          if (hasChildren)
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_right,
                              color: Colors.black,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Child Categories - Show only when expanded
          if (isExpanded && hasChildren)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _buildChildCategoryList(subcategory),
            ),
        ],
      ),
    );
  }

  void _toggleSubcategory(int subcategoryId) {
    setState(() {
      _expandedSubcategories[subcategoryId] =
          !(_expandedSubcategories[subcategoryId] ?? false);
    });
  }

  Widget _buildChildCategoryList(SubCategoryFull subcategory) {
    final childs = subcategory.childs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: childs.map((child) {
        final isExpanded = _expandedChildCategories[child.id] ?? false;
        return _buildChildCategoryItem(child, isExpanded);
      }).toList(),
    );
  }

  void _toggleChildCategory(int childId) {
    setState(() {
      _expandedChildCategories[childId] =
          !(_expandedChildCategories[childId] ?? false);
    });
  }

  Widget _buildChildCategoryItem(ChildCategoryFull child, bool isExpanded) {
    // Child categories should have dark blue background with white text
    // If child has no childsubs, show as direct button to products with dark blue background
    if (child.childsubs.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF003F7F), // Brand blue background
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToChild(child),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Center(
                child: Text(
                  child.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white, // White text
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // If child has childsubs, show expandable button with dark blue background
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // Child category button with + icon and dark blue background
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF003F7F), // Brand blue background
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _toggleChildCategory(child.id),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          child.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white, // White text
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.remove_circle_outline
                            : Icons.add_circle_outline,
                        size: 20,
                        color: Colors.white, // White icon
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Expanded content - Childsubs
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, right: 16),
              child: _buildExpandedContent(child),
            ),
        ],
      ),
    );
  }

  Widget _buildViewProductsButton(
    VoidCallback onTap, {
    String label = 'View Products',
    bool isPrimary = false,
    bool isSmall = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003F7F),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: isSmall ? 10 : 14,
            horizontal: isSmall ? 16 : 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isSmall ? 13 : 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: isSmall ? 16 : 18),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(ChildCategoryFull child) {
    // If child has childsubs, show them
    if (child.childsubs.isNotEmpty) {
      return _buildChildSubList(child);
    }

    // Otherwise, show View Products button
    return _buildViewProductsButton(
      () => _navigateToChild(child),
      label: 'View Products',
      isPrimary: true,
      isSmall: true,
    );
  }

  Widget _buildChildSubList(ChildCategoryFull child) {
    final childsubs = child.childsubs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: childsubs.map((childSub) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildChildSubItem(child, childSub),
        );
      }).toList(),
    );
  }

  Widget _buildChildSubItem(
    ChildCategoryFull child,
    ChildSubCategoryFull childSub,
  ) {
    const brandBlue = Color(0xFF003F7F);
    const highlightColor = Color(0xFFFFB800);
    final isSelected = _selectedChildSubId == childSub.id;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? highlightColor : brandBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedChildSubId = childSub.id;
            });
            _navigateToChildSub(child, childSub);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    childSub.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? brandBlue : Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.double_arrow,
                  size: 20,
                  color: isSelected ? brandBlue : Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
