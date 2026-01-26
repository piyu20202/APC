class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? areaCode;
  final String? landline;
  final String? unitApartmentNo;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? zip;
  final int isTradeUser;
  final int specialUser;
  final int? freeShippingThreshold;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.areaCode,
    this.landline,
    this.unitApartmentNo,
    this.address,
    this.city,
    this.state,
    this.country,
    this.zip,
    required this.isTradeUser,
    required this.specialUser,
    this.freeShippingThreshold,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      areaCode: json['area_code'] as String?,
      landline: json['landline'] as String?,
      unitApartmentNo: json['unit_apartmentno'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      zip: json['zip'] as String?,
      isTradeUser: json['is_trade_user'] as int,
      specialUser: json['special_user'] as int,
      freeShippingThreshold: json['free_shipping_threshold'] != null
          ? (json['free_shipping_threshold'] is int
                ? json['free_shipping_threshold'] as int
                : int.tryParse(json['free_shipping_threshold'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'area_code': areaCode,
      'landline': landline,
      'unit_apartmentno': unitApartmentNo,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'zip': zip,
      'is_trade_user': isTradeUser,
      'special_user': specialUser,
      'free_shipping_threshold': freeShippingThreshold,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? areaCode,
    String? landline,
    String? unitApartmentNo,
    String? address,
    String? city,
    String? state,
    String? country,
    String? zip,
    int? isTradeUser,
    int? specialUser,
    int? freeShippingThreshold,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      areaCode: areaCode ?? this.areaCode,
      landline: landline ?? this.landline,
      unitApartmentNo: unitApartmentNo ?? this.unitApartmentNo,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zip: zip ?? this.zip,
      isTradeUser: isTradeUser ?? this.isTradeUser,
      specialUser: specialUser ?? this.specialUser,
      freeShippingThreshold: freeShippingThreshold ?? this.freeShippingThreshold,
    );
  }
}

class LoginResponse {
  final String accessToken;
  final String tokenType;
  final UserModel user;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }
}
