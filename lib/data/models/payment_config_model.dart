class PaymentConfigModel {
  final CyberSourceConfig? cybersource;
  final GooglePayConfig? googlepay;
  final ApplePayConfig? applepay;
  final PayPalConfig? paypal;

  PaymentConfigModel({
    this.cybersource,
    this.googlepay,
    this.applepay,
    this.paypal,
  });

  factory PaymentConfigModel.fromJson(Map<String, dynamic> json) {
    return PaymentConfigModel(
      cybersource: json['cybersource'] != null
          ? CyberSourceConfig.fromJson(json['cybersource'])
          : null,
      googlepay: json['googlepay'] != null
          ? GooglePayConfig.fromJson(json['googlepay'])
          : null,
      applepay: json['applepay'] != null
          ? ApplePayConfig.fromJson(json['applepay'])
          : null,
      paypal: json['paypal'] != null
          ? PayPalConfig.fromJson(json['paypal'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cybersource': cybersource?.toJson(),
      'googlepay': googlepay?.toJson(),
      'applepay': applepay?.toJson(),
      'paypal': paypal?.toJson(),
    };
  }
}

class CyberSourceConfig {
  final String? merchantId;
  final String? accessKey;
  final String? secretKey;

  CyberSourceConfig({this.merchantId, this.accessKey, this.secretKey});

  factory CyberSourceConfig.fromJson(Map<String, dynamic> json) {
    return CyberSourceConfig(
      merchantId: json['merchant_id'],
      accessKey: json['access_key'],
      secretKey: json['secret_key'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant_id': merchantId,
      'access_key': accessKey,
      'secret_key': secretKey,
    };
  }
}

class GooglePayConfig {
  final String? merchantId;

  GooglePayConfig({this.merchantId});

  factory GooglePayConfig.fromJson(Map<String, dynamic> json) {
    return GooglePayConfig(
      merchantId: json['merchant_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant_id': merchantId,
    };
  }
}

class ApplePayConfig {
  final String? merchantId;

  ApplePayConfig({this.merchantId});

  factory ApplePayConfig.fromJson(Map<String, dynamic> json) {
    return ApplePayConfig(
      merchantId: json['merchant_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant_id': merchantId,
    };
  }
}

class PayPalConfig {
  final String? clientKey;
  final String? secretKey;

  PayPalConfig({this.clientKey, this.secretKey});

  factory PayPalConfig.fromJson(Map<String, dynamic> json) {
    return PayPalConfig(
      clientKey: json['client_key'],
      secretKey: json['secret_key'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_key': clientKey,
      'secret_key': secretKey,
    };
  }
}
