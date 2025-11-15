class ApiEndpoints {
  // Base URL
  static const String baseUrl =
      'https://www.gurgaonit.com/apc_production_dev/api';

  // Authentication endpoints
  static const String login = '/login';

  // Settings endpoints
  static const String settings = '/settings';
  static const String homepageSettings = '/homepage-settings';

  // Latest Products endpoint
  static const String latestProducts = '/latest-products';

  // Sale Products endpoint
  static const String saleProducts = '/sale-products';

  // Search Products endpoint
  static const String searchProducts = '/search-products';

  // Product Details endpoint
  static const String productDetails = '/product-details';

  // Category Details endpoint
  static const String categoryDetails = '/category-details';

  // SubCategory Details endpoint
  static const String subcategoryDetails = '/subcategory-details';

  // ChildCategory Details endpoint
  static const String childcategoryDetails = '/childcategory-details';

  // SubChildCategory Details endpoint
  static const String subchildcategoryDetails = '/subchildcategory-details';

  // Products by Category endpoint
  static const String productsByCategory = '/get/category/products';

  // All Categories endpoint
  static const String allCategories = '/get/all_categories/';

  // Add more endpoints here as needed
  // static const String register = '/register';
  // static const String forgotPassword = '/forgot-password';
  // static const String logout = '/logout';
}
