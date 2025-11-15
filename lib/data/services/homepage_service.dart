import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/utils/logger.dart';
import '../../core/services/categories_cache_service.dart';
import '../models/homepage_model.dart';
import '../models/categories_model.dart';

/// Helper class to store category structure information
class CategoryStructure {
  final bool hasSubcategories;
  final bool hasChildcategories;

  CategoryStructure({
    required this.hasSubcategories,
    required this.hasChildcategories,
  });
}

class HomepageService {
  // Set this to true to use dummy data for testing
  static const bool useDummyData = false;

  // Category name to structure mapping for dummy data
  CategoryStructure _getCategoryStructure(String categoryName) {
    final normalizedName = categoryName.toLowerCase().trim();
    
    if (normalizedName.contains('remote')) {
      return CategoryStructure(hasSubcategories: true, hasChildcategories: true);
    } else if (normalizedName.contains('video intercom') || 
               normalizedName.contains('video intercom system')) {
      return CategoryStructure(hasSubcategories: true, hasChildcategories: false);
    }
    
    // Default: no subcategories
    return CategoryStructure(hasSubcategories: false, hasChildcategories: false);
  }

  /// Generate dummy category data for testing
  Category _generateDummyCategory(
    int id,
    String name, {
    bool hasSubcategories = false,
    bool hasChildcategories = false,
  }) {
    return Category(
      id: id,
      name: name,
      image: 'assets/images/product${id % 5}.png',
      pageOpen: hasSubcategories ? 'landing_page' : 'product_listing_page',
      subcategories: hasSubcategories ? _generateDummySubcategories(id, name, hasChildcategories: hasChildcategories) : null,
    );
  }

  List<SubCategory> _generateDummySubcategories(int categoryId, String categoryName, {bool hasChildcategories = false}) {
    final normalizedCategoryName = categoryName.toLowerCase().trim();
    final isRemoteCategory = normalizedCategoryName.contains('remote');
    
    return [
      SubCategory(
        id: categoryId * 10 + 1,
        name: 'SubCategory ${categoryId}-1',
        image: 'assets/images/product${(categoryId * 10 + 1) % 5}.png',
        categoryId: categoryId,
        // All subcategories of Remote category have childcategories
        // Some childcategories will have subchildcategories for testing
        childcategories: (hasChildcategories && isRemoteCategory) 
            ? _generateDummyChildcategories(categoryId * 10 + 1, hasSubchildcategories: true) 
            : null,
      ),
      SubCategory(
        id: categoryId * 10 + 2,
        name: 'SubCategory ${categoryId}-2',
        image: 'assets/images/product${(categoryId * 10 + 2) % 5}.png',
        categoryId: categoryId,
        // All subcategories of Remote category have childcategories
        // Some childcategories will have subchildcategories for testing
        childcategories: (hasChildcategories && isRemoteCategory) 
            ? _generateDummyChildcategories(categoryId * 10 + 2, hasSubchildcategories: true) 
            : null,
      ),
    ];
  }

  List<ChildCategory> _generateDummyChildcategories(int subcategoryId, {bool hasSubchildcategories = false}) {
    return [
      ChildCategory(
        id: subcategoryId * 10 + 1,
        name: 'ChildCategory ${subcategoryId}-1',
        image: 'assets/images/product${(subcategoryId * 10 + 1) % 5}.png',
        subcategoryId: subcategoryId,
        categoryId: (subcategoryId ~/ 10),
        subchildcategories: hasSubchildcategories ? _generateDummySubchildcategories(subcategoryId * 10 + 1) : null,
      ),
      ChildCategory(
        id: subcategoryId * 10 + 2,
        name: 'ChildCategory ${subcategoryId}-2',
        image: 'assets/images/product${(subcategoryId * 10 + 2) % 5}.png',
        subcategoryId: subcategoryId,
        categoryId: (subcategoryId ~/ 10),
        subchildcategories: hasSubchildcategories ? _generateDummySubchildcategories(subcategoryId * 10 + 2) : null,
      ),
    ];
  }

  List<SubChildCategory> _generateDummySubchildcategories(int childcategoryId, {bool hasNestedSubchildcategories = false}) {
    // If hasNestedSubchildcategories is true, only return the first subchildcategory
    // which will have the second one nested under it
    if (hasNestedSubchildcategories) {
      return [
        SubChildCategory(
          id: childcategoryId * 10 + 1,
          name: 'SubChildCategory ${childcategoryId}-1',
          image: 'assets/images/product${(childcategoryId * 10 + 1) % 5}.png',
          childcategoryId: childcategoryId,
          subcategoryId: (childcategoryId ~/ 10),
          categoryId: (childcategoryId ~/ 100),
          // First subchildcategory has the second one nested under it
          subchildcategories: _generateNestedSubchildcategories(childcategoryId * 10 + 1),
        ),
      ];
    }
    
    // Otherwise, return both as siblings
    return [
      SubChildCategory(
        id: childcategoryId * 10 + 1,
        name: 'SubChildCategory ${childcategoryId}-1',
        image: 'assets/images/product${(childcategoryId * 10 + 1) % 5}.png',
        childcategoryId: childcategoryId,
        subcategoryId: (childcategoryId ~/ 10),
        categoryId: (childcategoryId ~/ 100),
      ),
      SubChildCategory(
        id: childcategoryId * 10 + 2,
        name: 'SubChildCategory ${childcategoryId}-2',
        image: 'assets/images/product${(childcategoryId * 10 + 2) % 5}.png',
        childcategoryId: childcategoryId,
        subcategoryId: (childcategoryId ~/ 10),
        categoryId: (childcategoryId ~/ 100),
      ),
    ];
  }

  List<SubChildCategory> _generateNestedSubchildcategories(int subchildcategoryId) {
    // Generate the second subchildcategory (e.g., 1511-2) nested under the first one (e.g., 1511-1)
    // The parent subchildcategory ID is like 15111, so we need to generate 15112
    // But we want it to be named "1511-2", so we calculate it differently
    final parentChildcategoryId = subchildcategoryId ~/ 10; // e.g., 1511 from 15111
    final nestedSubchildcategoryId = parentChildcategoryId * 10 + 2; // e.g., 15112
    
    return [
      SubChildCategory(
        id: nestedSubchildcategoryId,
        name: 'SubChildCategory ${parentChildcategoryId}-2',
        image: 'assets/images/product${nestedSubchildcategoryId % 5}.png',
        childcategoryId: parentChildcategoryId,
        subcategoryId: (parentChildcategoryId ~/ 10),
        categoryId: (parentChildcategoryId ~/ 100),
      ),
    ];
  }

  List<LatestProduct> _generateDummyProducts({
    int? categoryId,
    int? subcategoryId,
    int? childcategoryId,
    int? subchildcategoryId,
  }) {
    final List<LatestProduct> products = [];
    final baseId = subchildcategoryId ?? childcategoryId ?? subcategoryId ?? categoryId ?? 1;
    
    for (int i = 1; i <= 8; i++) {
      products.add(
        LatestProduct(
          id: baseId * 100 + i,
          sku: 'SKU-${baseId}-$i',
          name: 'Product ${baseId}-$i - Sample Product Item',
          slug: 'product-$baseId-$i',
          thumbnail: 'assets/images/product${i % 5}.png',
          price: 100.0 + (i * 25),
          previousPrice: 150.0 + (i * 30),
          status: 1,
          outOfStock: 0,
          tags: 'tag1, tag2',
          features: 'Feature 1, Feature 2',
          isKit: null,
          createdAt: DateTime.now().toString(),
          slugUrl: '/product-$baseId-$i',
          shortDescription: 'This is a sample product description for testing purposes.',
        ),
      );
    }
    return products;
  }
  /// Fetch homepage data from the server
  Future<HomepageModel> getHomepageData() async {
    try {
      Logger.info('Fetching homepage data from server');
      Logger.info(
        'Full URL: ${ApiEndpoints.baseUrl}${ApiEndpoints.homepageSettings}',
      );

      final response = await ApiClient.get(
        endpoint: ApiEndpoints.homepageSettings,
        requireAuth: false,
      );

      Logger.info('Response received');
      Logger.info('Response type: ${response.runtimeType}');
      Logger.info('Response is empty: ${response.isEmpty}');
      Logger.info('Response keys: ${response.keys.join(", ")}');

      // Extract categories directly
      List<Category> categories = [];
      if (response.containsKey('categories') &&
          response['categories'] != null) {
        Logger.info('Categories found');
        final categoriesData = response['categories'];
        Logger.info('Categories data type: ${categoriesData.runtimeType}');

        if (categoriesData is List) {
          Logger.info(
            'Categories is a list with ${categoriesData.length} items',
          );

          // Parse each category item
          for (var i = 0; i < categoriesData.length; i++) {
            final item = categoriesData[i];
            if (item == null) {
              Logger.warning('Category item at index $i is null - skipping');
              continue;
            }

            if (item is! Map<String, dynamic>) {
              Logger.warning(
                'Category item at index $i is not a Map: ${item.runtimeType}',
              );
              continue;
            }

            try {
              final category = Category.fromJson(item);
              categories.add(category);
              Logger.info('Successfully parsed category: ${category.name}');
            } catch (e) {
              Logger.error('Error parsing category at index $i', e);
            }
          }
        }
      } else {
        Logger.warning('Categories key not found or is null');
        Logger.info('Available keys: ${response.keys.join(", ")}');
      }

      Logger.info('Total categories parsed: ${categories.length}');

      // Extract partners
      List<Partner> partners = [];
      if (response.containsKey('partners') && response['partners'] != null) {
        Logger.info('Partners found');
        final partnersData = response['partners'];

        if (partnersData is List) {
          Logger.info('Partners is a list with ${partnersData.length} items');

          for (var i = 0; i < partnersData.length; i++) {
            final item = partnersData[i];
            if (item == null) {
              Logger.warning('Partner item at index $i is null - skipping');
              continue;
            }

            if (item is! Map<String, dynamic>) {
              Logger.warning(
                'Partner item at index $i is not a Map: ${item.runtimeType}',
              );
              continue;
            }

            try {
              final partner = Partner.fromJson(item);
              partners.add(partner);
              Logger.info('Successfully parsed partner: ID ${partner.id}');
            } catch (e) {
              Logger.error('Error parsing partner at index $i', e);
            }
          }
        }
      } else {
        Logger.warning('Partners key not found or is null');
      }

      Logger.info('Total partners parsed: ${partners.length}');

      // Extract services
      List<Service> services = [];
      if (response.containsKey('services') && response['services'] != null) {
        Logger.info('Services found');
        final servicesData = response['services'];

        if (servicesData is List) {
          Logger.info('Services is a list with ${servicesData.length} items');

          for (var i = 0; i < servicesData.length; i++) {
            final item = servicesData[i];
            if (item == null) {
              Logger.warning('Service item at index $i is null - skipping');
              continue;
            }

            if (item is! Map<String, dynamic>) {
              Logger.warning(
                'Service item at index $i is not a Map: ${item.runtimeType}',
              );
              continue;
            }

            try {
              final service = Service.fromJson(item);
              services.add(service);
              Logger.info('Successfully parsed service: ${service.title}');
            } catch (e) {
              Logger.error('Error parsing service at index $i', e);
            }
          }
        }
      } else {
        Logger.warning('Services key not found or is null');
      }

      Logger.info('Total services parsed: ${services.length}');

      // Extract latest products
      List<LatestProduct> latestProducts = [];
      if (response.containsKey('latest_products') &&
          response['latest_products'] != null) {
        Logger.info('Latest products found');
        final productsData = response['latest_products'];
        if (productsData is List) {
          for (var i = 0; i < productsData.length; i++) {
            final item = productsData[i];
            if (item is Map<String, dynamic>) {
              try {
                latestProducts.add(LatestProduct.fromJson(item));
              } catch (e) {
                Logger.error('Error parsing latest product at index $i', e);
              }
            }
          }
        }
      } else {
        Logger.warning('latest_products key not found or is null');
      }

      // Return HomepageModel with categories, partners, and services
      final homepageModel = HomepageModel(
        partners: partners,
        services: services,
        sliders: [],
        allBanners: [],
        categories: categories,
        latestProducts: latestProducts,
      );
      Logger.info(
        'Parsed categories count: ${homepageModel.categories.length}',
      );

      if (homepageModel.categories.isEmpty) {
        Logger.warning('Categories list is empty after parsing');
      }

      return homepageModel;
    } on ApiException catch (e) {
      Logger.error('API Exception: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to fetch homepage data', e);
      Logger.error('Stack trace', null, stackTrace);
      Logger.info('Exception type: ${e.runtimeType}');
      Logger.info('Exception message: $e');
      throw ApiException(
        message: 'Failed to fetch homepage data: ${e.toString()}',
      );
    }
  }

  /// Fetch latest products from the server
  Future<List<LatestProduct>> getLatestProducts() async {
    try {
      Logger.info('Fetching latest products from server');

      final response = await ApiClient.get(
        endpoint: ApiEndpoints.latestProducts,
        requireAuth: false,
      );

      Logger.info('Latest products response received');
      Logger.info('Response keys: ${response.keys.join(", ")}');

      List<LatestProduct> latestProducts = [];

      if (response.containsKey('latest_products') &&
          response['latest_products'] != null) {
        Logger.info('Latest products found in response');
        final productsData = response['latest_products'];

        if (productsData is List) {
          Logger.info(
            'Latest products is a list with ${productsData.length} items',
          );

          for (var i = 0; i < productsData.length; i++) {
            final item = productsData[i];
            if (item == null) {
              Logger.warning('Latest product at index $i is null - skipping');
              continue;
            }

            if (item is! Map<String, dynamic>) {
              Logger.warning(
                'Latest product at index $i is not a Map: ${item.runtimeType}',
              );
              continue;
            }

            try {
              final product = LatestProduct.fromJson(item);
              latestProducts.add(product);
              Logger.info(
                'Successfully parsed latest product: ${product.name}',
              );
            } catch (e) {
              Logger.error('Error parsing latest product at index $i', e);
            }
          }
        }
      } else {
        Logger.warning('latest_products key not found or is null in response');
      }

      Logger.info('Total latest products parsed: ${latestProducts.length}');
      return latestProducts;
    } on ApiException catch (e) {
      Logger.error('API Exception fetching latest products: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to fetch latest products', e);
      Logger.error('Stack trace', null, stackTrace);
      throw ApiException(
        message: 'Failed to fetch latest products: ${e.toString()}',
      );
    }
  }

  /// Fetch sale products from the server
  Future<List<LatestProduct>> getSaleProducts() async {
    try {
      Logger.info('Fetching sale products from server');

      final response = await ApiClient.get(
        endpoint: ApiEndpoints.saleProducts,
        requireAuth: false,
      );

      Logger.info('Sale products response received');
      Logger.info('Response keys: ${response.keys.join(", ")}');

      List<LatestProduct> saleProducts = [];

      if (response.containsKey('sale_products') &&
          response['sale_products'] != null) {
        Logger.info('sale_products found in response');
        final productsData = response['sale_products'];

        if (productsData is List) {
          Logger.info(
            'Sale products is a list with ${productsData.length} items',
          );

          for (var i = 0; i < productsData.length; i++) {
            final item = productsData[i];
            if (item == null) {
              Logger.warning('Sale product at index $i is null - skipping');
              continue;
            }

            if (item is! Map<String, dynamic>) {
              Logger.warning(
                'Sale product at index $i is not a Map: ${item.runtimeType}',
              );
              continue;
            }

            try {
              final product = LatestProduct.fromJson(item);
              saleProducts.add(product);
              Logger.info('Parsed sale product: ${product.name}');
            } catch (e) {
              Logger.error('Error parsing sale product at index $i', e);
            }
          }
        }
      } else {
        Logger.warning('sale_products key not found or is null in response');
      }

      Logger.info('Total sale products parsed: ${saleProducts.length}');
      return saleProducts;
    } on ApiException catch (e) {
      Logger.error('API Exception fetching sale products: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to fetch sale products', e, stackTrace);
      throw ApiException(
        message: 'Failed to fetch sale products: ${e.toString()}',
      );
    }
  }

  /// Search products from the server
  Future<List<LatestProduct>> searchProducts({
    required String searchKeyword,
    String? page,
    String? perPage,
  }) async {
    try {
      Logger.info('Searching products with keyword: $searchKeyword');

      // Build query parameters
      final queryParameters = <String, String>{
        'search_keyword': searchKeyword,
      };
      if (page != null && page.isNotEmpty) {
        queryParameters['page'] = page;
      }
      if (perPage != null && perPage.isNotEmpty) {
        queryParameters['per_page'] = perPage;
      }

      final response = await ApiClient.get(
        endpoint: ApiEndpoints.searchProducts,
        queryParameters: queryParameters,
        requireAuth: false,
      );

      Logger.info('Search products response received');
      Logger.info('Response keys: ${response.keys.join(", ")}');

      List<LatestProduct> searchResults = [];

      if (response.containsKey('products') && response['products'] != null) {
        Logger.info('Products found in response');
        final productsData = response['products'];

        if (productsData is List) {
          Logger.info(
            'Products is a list with ${productsData.length} items',
          );

          for (var i = 0; i < productsData.length; i++) {
            final item = productsData[i];
            if (item == null) {
              Logger.warning('Product at index $i is null - skipping');
              continue;
            }

            if (item is! Map<String, dynamic>) {
              Logger.warning(
                'Product at index $i is not a Map: ${item.runtimeType}',
              );
              continue;
            }

            try {
              final product = LatestProduct.fromJson(item);
              searchResults.add(product);
              Logger.info('Successfully parsed product: ${product.name}');
            } catch (e) {
              Logger.error('Error parsing product at index $i', e);
            }
          }
        }
      } else {
        Logger.warning('products key not found or is null in response');
      }

      Logger.info('Total search products parsed: ${searchResults.length}');
      return searchResults;
    } on ApiException catch (e) {
      Logger.error('API Exception searching products: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to search products', e, stackTrace);
      throw ApiException(
        message: 'Failed to search products: ${e.toString()}',
      );
    }
  }

  /// Fetch category details with subcategories
  Future<Category> getCategoryDetails(int categoryId) async {
    try {
      Logger.info('Fetching category details for ID: $categoryId');

      // Use dummy data for testing
      if (useDummyData) {
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
        Logger.info('Using dummy data for category details');
        
        // Try to get category name from homepage data first
        String categoryName = 'Category $categoryId';
        try {
          final homepageData = await getHomepageData();
          final category = homepageData.categories.firstWhere(
            (cat) => cat.id == categoryId,
            orElse: () => Category(id: categoryId, name: categoryName),
          );
          categoryName = category.name;
        } catch (e) {
          Logger.warning('Could not get category name from homepage, using default');
        }
        
        // Check category structure based on name
        final structure = _getCategoryStructure(categoryName);
        
        return _generateDummyCategory(
          categoryId,
          categoryName,
          hasSubcategories: structure.hasSubcategories,
          hasChildcategories: structure.hasChildcategories,
        );
      }

      final response = await ApiClient.get(
        endpoint: ApiEndpoints.categoryDetails,
        queryParameters: {'category_id': categoryId.toString()},
        requireAuth: false,
      );

      Logger.info('Category details response received');

      if (response.containsKey('category') && response['category'] != null) {
        return Category.fromJson(response['category'] as Map<String, dynamic>);
      }

      throw ApiException(message: 'Category details not found');
    } on ApiException catch (e) {
      Logger.error('API Exception fetching category details: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to fetch category details', e, stackTrace);
      throw ApiException(
        message: 'Failed to fetch category details: ${e.toString()}',
      );
    }
  }

  /// Fetch subcategory details with childcategories
  Future<SubCategory> getSubcategoryDetails(int subcategoryId) async {
    try {
      Logger.info('Fetching subcategory details for ID: $subcategoryId');

      // Use dummy data for testing
      if (useDummyData) {
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
        Logger.info('Using dummy data for subcategory details');
        
        final categoryId = subcategoryId ~/ 10;
        
        // Try to get category name to determine structure
        String categoryName = 'Category $categoryId';
        bool hasChildcategories = false;
        
        try {
          final homepageData = await getHomepageData();
          final category = homepageData.categories.firstWhere(
            (cat) => cat.id == categoryId,
            orElse: () => Category(id: categoryId, name: categoryName),
          );
          categoryName = category.name;
          
          // Check if this is "Remote" category - only Remote has childcategories
          final normalizedName = categoryName.toLowerCase().trim();
          hasChildcategories = normalizedName.contains('remote');
        } catch (e) {
          Logger.warning('Could not get category name from homepage, using default');
        }
        
        return SubCategory(
          id: subcategoryId,
          name: 'SubCategory $subcategoryId',
          image: 'assets/images/product${subcategoryId % 5}.png',
          categoryId: categoryId,
          // All subcategories of Remote category have childcategories
          childcategories: hasChildcategories ? _generateDummyChildcategories(subcategoryId) : null,
        );
      }

      final response = await ApiClient.get(
        endpoint: ApiEndpoints.subcategoryDetails,
        queryParameters: {'subcategory_id': subcategoryId.toString()},
        requireAuth: false,
      );

      Logger.info('Subcategory details response received');

      if (response.containsKey('subcategory') &&
          response['subcategory'] != null) {
        return SubCategory.fromJson(
          response['subcategory'] as Map<String, dynamic>,
        );
      }

      throw ApiException(message: 'Subcategory details not found');
    } on ApiException catch (e) {
      Logger.error('API Exception fetching subcategory details: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to fetch subcategory details', e, stackTrace);
      throw ApiException(
        message: 'Failed to fetch subcategory details: ${e.toString()}',
      );
    }
  }

  /// Fetch childcategory details
  Future<ChildCategory> getChildcategoryDetails(int childcategoryId) async {
    try {
      Logger.info('Fetching childcategory details for ID: $childcategoryId');

      // Use dummy data for testing
      if (useDummyData) {
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
        Logger.info('Using dummy data for childcategory details');
        
        final subcategoryId = childcategoryId ~/ 10;
        final categoryId = subcategoryId ~/ 10;
        
        // For testing, some childcategories have subchildcategories
        // You can modify this logic based on your needs
        final hasSubchildcategories = childcategoryId % 2 == 1; // Odd IDs have subchildcategories
        
        return ChildCategory(
          id: childcategoryId,
          name: 'ChildCategory ${subcategoryId}-${childcategoryId % 10}',
          image: 'assets/images/product${childcategoryId % 5}.png',
          subcategoryId: subcategoryId,
          categoryId: categoryId,
          subchildcategories: hasSubchildcategories 
              ? _generateDummySubchildcategories(childcategoryId, hasNestedSubchildcategories: true) 
              : null,
        );
      }

      final response = await ApiClient.get(
        endpoint: ApiEndpoints.childcategoryDetails,
        queryParameters: {'childcategory_id': childcategoryId.toString()},
        requireAuth: false,
      );

      Logger.info('Childcategory details response received');

      if (response.containsKey('childcategory') &&
          response['childcategory'] != null) {
        return ChildCategory.fromJson(
          response['childcategory'] as Map<String, dynamic>,
        );
      }

      throw ApiException(message: 'Childcategory details not found');
    } on ApiException catch (e) {
      Logger.error(
        'API Exception fetching childcategory details: ${e.message}',
      );
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to fetch childcategory details', e, stackTrace);
      throw ApiException(
        message: 'Failed to fetch childcategory details: ${e.toString()}',
      );
    }
  }

  /// Fetch subchildcategory details
  Future<SubChildCategory> getSubchildcategoryDetails(int subchildcategoryId) async {
    try {
      Logger.info('Fetching subchildcategory details for ID: $subchildcategoryId');

      // Use dummy data for testing
      if (useDummyData) {
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
        Logger.info('Using dummy data for subchildcategory details');
        
        final childcategoryId = subchildcategoryId ~/ 10;
        final subcategoryId = childcategoryId ~/ 10;
        final categoryId = subcategoryId ~/ 10;
        
        // For testing, some subchildcategories have nested subchildcategories
        // Example: subchildcategory ending in 1 (like 15111 which represents 1511-1) has nested subchildcategories
        // The nested one will be 15112 which represents 1511-2
        final hasNestedSubchildcategories = (subchildcategoryId % 10) == 1;
        
        return SubChildCategory(
          id: subchildcategoryId,
          name: 'SubChildCategory ${subchildcategoryId ~/ 10}-${subchildcategoryId % 10}',
          image: 'assets/images/product${subchildcategoryId % 5}.png',
          childcategoryId: childcategoryId,
          subcategoryId: subcategoryId,
          categoryId: categoryId,
          subchildcategories: hasNestedSubchildcategories 
              ? _generateNestedSubchildcategories(subchildcategoryId) 
              : null,
        );
      }

      final response = await ApiClient.get(
        endpoint: ApiEndpoints.subchildcategoryDetails,
        queryParameters: {'subchildcategory_id': subchildcategoryId.toString()},
        requireAuth: false,
      );

      Logger.info('Subchildcategory details response received');

      if (response.containsKey('subchildcategory') &&
          response['subchildcategory'] != null) {
        return SubChildCategory.fromJson(
          response['subchildcategory'] as Map<String, dynamic>,
        );
      }

      throw ApiException(message: 'Subchildcategory details not found');
    } on ApiException catch (e) {
      Logger.error(
        'API Exception fetching subchildcategory details: ${e.message}',
      );
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to fetch subchildcategory details', e, stackTrace);
      throw ApiException(
        message: 'Failed to fetch subchildcategory details: ${e.toString()}',
      );
    }
  }

  /// Fetch products by category ID (can be category, subcategory, childcategory, or subchildcategory)
  Future<List<LatestProduct>> getProductsByCategory({
    String? categorySlug,
    String? categoryType,
    int? page,
    int? perPage,
    int? categoryId,
    int? subcategoryId,
    int? childcategoryId,
    int? subchildcategoryId,
  }) async {
    try {
      Logger.info(
        'Fetching products by category - slug: $categorySlug, type: $categoryType, '
        'categoryId: $categoryId, subcategoryId: $subcategoryId, '
        'childcategoryId: $childcategoryId, subchildcategoryId: $subchildcategoryId',
      );

      // Use dummy data for testing
      if (useDummyData || categorySlug == null || categoryType == null) {
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
        Logger.info('Using dummy data for products by category');
        return _generateDummyProducts(
          categoryId: categoryId,
          subcategoryId: subcategoryId,
          childcategoryId: childcategoryId,
          subchildcategoryId: subchildcategoryId,
        );
      }

      final queryParameters = <String, String>{
        'category_slug': categorySlug,
        'category_type': categoryType,
      };
      if (page != null) {
        queryParameters['page'] = page.toString();
      }
      if (perPage != null) {
        queryParameters['per_page'] = perPage.toString();
      }

      final response = await ApiClient.get(
        endpoint: ApiEndpoints.productsByCategory,
        queryParameters: queryParameters,
        requireAuth: false,
      );

      Logger.info('Products by category response received');
      Logger.info('Response keys: ${response.keys.join(", ")}');

      List<LatestProduct> products = [];

      if (response.containsKey('products') && response['products'] != null) {
        final productsData = response['products'];

        if (productsData is List) {
          for (var i = 0; i < productsData.length; i++) {
            final item = productsData[i];
            if (item != null && item is Map<String, dynamic>) {
              try {
                products.add(LatestProduct.fromJson(item));
              } catch (e) {
                Logger.error('Error parsing product at index $i', e);
              }
            }
          }
        }
      }

      Logger.info('Total products parsed: ${products.length}');
      return products;
    } on ApiException catch (e) {
      Logger.error('API Exception fetching products by category: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to fetch products by category', e, stackTrace);
      throw ApiException(
        message: 'Failed to fetch products by category: ${e.toString()}',
      );
    }
  }

  /// Fetch all categories with full nested structure
  Future<List<CategoryFull>> getAllCategories() async {
    try {
      Logger.info('Fetching all categories from server');
      Logger.info(
        'Full URL: ${ApiEndpoints.baseUrl}${ApiEndpoints.allCategories}',
      );

      final response = await ApiClient.get(
        endpoint: ApiEndpoints.allCategories,
        requireAuth: false,
      );

      Logger.info('All categories response received');
      Logger.info('Response type: ${response.runtimeType}');
      Logger.info('Response keys: ${response.keys.join(", ")}');

      // Parse the response
      final categoriesResponse = CategoriesResponse.fromJson(response);
      
      Logger.info('Parsed ${categoriesResponse.categories.length} categories');

      // Cache the categories
      CategoriesCacheService().cacheCategories(categoriesResponse.categories);

      return categoriesResponse.categories;
    } on ApiException catch (e) {
      Logger.error('API Exception: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to fetch all categories', e);
      Logger.error('Stack trace', null, stackTrace);
      throw ApiException(
        message: 'Failed to fetch all categories: ${e.toString()}',
      );
    }
  }
}
