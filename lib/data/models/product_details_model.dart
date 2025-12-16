class ProductDetailsModel {
  final int id;
  final String sku;
  final String productType;
  final String? affiliateLink;
  final int userId;
  final String categoryId;
  final String subcategoryId;
  final String childcategoryId;
  final String? childsubcategoryId;
  final dynamic attributes;
  final String name;
  final String slug;
  final String photo;
  final String? googlePhoto;
  final String? googleThumbnail;
  final String includeInGoogleXml;
  final String thumbnail;
  final String? imageTitle;
  final String? file;
  final String size;
  final String sizeQty;
  final String sizePrice;
  final String sizeWeight;
  final String color;
  final num price;
  final num previousPrice;
  final String? details;
  final dynamic stock;
  final String? policy;
  final int status;
  final int views;
  final String tags;
  final List<String> features;
  final List<String> colors;
  final int productCondition;
  final dynamic ship;
  final int isMeta;
  final String metaTitle;
  final List<String> metaTag;
  final String? metaDescription;
  final String? youtube;
  final String type;
  final String license;
  final String licenseQty;
  final String? link;
  final String? platform;
  final String? region;
  final String? licenceType;
  final String? measure;
  final int featured;
  final int best;
  final int top;
  final int hot;
  final int latest;
  final int big;
  final int trending;
  final int sale;
  final String createdAt;
  final String updatedAt;
  final int isDiscount;
  final String? discountDate;
  final String wholeSellQty;
  final String wholeSellDiscount;
  final int isCatalog;
  final int catalogId;
  final int pDay;
  final int pMonth;
  final String pWeight;
  final String? shortDescription;
  final String? productSizeType;
  final String? productAdjustable;
  final String? productAddOn;
  final String? usedInKit;
  final String? shippingRateType;
  final int? totalParcelCount;
  final String? parcelWeightList;
  final String? isKIT;
  final String? upgradeShortDescription;
  final String? isAddon;
  final num? addonPrice;
  final num? upgradablePrice;
  final num? upgradableShippingPrice;
  final String showHotPriceImage;
  final dynamic structuredDatas;
  final String additionalExpressShippingStatus;
  final int commonWgoProduct;
  final int backOrderAllowed;
  final dynamic tradeUserProduct;
  final int enableProductStock;
  final int stockShowRemainingQty;
  final int stockThresholdQty;
  final int reorderLevelQty;
  final String? supplierSku;
  final String? supplierName;
  final int premadeKit;
  final num tradePrice;
  final dynamic tradeFeatures;
  final dynamic tradeColors;
  final int outOfStock;
  final String customerType;
  final String slugUrl;
  final int showFreightCostIcon;
  final int showFreeShippingIcon;

  ProductDetailsModel({
    required this.id,
    required this.sku,
    required this.productType,
    this.affiliateLink,
    required this.userId,
    required this.categoryId,
    required this.subcategoryId,
    required this.childcategoryId,
    this.childsubcategoryId,
    this.attributes,
    required this.name,
    required this.slug,
    required this.photo,
    this.googlePhoto,
    this.googleThumbnail,
    required this.includeInGoogleXml,
    required this.thumbnail,
    this.imageTitle,
    this.file,
    required this.size,
    required this.sizeQty,
    required this.sizePrice,
    required this.sizeWeight,
    required this.color,
    required this.price,
    required this.previousPrice,
    this.details,
    this.stock,
    this.policy,
    required this.status,
    required this.views,
    required this.tags,
    required this.features,
    required this.colors,
    required this.productCondition,
    this.ship,
    required this.isMeta,
    required this.metaTitle,
    required this.metaTag,
    this.metaDescription,
    this.youtube,
    required this.type,
    required this.license,
    required this.licenseQty,
    this.link,
    this.platform,
    this.region,
    this.licenceType,
    this.measure,
    required this.featured,
    required this.best,
    required this.top,
    required this.hot,
    required this.latest,
    required this.big,
    required this.trending,
    required this.sale,
    required this.createdAt,
    required this.updatedAt,
    required this.isDiscount,
    this.discountDate,
    required this.wholeSellQty,
    required this.wholeSellDiscount,
    required this.isCatalog,
    required this.catalogId,
    required this.pDay,
    required this.pMonth,
    required this.pWeight,
    this.shortDescription,
    this.productSizeType,
    this.productAdjustable,
    this.productAddOn,
    this.usedInKit,
    this.shippingRateType,
    this.totalParcelCount,
    this.parcelWeightList,
    this.isKIT,
    this.upgradeShortDescription,
    this.isAddon,
    this.addonPrice,
    this.upgradablePrice,
    this.upgradableShippingPrice,
    required this.showHotPriceImage,
    this.structuredDatas,
    required this.additionalExpressShippingStatus,
    required this.commonWgoProduct,
    required this.backOrderAllowed,
    this.tradeUserProduct,
    required this.enableProductStock,
    required this.stockShowRemainingQty,
    required this.stockThresholdQty,
    required this.reorderLevelQty,
    this.supplierSku,
    this.supplierName,
    required this.premadeKit,
    required this.tradePrice,
    this.tradeFeatures,
    this.tradeColors,
    required this.outOfStock,
    required this.customerType,
    required this.slugUrl,
    required this.showFreightCostIcon,
    required this.showFreeShippingIcon,
  });

  factory ProductDetailsModel.fromJson(Map<String, dynamic> json) {
    num parseNum(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v;
      final s = v.toString().trim();
      return num.tryParse(s) ?? 0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      final s = v.toString().trim();
      return int.tryParse(s) ?? 0;
    }

    String parseString(dynamic v) {
      if (v == null) return '';
      return v.toString();
    }

    List<String> parseStringList(dynamic v) {
      if (v == null) return [];
      if (v is List) {
        return v.map((e) => e.toString()).toList();
      }
      return [];
    }

    return ProductDetailsModel(
      id: parseInt(json['id']),
      sku: parseString(json['sku']),
      productType: parseString(json['product_type']),
      affiliateLink: json['affiliate_link']?.toString(),
      userId: parseInt(json['user_id']),
      categoryId: parseString(json['category_id']),
      subcategoryId: parseString(json['subcategory_id']),
      childcategoryId: parseString(json['childcategory_id']),
      childsubcategoryId: json['childsubcategory_id']?.toString(),
      attributes: json['attributes'],
      name: parseString(json['name']),
      slug: parseString(json['slug']),
      photo: parseString(json['photo']),
      googlePhoto: json['google_photo']?.toString(),
      googleThumbnail: json['google_thumbnail']?.toString(),
      includeInGoogleXml: parseString(json['include_in_google_xml']),
      thumbnail: parseString(json['thumbnail']),
      imageTitle: json['image_title']?.toString(),
      file: json['file']?.toString(),
      size: parseString(json['size']),
      sizeQty: parseString(json['size_qty']),
      sizePrice: parseString(json['size_price']),
      sizeWeight: parseString(json['size_weight']),
      color: parseString(json['color']),
      price: parseNum(json['price']),
      previousPrice: parseNum(json['previous_price']),
      details: json['details']?.toString(),
      stock: json['stock'],
      policy: json['policy']?.toString(),
      status: parseInt(json['status']),
      views: parseInt(json['views']),
      tags: parseString(json['tags']),
      features: parseStringList(json['features']),
      colors: parseStringList(json['colors']),
      productCondition: parseInt(json['product_condition']),
      ship: json['ship'],
      isMeta: parseInt(json['is_meta']),
      metaTitle: parseString(json['meta_title']),
      metaTag: parseStringList(json['meta_tag']),
      metaDescription: json['meta_description']?.toString(),
      youtube: json['youtube']?.toString(),
      type: parseString(json['type']),
      license: parseString(json['license']),
      licenseQty: parseString(json['license_qty']),
      link: json['link']?.toString(),
      platform: json['platform']?.toString(),
      region: json['region']?.toString(),
      licenceType: json['licence_type']?.toString(),
      measure: json['measure']?.toString(),
      featured: parseInt(json['featured']),
      best: parseInt(json['best']),
      top: parseInt(json['top']),
      hot: parseInt(json['hot']),
      latest: parseInt(json['latest']),
      big: parseInt(json['big']),
      trending: parseInt(json['trending']),
      sale: parseInt(json['sale']),
      createdAt: parseString(json['created_at']),
      updatedAt: parseString(json['updated_at']),
      isDiscount: parseInt(json['is_discount']),
      discountDate: json['discount_date']?.toString(),
      wholeSellQty: parseString(json['whole_sell_qty']),
      wholeSellDiscount: parseString(json['whole_sell_discount']),
      isCatalog: parseInt(json['is_catalog']),
      catalogId: parseInt(json['catalog_id']),
      pDay: parseInt(json['p_day']),
      pMonth: parseInt(json['p_month']),
      pWeight: parseString(json['p_weight']),
      shortDescription: json['short_description']?.toString(),
      productSizeType: json['product_sizeType']?.toString(),
      productAdjustable: json['product_adjustable']?.toString(),
      productAddOn: json['product_add_on']?.toString(),
      usedInKit: json['used_in_kit']?.toString(),
      shippingRateType: json['shipping_rate_type']?.toString(),
      totalParcelCount: json['total_parcel_count'] != null
          ? parseInt(json['total_parcel_count'])
          : null,
      parcelWeightList: json['parcel_weight_list']?.toString(),
      isKIT: json['isKIT']?.toString(),
      upgradeShortDescription: json['upgradeShortDescription']?.toString(),
      isAddon: json['isAddon']?.toString(),
      addonPrice: json['addon_price'] != null
          ? parseNum(json['addon_price'])
          : null,
      upgradablePrice: json['upgradable_price'] != null
          ? parseNum(json['upgradable_price'])
          : null,
      upgradableShippingPrice: json['upgradable_shipping_price'] != null
          ? parseNum(json['upgradable_shipping_price'])
          : null,
      showHotPriceImage: parseString(json['showHotPriceImage']),
      structuredDatas: json['structured_datas'],
      additionalExpressShippingStatus: parseString(
        json['additional_express_shipping_status'],
      ),
      commonWgoProduct: parseInt(json['common_wgo_product']),
      backOrderAllowed: parseInt(json['back_order_allowed']),
      tradeUserProduct: json['trade_user_product'],
      enableProductStock: parseInt(json['enable_product_stock']),
      stockShowRemainingQty: parseInt(json['stock_show_remaining_qty']),
      stockThresholdQty: parseInt(json['stock_threshold_qty']),
      reorderLevelQty: parseInt(json['reorder_level_qty']),
      supplierSku: json['supplier_sku']?.toString(),
      supplierName: json['supplier_name']?.toString(),
      premadeKit: parseInt(json['premade_kit']),
      tradePrice: parseNum(json['trade_price']),
      tradeFeatures: json['trade_features'],
      tradeColors: json['trade_colors'],
      outOfStock: parseInt(json['out_of_stock']),
      customerType: parseString(json['customer_type']),
      slugUrl: parseString(json['slug_url']),
      showFreightCostIcon: parseInt(json['show_freight_cost_icon']),
      showFreeShippingIcon: parseInt(json['show_free_shipping_icon']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'product_type': productType,
      'affiliate_link': affiliateLink,
      'user_id': userId,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'childcategory_id': childcategoryId,
      'childsubcategory_id': childsubcategoryId,
      'attributes': attributes,
      'name': name,
      'slug': slug,
      'photo': photo,
      'google_photo': googlePhoto,
      'google_thumbnail': googleThumbnail,
      'include_in_google_xml': includeInGoogleXml,
      'thumbnail': thumbnail,
      'image_title': imageTitle,
      'file': file,
      'size': size,
      'size_qty': sizeQty,
      'size_price': sizePrice,
      'size_weight': sizeWeight,
      'color': color,
      'price': price,
      'previous_price': previousPrice,
      'details': details,
      'stock': stock,
      'policy': policy,
      'status': status,
      'views': views,
      'tags': tags,
      'features': features,
      'colors': colors,
      'product_condition': productCondition,
      'ship': ship,
      'is_meta': isMeta,
      'meta_title': metaTitle,
      'meta_tag': metaTag,
      'meta_description': metaDescription,
      'youtube': youtube,
      'type': type,
      'license': license,
      'license_qty': licenseQty,
      'link': link,
      'platform': platform,
      'region': region,
      'licence_type': licenceType,
      'measure': measure,
      'featured': featured,
      'best': best,
      'top': top,
      'hot': hot,
      'latest': latest,
      'big': big,
      'trending': trending,
      'sale': sale,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_discount': isDiscount,
      'discount_date': discountDate,
      'whole_sell_qty': wholeSellQty,
      'whole_sell_discount': wholeSellDiscount,
      'is_catalog': isCatalog,
      'catalog_id': catalogId,
      'p_day': pDay,
      'p_month': pMonth,
      'p_weight': pWeight,
      'short_description': shortDescription,
      'product_sizeType': productSizeType,
      'product_adjustable': productAdjustable,
      'product_add_on': productAddOn,
      'used_in_kit': usedInKit,
      'shipping_rate_type': shippingRateType,
      'total_parcel_count': totalParcelCount,
      'parcel_weight_list': parcelWeightList,
      'isKIT': isKIT,
      'upgradeShortDescription': upgradeShortDescription,
      'isAddon': isAddon,
      'addon_price': addonPrice,
      'upgradable_price': upgradablePrice,
      'upgradable_shipping_price': upgradableShippingPrice,
      'showHotPriceImage': showHotPriceImage,
      'structured_datas': structuredDatas,
      'additional_express_shipping_status': additionalExpressShippingStatus,
      'common_wgo_product': commonWgoProduct,
      'back_order_allowed': backOrderAllowed,
      'trade_user_product': tradeUserProduct,
      'enable_product_stock': enableProductStock,
      'stock_show_remaining_qty': stockShowRemainingQty,
      'stock_threshold_qty': stockThresholdQty,
      'reorder_level_qty': reorderLevelQty,
      'supplier_sku': supplierSku,
      'supplier_name': supplierName,
      'premade_kit': premadeKit,
      'trade_price': tradePrice,
      'trade_features': tradeFeatures,
      'trade_colors': tradeColors,
      'out_of_stock': outOfStock,
      'customer_type': customerType,
      'slug_url': slugUrl,
      'show_freight_cost_icon': showFreightCostIcon,
      'show_free_shipping_icon': showFreeShippingIcon,
    };
  }
}
