import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/utils/logger.dart';

class CartService {
  /// Call /user/cart/add-products with the prepared payload
  Future<Map<String, dynamic>> addProducts(Map<String, dynamic> payload) async {
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

  /// Call /user/cart/remove-products to delete an item from the cart
  Future<Map<String, dynamic>> removeProduct({
    required int productId,
    required String oldCartJson,
  }) async {
    final body = {'id': productId, 'old_cart': oldCartJson};

    try {
      Logger.info('Calling remove-products API for item $productId');
      final response = await ApiClient.post(
        endpoint: ApiEndpoints.removeCartProducts,
        body: body,
        contentType: 'application/json',
        requireAuth: false,
      );
      Logger.info('Remove-products response keys: ${response.keys.join(", ")}');
      return response;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to call remove-products API', e);
      Logger.error('Stack trace', null, stackTrace);
      rethrow;
    }
  }

  /// Call /user/cart/update with the pending cart changes
  Future<Map<String, dynamic>> updateCart(Map<String, dynamic> payload) async {
    try {
      Logger.info('Calling update-cart API');
      final response = await ApiClient.post(
        endpoint: ApiEndpoints.updateCart,
        body: payload,
        contentType: 'application/json',
        requireAuth: false,
      );
      Logger.info('Update-cart response keys: ${response.keys.join(", ")}');
      return response;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to call update-cart API', e);
      Logger.error('Stack trace', null, stackTrace);
      rethrow;
    }
  }

  /// Call /user/cart/coupon/apply to apply a coupon or promo code
  Future<Map<String, dynamic>> applyCoupon(
    Map<String, dynamic> payload,
  ) async {
    try {
      Logger.info('Calling apply-coupon API');
      final response = await ApiClient.post(
        endpoint: ApiEndpoints.applyCoupon,
        body: payload,
        contentType: 'application/json',
        requireAuth: false,
      );
      Logger.info('Apply-coupon response keys: ${response.keys.join(", ")}');
      return response;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to call apply-coupon API', e);
      Logger.error('Stack trace', null, stackTrace);
      rethrow;
    }
  }

  /// Call /user/cart/shipping to calculate shipping, tax, and total with GST
  Future<Map<String, dynamic>> calculateShipping(
    Map<String, dynamic> payload,
  ) async {
    try {
      Logger.info('Calling calculate-shipping API');
      final response = await ApiClient.get(
        endpoint: ApiEndpoints.calculateShipping,
        body: payload,
        contentType: 'application/json',
        requireAuth: false,
      );
      Logger.info('Calculate-shipping response keys: ${response.keys.join(", ")}');
      return response;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to call calculate-shipping API', e);
      Logger.error('Stack trace', null, stackTrace);
      rethrow;
    }
  }
}
