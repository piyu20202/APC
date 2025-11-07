import '../services/homepage_service.dart';
import '../models/homepage_model.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/utils/logger.dart';

class HomepageRepository {
  final HomepageService _homepageService;

  HomepageRepository({HomepageService? homepageService})
    : _homepageService = homepageService ?? HomepageService();

  /// Get homepage data (categories, partners, services, etc.)
  Future<HomepageModel> getHomepageData() async {
    try {
      Logger.info('Repository: Fetching homepage data');
      final data = await _homepageService.getHomepageData();
      Logger.info('Repository: Homepage data fetched successfully');
      return data;
    } on ApiException {
      rethrow;
    } catch (e) {
      Logger.error('Repository: Failed to fetch homepage data', e);
      throw ApiException(
        message: 'Failed to fetch homepage data: ${e.toString()}',
      );
    }
  }

  /// Get latest products
  Future<List<LatestProduct>> getLatestProducts() async {
    try {
      Logger.info('Repository: Fetching latest products');
      final products = await _homepageService.getLatestProducts();
      Logger.info('Repository: Latest products fetched successfully');
      return products;
    } on ApiException {
      rethrow;
    } catch (e) {
      Logger.error('Repository: Failed to fetch latest products', e);
      throw ApiException(
        message: 'Failed to fetch latest products: ${e.toString()}',
      );
    }
  }

  /// Get sale products
  Future<List<LatestProduct>> getSaleProducts() async {
    try {
      Logger.info('Repository: Fetching sale products');
      final products = await _homepageService.getSaleProducts();
      Logger.info('Repository: Sale products fetched successfully');
      return products;
    } on ApiException {
      rethrow;
    } catch (e) {
      Logger.error('Repository: Failed to fetch sale products', e);
      throw ApiException(
        message: 'Failed to fetch sale products: ${e.toString()}',
      );
    }
  }

  /// Search products
  Future<List<LatestProduct>> searchProducts({
    required String searchKeyword,
    String? page,
    String? perPage,
  }) async {
    try {
      Logger.info('Repository: Searching products with keyword: $searchKeyword');
      final products = await _homepageService.searchProducts(
        searchKeyword: searchKeyword,
        page: page,
        perPage: perPage,
      );
      Logger.info('Repository: Search products fetched successfully');
      return products;
    } on ApiException {
      rethrow;
    } catch (e) {
      Logger.error('Repository: Failed to search products', e);
      throw ApiException(
        message: 'Failed to search products: ${e.toString()}',
      );
    }
  }
}
