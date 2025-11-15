import 'package:flutter/material.dart';
import '../../../data/services/homepage_service.dart';
import '../../../data/models/homepage_model.dart';
import '../../../core/utils/logger.dart';
import '../widget/category_tile.dart';
import '../productlist_view/productlist.dart';

class SubChildCategoryPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final int subcategoryId;
  final String subcategoryName;
  final int childcategoryId;
  final String childcategoryName;
  final int? parentSubchildcategoryId; // For nested subchildcategories
  final String? parentSubchildcategoryName; // For nested subchildcategories
  final String? subcategorySlug;
  final String? childcategorySlug;
  final String? parentSubchildcategorySlug;

  const SubChildCategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.childcategoryId,
    required this.childcategoryName,
    this.parentSubchildcategoryId,
    this.parentSubchildcategoryName,
    this.subcategorySlug,
    this.childcategorySlug,
    this.parentSubchildcategorySlug,
  });

  @override
  State<SubChildCategoryPage> createState() => _SubChildCategoryPageState();
}

class _SubChildCategoryPageState extends State<SubChildCategoryPage> {
  final HomepageService _homepageService = HomepageService();
  List<SubChildCategory> _subchildcategories = [];
  Map<int, SubChildCategory> _subChildCategoryDetails =
      {}; // Cache subchildcategory details with nested subchildcategories
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchChildcategoryDetails();
  }

  Future<void> _fetchChildcategoryDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<SubChildCategory> subchildcategoriesList = [];

      // If parentSubchildcategoryId is provided, fetch nested subchildcategories
      if (widget.parentSubchildcategoryId != null) {
        Logger.info(
          'Fetching nested subchildcategory details for ID: ${widget.parentSubchildcategoryId}',
        );
        final parentSubchildcategory = await _homepageService
            .getSubchildcategoryDetails(widget.parentSubchildcategoryId!);
        subchildcategoriesList =
            parentSubchildcategory.subchildcategories ?? [];
      } else {
        // Otherwise, fetch subchildcategories from childcategory
        Logger.info(
          'Fetching childcategory details for ID: ${widget.childcategoryId}',
        );
        final childcategory = await _homepageService.getChildcategoryDetails(
          widget.childcategoryId,
        );
        subchildcategoriesList = childcategory.subchildcategories ?? [];
      }

      // Fetch full details for each subchildcategory to get nested subchildcategories
      List<SubChildCategory> subchildcategoriesWithDetails = [];
      for (var subchildcategory in subchildcategoriesList) {
        try {
          final subchildcategoryDetails = await _homepageService
              .getSubchildcategoryDetails(subchildcategory.id);
          subchildcategoriesWithDetails.add(subchildcategoryDetails);
          _subChildCategoryDetails[subchildcategory.id] =
              subchildcategoryDetails;
        } catch (e) {
          Logger.warning(
            'Failed to fetch details for subchildcategory ${subchildcategory.id}, using basic info',
          );
          subchildcategoriesWithDetails.add(subchildcategory);
        }
      }

      setState(() {
        _subchildcategories = subchildcategoriesWithDetails;
        _isLoading = false;
      });

      Logger.info(
        'Loaded ${_subchildcategories.length} subchildcategories with details',
      );
    } catch (e) {
      Logger.error('Failed to load subchildcategory details', e);
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to load sub-child categories. Please try again.';
      });
    }
  }

  void _navigateToSubchildcategory(SubChildCategory subchildcategory) {
    // Get full details if available (with nested subchildcategories)
    final subchildcategoryDetails =
        _subChildCategoryDetails[subchildcategory.id] ?? subchildcategory;

    // If subchildcategory has nested subchildcategories, show them in a new page
    if (subchildcategoryDetails.hasSubchildcategories &&
        subchildcategoryDetails.subchildcategories != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubChildCategoryPage(
            categoryId: widget.categoryId,
            categoryName: widget.categoryName,
            subcategoryId: widget.subcategoryId,
            subcategoryName: widget.subcategoryName,
            childcategoryId: widget.childcategoryId,
            childcategoryName: widget.childcategoryName,
            parentSubchildcategoryId: subchildcategory.id,
            parentSubchildcategoryName: subchildcategory.name,
            subcategorySlug: widget.subcategorySlug,
            childcategorySlug: widget.childcategorySlug,
            parentSubchildcategorySlug: subchildcategory.slug,
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
            childcategoryId: widget.childcategoryId,
            subchildcategoryId: subchildcategory.id,
            categorySlug:
                subchildcategory.slug ?? widget.parentSubchildcategorySlug,
            categoryType: 'childsubcategory',
            title: subchildcategory.name,
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
          widget.parentSubchildcategoryName ?? widget.childcategoryName,
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
              onPressed: _fetchChildcategoryDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // If no subchildcategories, navigate directly to products
    if (_subchildcategories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductListScreen(
              categoryId: widget.categoryId,
              subcategoryId: widget.subcategoryId,
              childcategoryId: widget.childcategoryId,
              categorySlug: widget.childcategorySlug,
              categoryType: 'childcategory',
              title: widget.childcategoryName,
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
            itemCount: _subchildcategories.length,
            itemBuilder: (context, index) {
              final subchildcategory = _subchildcategories[index];
              return CategoryTile(
                name: subchildcategory.name,
                image: subchildcategory.image,
                onTap: () => _navigateToSubchildcategory(subchildcategory),
              );
            },
          ),
        ),
      ),
    );
  }
}
