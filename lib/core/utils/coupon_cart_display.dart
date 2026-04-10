class CouponCartDisplay {
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(
        value.replaceAll(',', '').replaceAll(r'$', '').trim(),
      );
    }
    return null;
  }

  static String? couponCode(Map<String, dynamic>? cartResponse) {
    if (cartResponse == null) return null;

    final coupon = cartResponse['coupon'];
    if (coupon is Map<String, dynamic>) {
      final code = coupon['code']?.toString().trim();
      if (code != null && code.isNotEmpty) return code;
    }

    final directCode = cartResponse['coupon_code']?.toString().trim();
    if (directCode != null && directCode.isNotEmpty) return directCode;

    return null;
  }

  static String? offerSubtitle(Map<String, dynamic>? cartResponse) {
    if (cartResponse == null) return null;

    final coupon = cartResponse['coupon'];
    if (coupon is! Map<String, dynamic>) return null;

    final price = _toDouble(coupon['price']);
    final type = (coupon['coupon_discount_type'] ?? '')
        .toString()
        .toLowerCase()
        .trim();

    if (price == null || price <= 0) return null;

    if (type == 'percentage' || type == 'percent') {
      return '${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)}% OFF';
    }

    return '\$${price.toStringAsFixed(2)} OFF';
  }

  static double savingsFromCart(
    Map<String, dynamic>? cartResponse, {
    double? grandTotalBefore,
    double? grandTotalAfter,
  }) {
    if (grandTotalBefore != null &&
        grandTotalAfter != null &&
        grandTotalBefore > grandTotalAfter) {
      return grandTotalBefore - grandTotalAfter;
    }

    if (cartResponse == null) return 0.0;

    final discount = _toDouble(cartResponse['discount']) ?? 0.0;
    if (discount > 0) return discount;

    final couponDiscount = _toDouble(cartResponse['coupon_discount']) ?? 0.0;
    if (couponDiscount > 0) return couponDiscount;

    return 0.0;
  }
}
