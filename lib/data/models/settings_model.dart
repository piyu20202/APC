class SettingsModel {
  final GeneralSettings generalSettings;
  final PageSettings pageSettings;
  final List<PickupLocation> pickupLocations;

  SettingsModel({
    required this.generalSettings,
    required this.pageSettings,
    required this.pickupLocations,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      generalSettings: GeneralSettings.fromJson(
        json['general_settings'] as Map<String, dynamic>,
      ),
      pageSettings: PageSettings.fromJson(
        json['page_settings'] as Map<String, dynamic>,
      ),
      pickupLocations: (json['pickup_locations'] as List<dynamic>)
          .map(
            (location) =>
                PickupLocation.fromJson(location as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'general_settings': generalSettings.toJson(),
      'page_settings': pageSettings.toJson(),
      'pickup_locations': pickupLocations
          .map((location) => location.toJson())
          .toList(),
    };
  }
}

class GeneralSettings {
  final String logo;
  final String favicon;
  final String title;
  final String copyright;
  final String headerPhone;
  final String defaultImage;

  GeneralSettings({
    required this.logo,
    required this.favicon,
    required this.title,
    required this.copyright,
    required this.headerPhone,
    required this.defaultImage,
  });

  factory GeneralSettings.fromJson(Map<String, dynamic> json) {
    return GeneralSettings(
      logo: json['logo'] as String? ?? '',
      favicon: json['favicon'] as String? ?? '',
      title: json['title'] as String? ?? '',
      copyright: json['copyright'] as String? ?? '',
      headerPhone: json['header_phone'] as String? ?? '',
      defaultImage: json['default_image'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logo': logo,
      'favicon': favicon,
      'title': title,
      'copyright': copyright,
      'header_phone': headerPhone,
      'default_image': defaultImage,
    };
  }
}

class PageSettings {
  final int id;
  final String contactSuccess;
  final String contactEmail;
  final String contactTitle;
  final String contactText;
  final String sideTitle;
  final String sideText;
  final String street;
  final String phone;
  final String? fax;
  final String email;
  final String site;
  final String bestSellerBanner;
  final String bestSellerBannerLink;
  final String bigSaveBanner;
  final String bigSaveBannerLink;
  final String bestSellerBanner1;
  final String bestSellerBannerLink1;
  final String bigSaveBanner1;
  final String bigSaveBannerLink1;
  final String topImageTitle;
  final String bottomImageTitle;
  final String? bigImageTitle;
  final String? bigImageTitle1;

  PageSettings({
    required this.id,
    required this.contactSuccess,
    required this.contactEmail,
    required this.contactTitle,
    required this.contactText,
    required this.sideTitle,
    required this.sideText,
    required this.street,
    required this.phone,
    this.fax,
    required this.email,
    required this.site,
    required this.bestSellerBanner,
    required this.bestSellerBannerLink,
    required this.bigSaveBanner,
    required this.bigSaveBannerLink,
    required this.bestSellerBanner1,
    required this.bestSellerBannerLink1,
    required this.bigSaveBanner1,
    required this.bigSaveBannerLink1,
    required this.topImageTitle,
    required this.bottomImageTitle,
    this.bigImageTitle,
    this.bigImageTitle1,
  });

  factory PageSettings.fromJson(Map<String, dynamic> json) {
    return PageSettings(
      id: json['id'] as int? ?? 0,
      contactSuccess: json['contact_success'] as String? ?? '',
      contactEmail: json['contact_email'] as String? ?? '',
      contactTitle: _extractTextFromHtml(
        json['contact_title'] as String? ?? '',
      ),
      contactText: _extractTextFromHtml(json['contact_text'] as String? ?? ''),
      sideTitle: _extractTextFromHtml(json['side_title'] as String? ?? ''),
      sideText: _extractTextFromHtml(json['side_text'] as String? ?? ''),
      street: json['street'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      fax: json['fax'] as String?,
      email: json['email'] as String? ?? '',
      site: json['site'] as String? ?? '',
      bestSellerBanner: json['best_seller_banner'] as String? ?? '',
      bestSellerBannerLink: json['best_seller_banner_link'] as String? ?? '',
      bigSaveBanner: json['big_save_banner'] as String? ?? '',
      bigSaveBannerLink: json['big_save_banner_link'] as String? ?? '',
      bestSellerBanner1: json['best_seller_banner1'] as String? ?? '',
      bestSellerBannerLink1: json['best_seller_banner_link1'] as String? ?? '',
      bigSaveBanner1: json['big_save_banner1'] as String? ?? '',
      bigSaveBannerLink1: json['big_save_banner_link1'] as String? ?? '',
      topImageTitle: json['top_image_title'] as String? ?? '',
      bottomImageTitle: json['bottom_image_title'] as String? ?? '',
      bigImageTitle: json['big_image_title'] as String?,
      bigImageTitle1: json['big_image_title1'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact_success': contactSuccess,
      'contact_email': contactEmail,
      'contact_title': contactTitle,
      'contact_text': contactText,
      'side_title': sideTitle,
      'side_text': sideText,
      'street': street,
      'phone': phone,
      'fax': fax,
      'email': email,
      'site': site,
      'best_seller_banner': bestSellerBanner,
      'best_seller_banner_link': bestSellerBannerLink,
      'big_save_banner': bigSaveBanner,
      'big_save_banner_link': bigSaveBannerLink,
      'best_seller_banner1': bestSellerBanner1,
      'best_seller_banner_link1': bestSellerBannerLink1,
      'big_save_banner1': bigSaveBanner1,
      'big_save_banner_link1': bigSaveBannerLink1,
      'top_image_title': topImageTitle,
      'bottom_image_title': bottomImageTitle,
      'big_image_title': bigImageTitle,
      'big_image_title1': bigImageTitle1,
    };
  }

  // Helper function to extract text from HTML
  static String _extractTextFromHtml(String html) {
    if (html.isEmpty) return '';

    // Remove HTML tags using regex
    final htmlTagRegex = RegExp(r'<[^>]*>');
    String text = html.replaceAll(htmlTagRegex, '');

    // Decode HTML entities
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&');

    // Clean up extra whitespace
    text = text.trim().replaceAll(RegExp(r'\s+'), ' ');

    return text;
  }
}

class PickupLocation {
  final int id;
  final String location;
  final String warehouseCode;
  final String warehouseShortCode;
  final String phone;
  final String displayPhone;
  final String salesEmail;
  final String supportEmail;
  final String googleMap;
  final int status;
  final int timeDifference;

  PickupLocation({
    required this.id,
    required this.location,
    required this.warehouseCode,
    required this.warehouseShortCode,
    required this.phone,
    required this.displayPhone,
    required this.salesEmail,
    required this.supportEmail,
    required this.googleMap,
    required this.status,
    required this.timeDifference,
  });

  factory PickupLocation.fromJson(Map<String, dynamic> json) {
    return PickupLocation(
      id: json['id'] as int? ?? 0,
      location: json['location'] as String? ?? '',
      warehouseCode: json['warehouse_code'] as String? ?? '',
      warehouseShortCode: json['warehouse_short_code'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      displayPhone: json['display_phone'] as String? ?? '',
      salesEmail: json['sales_email'] as String? ?? '',
      supportEmail: json['support_email'] as String? ?? '',
      googleMap: json['google_map'] as String? ?? '',
      status: json['status'] as int? ?? 0,
      timeDifference: json['time_difference'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'warehouse_code': warehouseCode,
      'warehouse_short_code': warehouseShortCode,
      'phone': phone,
      'display_phone': displayPhone,
      'sales_email': salesEmail,
      'support_email': supportEmail,
      'google_map': googleMap,
      'status': status,
      'time_difference': timeDifference,
    };
  }
}
