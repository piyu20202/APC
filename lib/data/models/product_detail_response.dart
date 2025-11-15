import 'product_details_model.dart';

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

String _asString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

int _asInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}

double _asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

bool _asBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  final normalized = value.toString().toLowerCase();
  return normalized == 'yes' || normalized == 'true' || normalized == '1';
}

class GalleryItem {
  final int id;
  final int productId;
  final String photo;
  final String? gTitle;

  const GalleryItem({
    required this.id,
    required this.productId,
    required this.photo,
    this.gTitle,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      id: _asInt(json['id']),
      productId: _asInt(json['product_id']),
      photo: _asString(json['photo']),
      gTitle: json['g_title']?.toString(),
    );
  }
}

class ProductDetailResponse {
  final ProductDetailsModel product;
  final List<KitIncludeItem> kitIncludesOne;
  final List<KitIncludeItem> kitIncludesTwo;
  final List<QtyUpgradeProduct> qtyUpgradeProducts;
  final List<UpgradeProduct> upgradeProducts;
  final List<AddonProduct> addonProducts;
  final List<GalleryItem> gallery;

  const ProductDetailResponse({
    required this.product,
    required this.kitIncludesOne,
    required this.kitIncludesTwo,
    required this.qtyUpgradeProducts,
    required this.upgradeProducts,
    required this.addonProducts,
    required this.gallery,
  });

  factory ProductDetailResponse.fromJson(Map<String, dynamic> json) {
    final productJson = (json['products'] as Map<String, dynamic>?) ?? {};

    return ProductDetailResponse(
      product: ProductDetailsModel.fromJson(productJson),
      kitIncludesOne: _asList(json['kit_includes_one'])
          .map((item) => KitIncludeItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      kitIncludesTwo: _asList(json['kit_includes_two'])
          .map((item) => KitIncludeItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      qtyUpgradeProducts: _asList(json['qty_upgrade_products'])
          .map(
            (item) => QtyUpgradeProduct.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      upgradeProducts: _asList(json['upgrade_products'])
          .map((item) => UpgradeProduct.fromJson(item as Map<String, dynamic>))
          .toList(),
      addonProducts: _asList(json['addon_products'])
          .map((item) => AddonProduct.fromJson(item as Map<String, dynamic>))
          .toList(),
      gallery: _asList(json['gallery'])
          .map((item) => GalleryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class KitIncludeItem {
  final int id;
  final int mainId;
  final int kitProductId;
  final int productBaseQuantity;
  final String name;
  final String sku;

  const KitIncludeItem({
    required this.id,
    required this.mainId,
    required this.kitProductId,
    required this.productBaseQuantity,
    required this.name,
    required this.sku,
  });

  factory KitIncludeItem.fromJson(Map<String, dynamic> json) {
    return KitIncludeItem(
      id: _asInt(json['id']),
      mainId: _asInt(json['mainId']),
      kitProductId: _asInt(json['kitProductId']),
      productBaseQuantity: _asInt(json['productBaseQuantity']),
      name: _asString(json['name']),
      sku: _asString(json['sku']),
    );
  }
}

class QtyUpgradeProduct {
  final int id;
  final int mainId;
  final int kitProductId;
  final int productBaseQuantity;
  final bool isUpgradeQty;
  final int maxQuantity;
  final double extraUnitPrice;
  final bool isUpgradeItem;
  final String name;
  final String sku;
  final String photo;
  final String upgradeShortDescription;
  final double price;

  const QtyUpgradeProduct({
    required this.id,
    required this.mainId,
    required this.kitProductId,
    required this.productBaseQuantity,
    required this.isUpgradeQty,
    required this.maxQuantity,
    required this.extraUnitPrice,
    required this.isUpgradeItem,
    required this.name,
    required this.sku,
    required this.photo,
    required this.upgradeShortDescription,
    required this.price,
  });

  factory QtyUpgradeProduct.fromJson(Map<String, dynamic> json) {
    return QtyUpgradeProduct(
      id: _asInt(json['id']),
      mainId: _asInt(json['mainId']),
      kitProductId: _asInt(json['kitProductId']),
      productBaseQuantity: _asInt(json['productBaseQuantity']),
      isUpgradeQty: _asBool(json['isUpgradeQty']),
      maxQuantity: _asInt(json['maxQuantity']),
      extraUnitPrice: _asDouble(json['extraUnitPrice']),
      isUpgradeItem: _asBool(json['isUpgradeItem']),
      name: _asString(json['name']),
      sku: _asString(json['sku']),
      photo: _asString(json['photo']),
      upgradeShortDescription: _asString(json['upgradeShortDescription']),
      price: _asDouble(json['price']),
    );
  }
}

class UpgradeProduct {
  final int id;
  final int mainId;
  final int kitProductId;
  final int productBaseQuantity;
  final bool isUpgradeItem;
  final String name;
  final String sku;
  final String photo;
  final String upgradeShortDescription;
  final double price;
  final List<SubProduct> subProducts;

  const UpgradeProduct({
    required this.id,
    required this.mainId,
    required this.kitProductId,
    required this.productBaseQuantity,
    required this.isUpgradeItem,
    required this.name,
    required this.sku,
    required this.photo,
    required this.upgradeShortDescription,
    required this.price,
    required this.subProducts,
  });

  factory UpgradeProduct.fromJson(Map<String, dynamic> json) {
    return UpgradeProduct(
      id: _asInt(json['id']),
      mainId: _asInt(json['mainId']),
      kitProductId: _asInt(json['kitProductId']),
      productBaseQuantity: _asInt(json['productBaseQuantity']),
      isUpgradeItem: _asBool(json['isUpgradeItem']),
      name: _asString(json['name']),
      sku: _asString(json['sku']),
      photo: _asString(json['photo']),
      upgradeShortDescription: _asString(json['upgradeShortDescription']),
      price: _asDouble(json['price']),
      subProducts: _asList(json['sub_products'])
          .map((item) => SubProduct.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubProduct {
  final int id;
  final int mainId;
  final int kitProductId;
  final int productBaseQuantity;
  final String name;
  final String sku;
  final String photo;
  final String upgradeShortDescription;
  final double price;

  const SubProduct({
    required this.id,
    required this.mainId,
    required this.kitProductId,
    required this.productBaseQuantity,
    required this.name,
    required this.sku,
    required this.photo,
    required this.upgradeShortDescription,
    required this.price,
  });

  factory SubProduct.fromJson(Map<String, dynamic> json) {
    return SubProduct(
      id: _asInt(json['id']),
      mainId: _asInt(json['mainId']),
      kitProductId: _asInt(json['kitProductId']),
      productBaseQuantity: _asInt(json['productBaseQuantity']),
      name: _asString(json['name']),
      sku: _asString(json['sku']),
      photo: _asString(json['photo']),
      upgradeShortDescription: _asString(json['upgradeShortDescription']),
      price: _asDouble(json['price']),
    );
  }
}

class AddonProduct {
  final int id;
  final int mainId;
  final int kitProductId;
  final String name;
  final String sku;
  final String photo;
  final String upgradeShortDescription;
  final double unitPrice;
  final double? originalPrice;

  const AddonProduct({
    required this.id,
    required this.mainId,
    required this.kitProductId,
    required this.name,
    required this.sku,
    required this.photo,
    required this.upgradeShortDescription,
    required this.unitPrice,
    this.originalPrice,
  });

  factory AddonProduct.fromJson(Map<String, dynamic> json) {
    return AddonProduct(
      id: _asInt(json['id']),
      mainId: _asInt(json['mainId']),
      kitProductId: _asInt(json['kitProductId']),
      name: _asString(json['name']),
      sku: _asString(json['sku']),
      photo: _asString(json['photo']),
      upgradeShortDescription: _asString(json['upgradeShortDescription']),
      unitPrice: _asDouble(json['price'] ?? json['unitPrice']),
      originalPrice: json['previous_price'] != null
          ? _asDouble(json['previous_price'])
          : null,
    );
  }
}
