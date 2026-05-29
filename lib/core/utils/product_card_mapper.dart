import '../../data/models/homepage_model.dart';

/// Maps [LatestProduct] to the `product` map expected by [ListingProductCard].
class ProductCardMapper {
  ProductCardMapper._();

  static List<String> parseFeatures(dynamic jsonValue) {
    if (jsonValue == null) return [];
    if (jsonValue is List) {
      return jsonValue
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (jsonValue is String && jsonValue.trim().isNotEmpty) {
      return [jsonValue.trim()];
    }
    return [];
  }

  static List<String> parseColors(dynamic jsonValue) {
    if (jsonValue == null) return [];
    if (jsonValue is List) {
      return jsonValue
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (jsonValue is String && jsonValue.trim().isNotEmpty) {
      return [jsonValue.trim()];
    }
    return [];
  }

  static dynamic _pickForFeatures({
    required bool isTradeUser,
    required dynamic features,
    required dynamic tradeFeatures,
  }) {
    if (isTradeUser) {
      return parseFeatures(tradeFeatures).isNotEmpty
          ? tradeFeatures
          : features;
    }
    return parseFeatures(features).isNotEmpty ? features : tradeFeatures;
  }

  static dynamic _pickForColors({
    required bool isTradeUser,
    required dynamic colors,
    required dynamic tradeColors,
  }) {
    if (isTradeUser) {
      return parseColors(tradeColors).isNotEmpty ? tradeColors : colors;
    }
    return parseColors(colors).isNotEmpty ? colors : tradeColors;
  }

  /// Builds the `product` map expected by [ListingProductCard].
  static Map<String, dynamic> mapLatestProductForListingCard({
    required LatestProduct product,
    required bool isTradeUser,
    String? descriptionFallback,
  }) {
    final rawFeatures = _pickForFeatures(
      isTradeUser: isTradeUser,
      features: product.features,
      tradeFeatures: product.tradeFeatures,
    );
    final rawColors = _pickForColors(
      isTradeUser: isTradeUser,
      colors: product.colors,
      tradeColors: product.tradeColors,
    );

    final previousPrice = product.previousPrice;
    final price = product.price;
    final onSale = previousPrice > 0 && previousPrice > price;

    return {
      'id': product.id,
      'image': product.thumbnail,
      'thumbnail': product.thumbnail,
      'name': product.name,
      'sku': product.sku,
      'description':
          product.shortDescription ??
          descriptionFallback ??
          'Product description not available.',
      'price': price,
      'previous_price': previousPrice,
      'currentPrice': price.toString(),
      'originalPrice': previousPrice.toString(),
      'onSale': onSale,
      'onsale_line': product.onSaleLine,
      'display_features': parseFeatures(rawFeatures),
      'display_feature_colors': parseColors(rawColors),
      'out_of_stock': product.outOfStock,
      'show_freight_cost_icon': product.showFreightCostIcon,
      'show_free_shipping_icon': product.showFreeShippingIcon,
    };
  }

  /// Fallback map for legacy dummy products on home (non-API list).
  static Map<String, dynamic> mapLegacyProductMapForListingCard({
    required Map<String, dynamic> product,
    required bool isTradeUser,
  }) {
    final rawFeatures = _pickForFeatures(
      isTradeUser: isTradeUser,
      features: product['features'] ?? product['display_features'],
      tradeFeatures: product['trade_features'],
    );
    final rawColors = _pickForColors(
      isTradeUser: isTradeUser,
      colors: product['colors'] ?? product['display_feature_colors'],
      tradeColors: product['trade_colors'],
    );

    final previous = product['previous_price'] ?? product['originalPrice'];
    final price = product['price'] ?? product['currentPrice'];
    final num prevNum = _toNum(previous);
    final num priceNum = _toNum(price);
    final onSale = product['onSale'] == true || (prevNum > 0 && prevNum > priceNum);

    return {
      ...product,
      'thumbnail': product['thumbnail'] ?? product['image'],
      'price': priceNum,
      'previous_price': prevNum,
      'currentPrice': priceNum.toString(),
      'originalPrice': prevNum.toString(),
      'onSale': onSale,
      'onsale_line': product['onsale_line'],
      'display_features': parseFeatures(rawFeatures),
      'display_feature_colors': parseColors(rawColors),
      'out_of_stock': product['out_of_stock'] ?? 0,
    };
  }

  static num _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString().trim()) ?? 0;
  }
}
