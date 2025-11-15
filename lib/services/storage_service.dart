import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../data/models/settings_model.dart';

class StorageService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyTokenType = 'token_type';
  static const String _keyUserData = 'user_data';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keySettingsData = 'settings_data';
  static const String _keyCartData = 'cart_data';

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

  /// Clear all data including login and settings (complete logout)
  static Future<void> clearAllData() async {
    await clearLoginData();
    await clearSettings();
    await clearCartData();
  }

  // ============ Cart Storage Methods ============

  /// Save cart response data to SharedPreferences
  static Future<void> saveCartData(Map<String, dynamic> cartResponse) async {
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
}
