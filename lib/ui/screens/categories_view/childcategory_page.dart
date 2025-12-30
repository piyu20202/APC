import 'package:flutter/material.dart';
import '../../../data/services/homepage_service.dart';
import '../../../data/models/homepage_model.dart';
import '../../../core/utils/logger.dart';
import '../../../core/network/network_checker.dart';
import '../widget/app_state_view.dart';
import '../widget/category_tile.dart';
import '../productlist_view/productlist.dart';
import 'subchildcategory_page.dart';

class ChildCategoryPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final int subcategoryId;
  final String subcategoryName;
  final String? subcategorySlug;

  const ChildCategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryId,
    required this.subcategoryName,
    this.subcategorySlug,
  });

  @override
  State<ChildCategoryPage> createState() => _ChildCategoryPageState();
}

class _ChildCategoryPageState extends State<ChildCategoryPage> {
  final HomepageService _homepageService = HomepageService();
  List<ChildCategory> _childcategories = [];
  final Map<int, ChildCategory> _childCategoryDetails =
      {}; // Cache childcategory details with subchildcategories
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSubcategoryDetails();
  }

  Future<void> _onRefresh() async {
    final hasInternet = await NetworkChecker.hasConnection();
    if (!hasInternet) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection. Please try again.')),
        );
      }
      return;
    }
    await _fetchSubcategoryDetails();
  }

  void _viewProductsForSubcategory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductListScreen(
          categoryId: widget.categoryId,
          subcategoryId: widget.subcategoryId,
          categorySlug: widget.subcategorySlug,
          categoryType: 'subcategory',
          title: widget.subcategoryName,
        ),
      ),
    );
  }

  Future<void> _fetchSubcategoryDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Logger.info(
        'Fetching subcategory details for ID: ${widget.subcategoryId}',
      );
      final subcategory = await _homepageService.getSubcategoryDetails(
        widget.subcategoryId,
      );

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

      Logger.info(
        'Loaded ${_childcategories.length} childcategories with details',
      );
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
    final childcategoryDetails =
        _childCategoryDetails[childcategory.id] ?? childcategory;

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
            subcategorySlug: widget.subcategorySlug,
            childcategorySlug: childcategory.slug ?? childcategoryDetails.slug,
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
            categorySlug: childcategory.slug ?? childcategoryDetails.slug,
            categoryType: 'childcategory',
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
      body: RefreshIndicator.adaptive(
        onRefresh: _onRefresh,
        child: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppStateView(state: AppViewState.loading),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppStateView(
                    state: AppViewState.error,
                    title: 'Failed to load child categories',
                    message: _errorMessage,
                    primaryActionLabel: 'Retry',
                    onPrimaryAction: _fetchSubcategoryDetails,
                  ),
                )
              else if (_childcategories.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppStateView(
                    state: AppViewState.empty,
                    title: 'No child categories available',
                    message: 'You can view products directly, or pull down to refresh.',
                    primaryActionLabel: 'View products',
                    onPrimaryAction: _viewProductsForSubcategory,
                    secondaryActionLabel: 'Retry',
                    onSecondaryAction: _fetchSubcategoryDetails,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.95,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final childcategory = _childcategories[index];
                        return CategoryTile(
                          name: childcategory.name,
                          image: childcategory.image,
                          onTap: () => _navigateToChildcategory(childcategory),
                        );
                      },
                      childCount: _childcategories.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
