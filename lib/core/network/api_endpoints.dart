class ApiEndpoints {
  // Base URL
  static const String baseUrl =
      'https://www.gurgaonit.com/apc_production_dev/api';

  // Authentication endpoints
  static const String login = '/login';
  static const String register = '/user/register';
  static const String forgotPassword = '/forgot';
  static const String socialLogin = '/social/login';
  static const String socialRegister = '/social/register';
  static const String logout = '/logout';
  static const String changePassword = '/user/change-password';

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

  // Cart endpoints
  static const String addCartProducts = '/user/cart/add-products';
  static const String removeCartProducts = '/user/cart/remove-products';
  static const String updateCart = '/user/cart/update';
  static const String applyCoupon = '/user/cart/coupon/apply';

  // Order endpoints
  static const String storeOrder = '/user/store/order';
  static const String getUserOrders = '/user/orders';
  static const String getOrderDetails = '/user/orders/details';

  // Profile endpoints
  static const String updateProfile = '/user/profile';

  // Payment endpoints (CyberSource)
  static const String createPaymentIntent = '/user/payment/create-intent';
  static const String processPayment = '/user/payment/process';
  static const String processGooglePay = '/user/payment/process-google-pay';
  // Google Pay token -> CyberSource (base64 token payload)
  static const String googlePayToken =
      '/user/payment/cybersource/googlepay/token';
  // Apple Pay token -> CyberSource (base64 token payload)
  static const String applePayToken =
      '/user/payment/cybersource/applepay/token';
  // Card payment (raw card details payload)
  static const String cybersourceCardPayment = '/user/payment/cybersource/card';
  static const String verifyPaymentStatus = '/user/payment/verify-status';

  // PayPal payment endpoints
  static const String processPayPal = '/user/payment/paypal/process';
  static const String verifyPayPalStatus = '/user/payment/paypal/verify-status';

  // Add more endpoints here as needed
  // static const String register = '/register';
  // static const String forgotPassword = '/forgot-password';
  // static const String logout = '/logout';
}
