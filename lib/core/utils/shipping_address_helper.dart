/// Builds the combined `shipping_address` string for cart/order APIs.
///
/// Format: address, city, state, zip code
class ShippingAddressHelper {
  static String fromCheckout(Map<String, dynamic>? checkoutData) {
    if (checkoutData == null) return '';

    final shippingMethod =
        checkoutData['shipping_method']?.toString() ?? 'Ship to Address';
    if (shippingMethod == 'Pickup') return '';

    return _joinParts(
      address: checkoutData['address'],
      city: checkoutData['suburb'],
      state: checkoutData['state'],
      zip: checkoutData['post_code'],
    );
  }

  static String fromOrder(Map<String, dynamic>? orderData) {
    if (orderData == null) return '';

    final order = orderData['order'] is Map<String, dynamic>
        ? orderData['order'] as Map<String, dynamic>
        : orderData;

    final existing = order['shipping_address']?.toString().trim();
    if (existing != null && existing.isNotEmpty) return existing;

    return _joinParts(
      address: order['shipping_address'] ?? order['address'] ?? order['customer_address'],
      city: order['shipping_city'] ?? order['city'] ?? order['customer_city'],
      state: order['shipping_state'] ?? order['state'] ?? order['customer_state'],
      zip: order['shipping_zip'] ?? order['zip'] ?? order['customer_zip'],
    );
  }

  static String _joinParts({
    required dynamic address,
    required dynamic city,
    required dynamic state,
    required dynamic zip,
  }) {
    return [address, city, state, zip]
        .map((part) => part?.toString().trim() ?? '')
        .where((part) => part.isNotEmpty)
        .join(', ');
  }
}
