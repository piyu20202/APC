import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../data/models/settings_model.dart';
import '../services/user_role_service.dart';

class StorageService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyTokenType = 'token_type';
  static const String _keyUserData = 'user_data';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keySettingsData = 'settings_data';
  static const String _keyCartData = 'cart_data';
  static const String _keyPaymentCartSnapshot = 'payment_cart_snapshot';
  static const String _keyCheckoutData = 'checkout_data';
  static const String _keyOrderData = 'order_data';

  /// Save login response data to SharedPreferences
  static Future<void> saveLoginData(LoginResponse response) async {
    final prefs = await SharedPreferences.getInstance();

    // Save access token
    await prefs.setString(_keyAccessToken, response.accessToken);

    // Save token type
    await prefs.setString(_keyTokenType, response.tokenType);

    // Save user data as JSON string
    final userJson = jsonEncode(response.user.toJson());
    await prefs.setString(_keyUserData, userJson);

    // Save login status
    await prefs.setBool(_keyIsLoggedIn, true);

    // Sync trader status from user model
    await UserRoleService.setIsTraderUser(response.user.isTradeUser == 1);
  }

  /// Get access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  /// Get token type
  static Future<String?> getTokenType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTokenType);
  }

  /// Get bearer token (token type + access token)
  static Future<String?> getBearerToken() async {
    final tokenType = await getTokenType() ?? 'Bearer';
    final accessToken = await getAccessToken();
    if (accessToken != null) {
      return '$tokenType $accessToken';
    }
    return null;
  }

  /// Get user data
  static Future<UserModel?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyUserData);

    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Clear all login data (logout)
  static Future<void> clearLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyTokenType);
    await prefs.remove(_keyUserData);
    await prefs.setBool(_keyIsLoggedIn, false);

    // Sync trader status (clear it)
    await UserRoleService.removeTraderStatus();
  }

  /// Get complete login response
  static Future<LoginResponse?> getLoginResponse() async {
    final accessToken = await getAccessToken();
    final tokenType = await getTokenType();
    final user = await getUserData();

    if (accessToken != null && tokenType != null && user != null) {
      return LoginResponse(
        accessToken: accessToken,
        tokenType: tokenType,
        user: user,
      );
    }
    return null;
  }

  // ============ Settings Storage Methods ============

  /// Save settings data to SharedPreferences
  static Future<void> saveSettings(SettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = jsonEncode(settings.toJson());
    await prefs.setString(_keySettingsData, settingsJson);
  }

  /// Get settings data from SharedPreferences
  static Future<SettingsModel?> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_keySettingsData);

    if (settingsJson != null) {
      try {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        return SettingsModel.fromJson(settingsMap);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Clear settings data
  static Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySettingsData);
  }

  // ============ Cart Storage Methods ============

  /// Save cart response, injecting listing-product freight flags into the
  /// matching cart entry so they survive through checkout → payment page.
  ///
  /// [listingProduct] is the raw product map from the listing / detail screen
  /// (must contain `id`, `show_free_shipping_icon`, `show_freight_cost_icon`,
  /// `show_request_freight_cost`, and `product_sizeType`).
  static Future<void> saveCartDataWithProductHints(
    Map<String, dynamic> cartResponse, {
    required Map<String, dynamic> listingProduct,
  }) async {
    final productId = listingProduct['id'];
    final cart = cartResponse['cart'];

    if (productId != null && cart is Map) {
      final enrichedCart = <String, dynamic>{};

      (cart as Map).forEach((key, val) {
        if (val is Map && key.toString().startsWith('${productId}_')) {
          final entry = Map<String, dynamic>.from(val as Map);

          void injectIfAbsent(String field) {
            final v = listingProduct[field];
            if (v != null) {
              entry[field] ??= v;
              final itemRaw = entry['item'];
              if (itemRaw is Map) {
                final item = Map<String, dynamic>.from(itemRaw as Map);
                item[field] ??= v;
                entry['item'] = item;
              }
            }
          }

          injectIfAbsent('show_free_shipping_icon');
          injectIfAbsent('show_freight_cost_icon');
          injectIfAbsent('show_request_freight_cost');
          injectIfAbsent('product_sizeType');

          enrichedCart[key] = entry;
        } else {
          enrichedCart[key] = val;
        }
      });

      cartResponse = {...cartResponse, 'cart': enrichedCart};
    }

    return saveCartData(cartResponse);
  }

  /// Save cart response data to SharedPreferences
  static Future<void> saveCartData(Map<String, dynamic> cartResponse) async {
    // CRITICAL GUARD: Prevent any "paylater" or payment data from overwriting cart.
    // Cart should only contain 'cart', 'discount', 'coupon_discount', 'totalPrice', etc.
    // If response contains payment-specific fields, reject it to protect Pay Later flow.
    if (cartResponse.containsKey('paylater') || 
        cartResponse.containsKey('payment_method') || 
        cartResponse.containsKey('manual_order_by_admin')) {
      debugPrint('SECURITY: Rejected saveCartData() - contains payment data instead of cart data');
      return; // Reject this save to prevent cart corruption
    }
    
    final prefs = await SharedPreferences.getInstance();
    final cartJson = jsonEncode(cartResponse);
    await prefs.setString(_keyCartData, cartJson);
  }

  /// Get cart response data from SharedPreferences
  static Future<Map<String, dynamic>?> getCartData() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_keyCartData);

    if (cartJson != null) {
      try {
        final cartMap = jsonDecode(cartJson) as Map<String, dynamic>;
        return cartMap;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Clear cart data
  static Future<void> clearCartData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCartData);
  }

  /// Save temporary payment cart snapshot (for payment-page-only operations)
  static Future<void> savePaymentCartSnapshot(
    Map<String, dynamic> cartResponse,
  ) async {
    if (cartResponse['cart'] == null || cartResponse['cart'] is! Map) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final snapshot = <String, dynamic>{
      ...cartResponse,
      'snapshot_created_at_ms': DateTime.now().millisecondsSinceEpoch,
    };
    final snapJson = jsonEncode(snapshot);
    await prefs.setString(_keyPaymentCartSnapshot, snapJson);
  }

  /// Get temporary payment cart snapshot
  static Future<Map<String, dynamic>?> getPaymentCartSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final snapJson = prefs.getString(_keyPaymentCartSnapshot);

    if (snapJson != null) {
      try {
        final snapMap = jsonDecode(snapJson) as Map<String, dynamic>;
        return snapMap;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Clear temporary payment cart snapshot
  static Future<void> clearPaymentCartSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPaymentCartSnapshot);
  }

  // ============ Checkout Storage Methods ============

  /// Save checkout form data to SharedPreferences
  static Future<void> saveCheckoutData(
    Map<String, dynamic> checkoutData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final checkoutJson = jsonEncode(checkoutData);
    await prefs.setString(_keyCheckoutData, checkoutJson);
  }

  /// Get checkout form data from SharedPreferences
  static Future<Map<String, dynamic>?> getCheckoutData() async {
    final prefs = await SharedPreferences.getInstance();
    final checkoutJson = prefs.getString(_keyCheckoutData);

    if (checkoutJson != null) {
      try {
        final checkoutMap = jsonDecode(checkoutJson) as Map<String, dynamic>;
        return checkoutMap;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Clear checkout data
  static Future<void> clearCheckoutData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCheckoutData);
  }

  // ============ Order Storage Methods ============

  /// Save order response data to SharedPreferences
  static Future<void> saveOrderData(Map<String, dynamic> orderResponse) async {
    final prefs = await SharedPreferences.getInstance();
    final orderJson = jsonEncode(orderResponse);
    await prefs.setString(_keyOrderData, orderJson);
  }

  /// Get order response data from SharedPreferences
  static Future<Map<String, dynamic>?> getOrderData() async {
    final prefs = await SharedPreferences.getInstance();
    final orderJson = prefs.getString(_keyOrderData);

    if (orderJson != null) {
      try {
        final orderMap = jsonDecode(orderJson) as Map<String, dynamic>;
        return orderMap;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Clear stored order data
  static Future<void> clearOrderData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOrderData);
  }

  /// Clear all data including login, settings, cart, checkout and order (complete logout)
  static Future<void> clearAllData() async {
    await clearLoginData();
    await clearSettings();
    await clearCartData();
    await clearPaymentCartSnapshot();
    await clearCheckoutData();
    await clearOrderData();
  }
}
