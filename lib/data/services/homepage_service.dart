import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/utils/logger.dart';
import '../models/homepage_model.dart';

class HomepageService {
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
}
