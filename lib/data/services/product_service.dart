import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/utils/logger.dart';
import '../models/product_detail_response.dart';

class ProductService {
  /// Fetch product details from the server
  Future<ProductDetailResponse> getProductDetails(int productId) async {
    try {
      Logger.info('Fetching product details for product ID: $productId');

      Map<String, dynamic> response;
      try {
        Logger.info(
          'Full URL: ${ApiEndpoints.baseUrl}${ApiEndpoints.productDetails}?product_id=$productId',
        );
        response = await ApiClient.get(
          endpoint: ApiEndpoints.productDetails,
          queryParameters: {'product_id': productId.toString()},
          requireAuth: false,
        );
      } on ApiException catch (primaryError) {
        Logger.warning(
          'Primary product details request failed (${primaryError.statusCode}). '
          'Falling back to legacy path format.',
        );
        response = await ApiClient.get(
          endpoint: '${ApiEndpoints.productDetails}/$productId',
          requireAuth: false,
        );
      }

      Logger.info('Product details response received');
      Logger.info('Response keys: ${response.keys.join(", ")}');

      // Extract product from response and map to strongly typed objects
      if (response.containsKey('products') && response['products'] != null) {
        Logger.info('Product found in response');
        try {
          final productDetail = ProductDetailResponse.fromJson(response);
          Logger.info('Successfully parsed product: ${productDetail.product.name}');
          Logger.info(
            'Kit includes (one/two): ${productDetail.kitIncludesOne.length} / ${productDetail.kitIncludesTwo.length}',
          );
          Logger.info(
            'Qty upgrade products: ${productDetail.qtyUpgradeProducts.length}',
          );
          Logger.info(
            'Upgrade products: ${productDetail.upgradeProducts.length}',
          );
          return productDetail;
        } catch (e, stackTrace) {
          Logger.error('Error parsing product details response', e);
          Logger.error('Stack trace', null, stackTrace);
          throw ApiException(
            message: 'Failed to parse product details: ${e.toString()}',
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

