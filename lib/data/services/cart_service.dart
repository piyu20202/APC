import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/utils/logger.dart';

class CartService {
  /// Call /user/cart/add-products with the prepared payload
  Future<Map<String, dynamic>> addProducts(
    Map<String, dynamic> payload,
  ) async {
    try {
      Logger.info('Calling add-products API');
      final response = await ApiClient.post(
        endpoint: ApiEndpoints.addCartProducts,
        body: payload,
        contentType: 'application/json',
        requireAuth: false,
      );
      Logger.info('Add-products response keys: ${response.keys.join(", ")}');
      return response;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to call add-products API', e);
      Logger.error('Stack trace', null, stackTrace);
      rethrow;
    }
  }
}

