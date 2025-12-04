import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/utils/logger.dart';

class OrderService {
  /// Call /user/store/order to place an order
  Future<Map<String, dynamic>> storeOrder(Map<String, dynamic> payload) async {
    try {
      Logger.info('Calling store-order API');
      final response = await ApiClient.post(
        endpoint: ApiEndpoints.storeOrder,
        body: payload,
        contentType: 'application/json',
        requireAuth: true, // User must be logged in
      );
      Logger.info('Store-order response keys: ${response.keys.join(", ")}');
      return response;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to call store-order API', e);
      Logger.error('Stack trace', null, stackTrace);
      rethrow;
    }
  }
}

