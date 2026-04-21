import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single entry from the backend's `custom_menus` map.
class CustomMenu {
  final int id;
  final String name;
  final String type; // "custom" | "form"
  final String url;

  const CustomMenu({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
  });

  factory CustomMenu.fromJson(int id, Map<String, dynamic> json) {
    return CustomMenu(
      id: id,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'url': url,
      };

  /// Returns true when this menu should open the native Installation Manuals page.
  bool get isCustomNative => type.toLowerCase() == 'custom';

  /// Returns true when this menu should open a WebView with [url].
  bool get isForm => type.toLowerCase() == 'form';
}

/// Stores and retrieves the `custom_menus` map from SharedPreferences.
/// Key in prefs: `custom_menus_data` — stored as a JSON string.
class CustomMenuService {
  static const String _key = 'custom_menus_data';

  /// Persist the raw `custom_menus` map received from the API.
  ///
  /// Expected shape:
  /// ```json
  /// { "14": { "name": "Installation Manuals", "type": "custom", "url": "" } }
  /// ```
  static Future<void> saveCustomMenus(
    Map<String, dynamic> customMenusJson,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(customMenusJson));
  }

  /// Returns the raw custom_menus map (keyed by string IDs), or an empty map.
  static Future<Map<String, dynamic>> getRawMenus() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Looks up [categoryId] in the stored custom_menus.
  ///
  /// Returns a [CustomMenu] if a match is found, otherwise `null`.
  static Future<CustomMenu?> getMenuForCategory(int categoryId) async {
    final menus = await getRawMenus();
    final key = categoryId.toString();
    if (!menus.containsKey(key)) return null;
    final entry = menus[key];
    if (entry is! Map<String, dynamic>) return null;
    return CustomMenu.fromJson(categoryId, entry);
  }

  /// Synchronous lookup — use only after you have loaded the menus into memory.
  static CustomMenu? getMenuForCategorySync(
    int categoryId,
    Map<String, dynamic> menus,
  ) {
    final key = categoryId.toString();
    if (!menus.containsKey(key)) return null;
    final entry = menus[key];
    if (entry is! Map<String, dynamic>) return null;
    return CustomMenu.fromJson(categoryId, entry);
  }
}
