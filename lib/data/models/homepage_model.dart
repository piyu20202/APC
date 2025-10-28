import 'package:flutter/foundation.dart';

class HomepageModel {
  final List<Partner> partners;
  final List<Service> services;
  final List<Slider> sliders;
  final List<Banner> allBanners;
  final List<Category> categories;
  final List<LatestProduct> latestProducts;

  HomepageModel({
    required this.partners,
    required this.services,
    required this.sliders,
    required this.allBanners,
    required this.categories,
    required this.latestProducts,
  });

  factory HomepageModel.fromJson(Map<String, dynamic> json) {
    return HomepageModel(
      partners:
          (json['partners'] as List<dynamic>?)
              ?.map((item) => Partner.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      services:
          (json['services'] as List<dynamic>?)
              ?.map((item) => Service.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      sliders:
          (json['sliders'] as List<dynamic>?)
              ?.map((item) => Slider.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      allBanners:
          (json['all_banners'] as List<dynamic>?)
              ?.map((item) => Banner.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      categories:
          (json['categories'] as List<dynamic>?)
              ?.where((item) => item != null) // Filter out null items
              .map((item) {
                try {
                  if (item is! Map<String, dynamic>) {
                    debugPrint(
                      'Category item is not a Map: ${item.runtimeType}',
                    );
                    return null;
                  }
                  return Category.fromJson(item);
                } catch (e) {
                  debugPrint('Error parsing category: $e');
                  return null;
                }
              })
              .whereType<Category>()
              .toList() ??
          [],
      latestProducts:
          (json['latest_products'] as List<dynamic>?)
              ?.where((item) => item != null)
              .map((item) {
                try {
                  if (item is! Map<String, dynamic>) return null;
                  return LatestProduct.fromJson(item);
                } catch (e) {
                  debugPrint('Error parsing latest product: $e');
                  return null;
                }
              })
              .whereType<LatestProduct>()
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partners': partners.map((partner) => partner.toJson()).toList(),
      'services': services.map((service) => service.toJson()).toList(),
      'sliders': sliders.map((slider) => slider.toJson()).toList(),
      'all_banners': allBanners.map((banner) => banner.toJson()).toList(),
      'categories': categories.map((category) => category.toJson()).toList(),
      'latest_products': latestProducts.map((p) => p.toJson()).toList(),
    };
  }
}

class Partner {
  final int id;
  final String photo;

  Partner({required this.id, required this.photo});

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'] as int? ?? 0,
      photo: json['photo'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'photo': photo};
  }
}

class Service {
  final int id;
  final String title;
  final String photo;

  Service({required this.id, required this.title, required this.photo});

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'photo': photo};
  }
}

class Slider {
  final int id;
  final String photo;
  final String? link;
  final String? title;

  Slider({required this.id, required this.photo, this.link, this.title});

  factory Slider.fromJson(Map<String, dynamic> json) {
    return Slider(
      id: json['id'] as int? ?? 0,
      photo: json['photo'] as String? ?? '',
      link: json['link'] as String?,
      title: json['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'photo': photo, 'link': link, 'title': title};
  }
}

class Banner {
  final int id;
  final String photo;
  final String? link;
  final String? title;

  Banner({required this.id, required this.photo, this.link, this.title});

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'] as int? ?? 0,
      photo: json['photo'] as String? ?? '',
      link: json['link'] as String?,
      title: json['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'photo': photo, 'link': link, 'title': title};
  }
}

class Category {
  final int id;
  final String name;
  final String? image;

  Category({required this.id, required this.name, this.image});

  factory Category.fromJson(Map<String, dynamic> json) {
    try {
      return Category(
        id: json['id'] is int
            ? json['id']
            : (json['id'] != null
                  ? int.tryParse(json['id'].toString()) ?? 0
                  : 0),
        name: json['name'] is String
            ? json['name']
            : json['name']?.toString() ?? '',
        image: json['image'] is String
            ? json['image']
            : json['image']?.toString(),
      );
    } catch (e) {
      // Return a default category if parsing fails
      return Category(id: 0, name: 'Unknown Category', image: null);
    }
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'image': image};
  }
}

class LatestProduct {
  final int id;
  final String sku;
  final String name;
  final String slug;
  final String? thumbnail;
  final num price;
  final num previousPrice;
  final int status;
  final int outOfStock;
  final String tags;
  final String features;
  final String? isKit;
  final String? createdAt;
  final String slugUrl;

  LatestProduct({
    required this.id,
    required this.sku,
    required this.name,
    required this.slug,
    required this.thumbnail,
    required this.price,
    required this.previousPrice,
    required this.status,
    required this.outOfStock,
    required this.tags,
    required this.features,
    required this.isKit,
    required this.createdAt,
    required this.slugUrl,
  });

  factory LatestProduct.fromJson(Map<String, dynamic> json) {
    num parseNum(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v;
      final s = v.toString().trim();
      return num.tryParse(s) ?? 0;
    }

    return LatestProduct(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      sku: (json['sku'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      thumbnail:
          (json['thumbnail'] == null ||
              (json['thumbnail'] as String?)?.isEmpty == true)
          ? null
          : json['thumbnail'].toString(),
      price: parseNum(json['price']),
      previousPrice: parseNum(json['previous_price']),
      status: json['status'] is int
          ? json['status']
          : int.tryParse('${json['status']}') ?? 0,
      outOfStock: json['out_of_stock'] is int
          ? json['out_of_stock']
          : int.tryParse('${json['out_of_stock']}') ?? 0,
      tags: (json['tags'] ?? '').toString(),
      features: (json['features'] ?? '').toString(),
      isKit: json['isKIT']?.toString(),
      createdAt: json['created_at']?.toString(),
      slugUrl: (json['slug_url'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'slug': slug,
      'thumbnail': thumbnail,
      'price': price,
      'previous_price': previousPrice,
      'status': status,
      'out_of_stock': outOfStock,
      'tags': tags,
      'features': features,
      'isKIT': isKit,
      'created_at': createdAt,
      'slug_url': slugUrl,
    };
  }
}
