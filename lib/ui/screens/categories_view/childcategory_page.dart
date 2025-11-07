import 'package:flutter/material.dart';
import '../../../data/services/homepage_service.dart';
import '../../../data/models/homepage_model.dart';
import '../../../core/utils/logger.dart';
import '../widget/category_tile.dart';
import '../productlist_view/productlist.dart';
import 'subchildcategory_page.dart';

class ChildCategoryPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final int subcategoryId;
  final String subcategoryName;

  const ChildCategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryId,
    required this.subcategoryName,
  });

  @override
  State<ChildCategoryPage> createState() => _ChildCategoryPageState();
}

class _ChildCategoryPageState extends State<ChildCategoryPage> {
  final HomepageService _homepageService = HomepageService();
  List<ChildCategory> _childcategories = [];
  Map<int, ChildCategory> _childCategoryDetails = {}; // Cache childcategory details with subchildcategories
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSubcategoryDetails();
  }

  Future<void> _fetchSubcategoryDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Logger.info('Fetching subcategory details for ID: ${widget.subcategoryId}');
      final subcategory =
          await _homepageService.getSubcategoryDetails(widget.subcategoryId);

      // Fetch full details for each childcategory to get subchildcategories
      List<ChildCategory> childcategoriesWithDetails = [];
      for (var childcategory in subcategory.childcategories ?? []) {
        try {
          final childcategoryDetails = await _homepageService
              .getChildcategoryDetails(childcategory.id);
          childcategoriesWithDetails.add(childcategoryDetails);
          _childCategoryDetails[childcategory.id] = childcategoryDetails;
        } catch (e) {
          Logger.warning(
            'Failed to fetch details for childcategory ${childcategory.id}, using basic info',
          );
          childcategoriesWithDetails.add(childcategory);
        }
      }

      setState(() {
        _childcategories = childcategoriesWithDetails;
        _isLoading = false;
      });

      Logger.info('Loaded ${_childcategories.length} childcategories with details');
    } catch (e) {
      Logger.error('Failed to load subcategory details', e);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load child categories. Please try again.';
      });
    }
  }

  void _navigateToChildcategory(ChildCategory childcategory) {
    // Get full details if available (with subchildcategories)
    final childcategoryDetails = _childCategoryDetails[childcategory.id] ?? childcategory;
    
    // If childcategory has subchildcategories, show them in a new page
    if (childcategoryDetails.hasSubchildcategories &&
        childcategoryDetails.subchildcategories != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubChildCategoryPage(
            categoryId: widget.categoryId,
            categoryName: widget.categoryName,
            subcategoryId: widget.subcategoryId,
            subcategoryName: widget.subcategoryName,
            childcategoryId: childcategory.id,
            childcategoryName: childcategory.name,
          ),
        ),
      );
    } else {
      // Otherwise, navigate directly to product listing
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductListScreen(
            categoryId: widget.categoryId,
            subcategoryId: widget.subcategoryId,
            childcategoryId: childcategory.id,
            title: childcategory.name,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.subcategoryName,
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
              onPressed: _fetchSubcategoryDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // If no childcategories, navigate directly to products
    if (_childcategories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductListScreen(
              categoryId: widget.categoryId,
              subcategoryId: widget.subcategoryId,
              title: widget.subcategoryName,
            ),
          ),
        );
      });
      return const Center(child: CircularProgressIndicator());
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
            itemCount: _childcategories.length,
            itemBuilder: (context, index) {
              final childcategory = _childcategories[index];
              return CategoryTile(
                name: childcategory.name,
                image: childcategory.image,
                onTap: () => _navigateToChildcategory(childcategory),
              );
            },
          ),
        ),
      ),
    );
  }
}

