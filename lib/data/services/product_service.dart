import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/utils/logger.dart';
import '../models/product_details_model.dart';

class ProductService {
  /// Fetch product details from the server
  Future<ProductDetailsModel> getProductDetails(int productId) async {
    try {
      Logger.info('Fetching product details for product ID: $productId');
      Logger.info(
        'Full URL: ${ApiEndpoints.baseUrl}${ApiEndpoints.productDetails}/$productId',
      );

      final response = await ApiClient.get(
        endpoint: '${ApiEndpoints.productDetails}/$productId',
        requireAuth: false,
      );

      Logger.info('Product details response received');
      Logger.info('Response keys: ${response.keys.join(", ")}');

      // Extract product from response
      if (response.containsKey('products') && response['products'] != null) {
        Logger.info('Product found in response');
        final productData = response['products'];

        if (productData is Map<String, dynamic>) {
          try {
            final product = ProductDetailsModel.fromJson(productData);
            Logger.info('Successfully parsed product: ${product.name}');
            return product;
          } catch (e) {
            Logger.error('Error parsing product details', e);
            throw ApiException(
              message: 'Failed to parse product details: ${e.toString()}',
            );
          }
        } else {
          Logger.warning('Product data is not a Map: ${productData.runtimeType}');
          throw ApiException(
            message: 'Invalid product data format',
          );
        }
      } else {
        Logger.warning('products key not found or is null in response');
        throw ApiException(
          message: 'Product not found in response',
        );
      }
    } on ApiException catch (e) {
      Logger.error('API Exception fetching product details: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to fetch product details', e);
      Logger.error('Stack trace', null, stackTrace);
      throw ApiException(
        message: 'Failed to fetch product details: ${e.toString()}',
      );
    }
  }
}

