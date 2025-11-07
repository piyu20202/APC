import '../../data/models/categories_model.dart';

/// Service to cache categories data in memory
class CategoriesCacheService {
  static final CategoriesCacheService _instance = CategoriesCacheService._internal();
  factory CategoriesCacheService() => _instance;
  CategoriesCacheService._internal();

  List<CategoryFull>? _cachedCategories;
  DateTime? _cacheTimestamp;

  /// Cache the categories data
  void cacheCategories(List<CategoryFull> categories) {
    _cachedCategories = categories;
    _cacheTimestamp = DateTime.now();
  }

  /// Get cached categories
  List<CategoryFull>? getCachedCategories() {
    return _cachedCategories;
  }

  /// Get a specific category by ID
  CategoryFull? getCategoryById(int categoryId) {
    if (_cachedCategories == null) return null;
    try {
      return _cachedCategories!.firstWhere(
        (cat) => cat.id == categoryId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Clear the cache
  void clearCache() {
    _cachedCategories = null;
    _cacheTimestamp = null;
  }

  /// Check if cache exists
  bool hasCache() {
    return _cachedCategories != null;
  }

  /// Get cache timestamp
  DateTime? getCacheTimestamp() {
    return _cacheTimestamp;
  }
}

