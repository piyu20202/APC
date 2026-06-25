import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:apcproject/services/storage_service.dart';
import 'package:apcproject/data/services/payment_service.dart';
import 'package:apcproject/data/services/cart_service.dart';
import 'package:apcproject/data/services/order_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pay/pay.dart';
import 'package:apcproject/config/environment.dart';
import 'package:apcproject/data/models/user_model.dart';
import 'package:apcproject/core/utils/logger.dart';
import 'package:apcproject/core/utils/coupon_cart_display.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:apcproject/data/services/payment_config_service.dart';
import 'package:apcproject/data/models/payment_config_model.dart';
import 'package:apcproject/core/exceptions/api_exception.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:apcproject/ui/screens/payment_page/payment_failure.dart';
import 'package:apcproject/ui/screens/payment_page/payment_webview.dart';
import 'package:apcproject/ui/screens/profile_page/myorder.dart';

class _ShippingBreakdown {
  const _ShippingBreakdown({
    required this.subtotalExclGst,
    required this.shippingCost,
    required this.gstAmount,
    required this.discountAmount,
    required this.amount,
    required this.specialDiscount,
    required this.hasPendingFreightQuote,
    required this.isPayLater,
    required this.showFreeShippingLabel,
  });

  final double subtotalExclGst;
  final double shippingCost;
  final double gstAmount;
  final double discountAmount;
  final double amount;
  final double specialDiscount;
  final bool hasPendingFreightQuote;
  final bool isPayLater;
  final bool showFreeShippingLabel;
}

class _FreightRuleResult {
  const _FreightRuleResult({
    required this.shippingCost,
    required this.hasPendingFreightQuote,
    required this.showFreeShippingLabel,
  });

  final double shippingCost;
  final bool hasPendingFreightQuote;
  final bool showFreeShippingLabel;
}

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const PaymentPage({super.key, this.arguments});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final PaymentService _paymentService = PaymentService();
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, dynamic>? _orderData;
  String? _orderNumber;
  int? _orderId;
  double? _amount;
  String? _currency;

  // Order breakdown (from cart / shipping API, for display before payment)
  double? _totalCostExclGst; // total_cost_excl_gst — items only
  double? _totalWithoutGst; // total_without_gst
  double? _totalWithGst; // total_with_gst
  double? _subtotalExclGst; // legacy / coupon % base (synced from items total)
  double? _shippingCost;
  double? _gstAmount;
  double? _discountAmount; // stored for future display use
  double? _gstRate;
  bool _hasPendingFreightQuote = false;
  bool _isPayLater = false;
  bool _showFreeShippingLabel = false;

  /// From API `shipping_type`: `shipto` or `pickup`. Pickup hides free-delivery promo.
  String _shippingType = 'shipto';
  bool _isAwaitingFreight = false;
  String _selectedPaymentMethod = '';
  int _manualOrderByAdmin = 0;
  int _isTradeUser = 0;
  String _orderPaymentStatus = '';
  double? _specialDiscount;
  String _orderSource = '';
  String? _shippingTag;

  // Google Pay
  Pay? _payClient;
  PaymentConfiguration? _googlePayConfig;
  bool _isGooglePayAvailable = false;
  bool _isInitializingGooglePay = true;
  bool _hasAttemptedCouponFetch = false;
  StreamSubscription? _paymentResultSubscription;
  bool _isPaymentProcessing = false;
  bool _isWaitingForPaymentResult = false;
  bool _hasNavigatedAway = false;

  final _formKey = GlobalKey<FormState>();

  // Scroll controller for auto-scroll to card form + PAY NOW visibility
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _cardFormKey = GlobalKey();

  // PayPal config cache
  Map<String, dynamic>? _paypalConfig;

  // Coupon selection state
  List<dynamic> _availableCoupons = [];
  bool _isLoadingCoupons = false;

  // Card details
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardholderNameController =
      TextEditingController();

  final FocusNode _cardNumberFocus = FocusNode();
  final FocusNode _expiryFocus = FocusNode();
  final FocusNode _cvvFocus = FocusNode();
  final FocusNode _cardholderNameFocus = FocusNode();

  // Coupon variables
  final TextEditingController _couponController = TextEditingController();
  String? _couponCode;
  double _couponDiscount = 0.0;
  String? _couponOfferSubtitle;
  bool _isCouponApplied = false;
  bool _isUpdatingCoupon = false;

  // Stored for price refreshes
  String? _postcode;
  dynamic _oldCart;
  bool _pricingLoadFailed = false;
  bool _isRefreshingPricing = false;

  @override
  void initState() {
    super.initState();
    // STOP Auto-Initialization: API calls are now deferred to 'PAY NOW' click.
    // We only setup the UI from passed arguments for immediate display.
    _setupInitialUI();
    _loadPayPalConfig();
    _initializeGooglePay();

    // Scroll to bottom when CVV loses focus (covers both Done button & tap-outside)
    // 600ms delay gives iOS keyboard enough time to fully dismiss before scroll
    _cvvFocus.addListener(() {
      if (!_cvvFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  /// Populate initial UI values from navigation arguments to avoid showing $0.00
  /// without making any API calls until the user is ready to pay.
  void _setupInitialUI() {
    final args = widget.arguments;
    final bool isMyOrdersFlow = args?['from_my_orders_payment'] == true;

    if (args != null && args['summary_grand_total'] != null) {
      setState(() {
        _amount = _toDouble(args['summary_grand_total']) ?? 0.0;
        _gstAmount = _toDouble(args['summary_tax']) ?? 0.0;
        _shippingCost = _toDouble(args['summary_shipping']) ?? 0.0;
        _discountAmount = _toDouble(args['summary_discount']) ?? 0.0;
        _totalCostExclGst =
            _toDouble(args['summary_total_cost_excl_gst']) ??
            _toDouble(args['summary_subtotal']);
        _totalWithoutGst =
            _toDouble(args['summary_total_without_gst']) ??
            _toDouble(args['summary_subtotal']);
        _totalWithGst =
            _toDouble(args['summary_total_with_gst']) ??
            _toDouble(args['summary_grand_total']);
        _subtotalExclGst = _totalCostExclGst;

        // Initialize _isPayLater from flow indicator
        _isPayLater = isMyOrdersFlow;

        final argMethod = args['payment_method']?.toString();
        if (_selectedPaymentMethod.isEmpty &&
            argMethod != null &&
            argMethod.isNotEmpty) {
          _selectedPaymentMethod = argMethod;
        }

        // Show UI immediately from args (non-blank display)
        _isLoading = false;

        // Extract order ID/Number immediately so they are available for _refreshPricing
        final order = args['order_data']?['order'] as Map?;
        if (order != null) {
          _orderId = _toInt(order['id']);
          _orderNumber = order['order_number']?.toString();
          debugPrint(
            'SETUP_UI: Extracted Order ID: $_orderId, Number: $_orderNumber',
          );
        }
      });

      // For My Orders / Pay Later flow: even though we have initial values from args,
      // we MUST call _initializePayment() so it triggers _refreshPricing()
      // which calls /user/cart/shipping to get fresh, accurate pricing from the API.
      if (isMyOrdersFlow) {
        debugPrint(
          'SETUP_UI: My Orders flow detected - triggering _initializePayment for pricing refresh...',
        );
        _initializePayment();
      }
    } else {
      // Fallback for direct navigation where summary args are missing.
      // We must initialize to get the breakdown, otherwise the UI shows $0.00 and spins forever.
      _initializePayment();
    }
  }

  void _showShippingPricingErrorToast(Object error) {
    final isTimeout = error.toString().toLowerCase().contains('timeout');
    Fluttertoast.showToast(
      msg: isTimeout
          ? 'Shipping API timed out (90 sec). No response received. Pull down to refresh and try again.'
          : 'Could not load pricing from server. Pull down to refresh and try again.',
      toastLength: Toast.LENGTH_LONG,
    );
  }

  /// Pull-to-refresh: re-call /user/cart/shipping (user-initiated).
  Future<void> _onPullToRefreshPricing() async {
    if (_isRefreshingPricing || _isProcessing) return;
    setState(() => _isRefreshingPricing = true);
    try {
      await _reloadShippingPricing();
    } finally {
      if (mounted) setState(() => _isRefreshingPricing = false);
    }
  }

  Future<void> _reloadShippingPricing() async {
    String? postcode = _postcode;
    dynamic oldCart = _oldCart;

    if (postcode == null || postcode.isEmpty || oldCart == null) {
      final checkoutData = await StorageService.getCheckoutData();
      postcode = (checkoutData?['post_code'] as String?)?.trim();
      final cartResponse = await _getPaymentCartContainer();
      oldCart = cartResponse?['cart'];
      _postcode = postcode;
      _oldCart = oldCart;
    }

    if (postcode == null || postcode.isEmpty || oldCart == null) {
      Fluttertoast.showToast(
        msg: 'Missing checkout details. Please go back and try again.',
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    await _refreshPricing(postcode: postcode, oldCart: oldCart);
  }

  /// Load PayPal configuration from API (with asset fallback)
  Future<void> _loadPayPalConfig() async {
    try {
      // 1. Load baseline configuration from assets (for mode and other settings)
      final String jsonString = await rootBundle.loadString(
        'assets/paypal_config.json',
      );
      final Map<String, dynamic> configMap =
          jsonDecode(jsonString) as Map<String, dynamic>;

      // 2. Try to get dynamic credentials from storage
      var dynamicConfig = await PaymentConfigService.getCachedConfig();

      if (dynamicConfig == null) {
        debugPrint('PayPal: Cache empty, fetching dynamic config from API...');
        dynamicConfig = await PaymentConfigService.fetchAndSaveConfig();
      }

      final pp = dynamicConfig?.paypal;

      setState(() {
        _paypalConfig = configMap;
        if (pp != null && pp.clientKey != null && pp.secretKey != null) {
          debugPrint('Using dynamic PayPal credentials from API');
          // We'll store these in the configMap for convenience,
          // or just use the model values directly in handlePayPal.
          configMap['client_key'] = pp.clientKey;
          configMap['secret_key'] = pp.secretKey;
        }
      });
      debugPrint('PayPal config initialized. Mode: ${_paypalConfig?['mode']}');
    } catch (e) {
      debugPrint('Error loading PayPal config: $e');
      _paypalConfig = null;
    }
  }

  @override
  void dispose() {
    // NOTE: Do NOT clear payment_cart_snapshot here.
    // If user presses back button, we want to preserve the snapshot so they
    // can return to Order Price Details and try different coupon or payment method.
    // Snapshot should only be cleared after payment is SUCCESSFUL.
    _paymentResultSubscription?.cancel();
    _couponController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    _cardNumberFocus.dispose();
    _expiryFocus.dispose();
    _cvvFocus.dispose();
    _cardholderNameFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER METHODS - Parsing and Conversion
  // ─────────────────────────────────────────────────────────────────────────

  void _printLongString(String text, String label) {
    debugPrint('=== $label (Length: ${text.length}) ===');
    const int chunkSize = 800;
    for (int i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      debugPrint(text.substring(i, end));
    }
    debugPrint('=== END $label ===');
  }

  // ─── Google Pay ────────────────────────────────────────────────────────────

  Future<void> _initializeGooglePay() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      if (mounted) setState(() => _isInitializingGooglePay = false);
      return;
    }
    try {
      if (mounted) setState(() => _isInitializingGooglePay = true);

      // 1. Load base configuration from asset
      final String jsonString = await rootBundle.loadString(
        BuildConfig.googlePayConfigAsset,
      );
      final Map<String, dynamic> configMap = jsonDecode(jsonString);

      // 2. Try to override with dynamic config from storage (Shared Preferences)
      final dynamicConfig = await PaymentConfigService.getCachedConfig();

      // Get Merchant ID from storage OR use fallback
      final String merchantId =
          dynamicConfig?.googlepay?.merchantId ?? "BCR2DN7TRDA73ZCT";
      debugPrint('Initializing Google Pay with merchantId: $merchantId');

      if (configMap['data'] != null) {
        // A. Update Google Merchant ID
        if (configMap['data']['merchantInfo'] != null) {
          configMap['data']['merchantInfo']['merchantId'] = merchantId;
        }

        // B. Update Gateway Merchant ID (Cybersource)
        // Use cybersource merchantId from config, or fallback to 'anzapcau' (default in asset)
        final String gatewayMerchantId =
            dynamicConfig?.cybersource?.merchantId ?? "anzapcau";
        final allowedMethods =
            configMap['data']['allowedPaymentMethods'] as List?;
        if (allowedMethods != null && allowedMethods.isNotEmpty) {
          final tokenSpec = allowedMethods[0]['tokenizationSpecification'];
          if (tokenSpec != null && tokenSpec['parameters'] != null) {
            tokenSpec['parameters']['gatewayMerchantId'] = gatewayMerchantId;
          }
        }

        // C. Update Transaction Info (Default to 0.00, will be updated on click)
        if (configMap['data']['transactionInfo'] != null) {
          configMap['data']['transactionInfo']['totalPrice'] = (_amount ?? 0.0)
              .toStringAsFixed(2);
        }
      }

      // 3. Initialize Pay client
      _googlePayConfig = PaymentConfiguration.fromJsonString(
        jsonEncode(configMap),
      );
      _payClient = Pay({PayProvider.google_pay: _googlePayConfig!});

      _isGooglePayAvailable = await _payClient!.userCanPay(
        PayProvider.google_pay,
      );
      _setupPaymentResultListener();
      debugPrint('Google Pay initialized. Available: $_isGooglePayAvailable');
    } catch (e) {
      debugPrint('Error initializing Google Pay: $e');
      _isGooglePayAvailable = false;
    } finally {
      if (mounted) setState(() => _isInitializingGooglePay = false);
    }
  }

  void _setupPaymentResultListener() {
    const eventChannel = EventChannel('plugins.flutter.io/pay/payment_result');
    _paymentResultSubscription = eventChannel
        .receiveBroadcastStream()
        .map((r) => jsonDecode(r as String) as Map<String, dynamic>)
        .listen(
          (result) {
            debugPrint('Google Pay result received: $result');
            _handleGooglePayResult(result);
          },
          onError: (error) {
            debugPrint('Google Pay result error: $error');
            if (mounted) {
              setState(() {
                _isProcessing = false;
                _isWaitingForPaymentResult = false;
              });
              _navigateToPaymentFailure();
            }
          },
        );
  }

  Future<void> _handleGooglePayResult(
    Map<String, dynamic> paymentResult,
  ) async {
    // SECURITY: Only process if the user actually clicked the 'PAY NOW' button
    if (!_isWaitingForPaymentResult ||
        _isPaymentProcessing ||
        _hasNavigatedAway ||
        !mounted)
      return;

    _isWaitingForPaymentResult = false;

    try {
      _isPaymentProcessing = true;
      if (mounted) setState(() => _isProcessing = true);

      Map<String, dynamic>? orderData = await StorageService.getOrderData();
      final order = orderData?['order'] as Map<String, dynamic>?;
      final orderNumber = order?['order_number'] as String?;
      final orderId = _toInt(order?['id']);
      final amount = _amount ?? _toDouble(order?['pay_amount']) ?? 0.0;

      if (orderNumber == null) throw Exception('Order number not found');
      if (orderId == null) throw Exception('Order ID not found');

      debugPrint(
        'Processing Google Pay for order: $orderNumber (ID: $orderId), amount: $amount',
      );

      final response = await _paymentService.processGooglePay(
        orderNumber: orderNumber,
        orderId: orderId,
        amount: amount,
        paymentResult: paymentResult,
      );

      //debugPrint('***********payment sesssion start******');
      //debugPrint(const JsonEncoder.withIndent('  ').convert(response));
      //debugPrint('***********payment sesssion end******');

      final paymentToken = response['payment_token'] as String?;
      if (paymentToken != null && paymentToken.isNotEmpty) {
        _printLongString(paymentToken, 'GOOGLE_PAY_TOKEN_RAW');
        _printLongString(
          base64Encode(utf8.encode(paymentToken)),
          'GOOGLE_PAY_TOKEN_BASE64',
        );
      }

      // FINAL CLEANUP: Clear everything on success
      _paymentResultSubscription?.cancel();
      _paymentResultSubscription = null;

      if (!_isPayLater) {
        await StorageService.clearCartData();
        await StorageService.clearPaymentCartSnapshot();
      }
      await StorageService.clearOrderData();
      await StorageService.clearCheckoutData();

      if (mounted) {
        _hasNavigatedAway = true;
        _navigateToOrderSuccess(response, 'Google Pay');
      }
    } catch (e) {
      debugPrint('Google Pay error: $e');
      _isPaymentProcessing = false;
      _isWaitingForPaymentResult = false;
      // Do NOT clear cart on failure - user can retry.
      if (mounted) {
        _navigateToPaymentFailure();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isWaitingForPaymentResult = false;
        });
      }
    }
  }

  Future<void> _handleGooglePayClick() async {
    if (!_isGooglePayAvailable ||
        _payClient == null ||
        _googlePayConfig == null) {
      Fluttertoast.showToast(
        msg: 'Google Pay is not available on this device',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }
    if (_isProcessing || _isPaymentProcessing || _hasNavigatedAway) return;

    setState(() {
      _isProcessing = true;
      _isWaitingForPaymentResult = true;
    });

    try {
      // 1. Step A & B: Ensure order is created on server first (Normal Flow only)
      if (!_isPayLater &&
          !_isFromMyOrdersPayment &&
          (_orderId == null || _orderNumber == null)) {
        debugPrint(
          'Google Pay clicked: Creating order via store-order API first...',
        );
        final response = await _createOrderForDirectPayment();
        if (response == null) {
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _isWaitingForPaymentResult = false;
            });
          }
          return;
        }

        // CONDITIONAL FLOW: check process_payment
        if (response['process_payment'] == 0 &&
            response['show_order_success'] == 1) {
          _navigateToOrderSuccess(response, 'Google Pay');
          return;
        }
        debugPrint(
          'Order created successfully: $_orderNumber. Proceeding to Google Pay flow...',
        );
      } else if (_isFromMyOrdersPayment &&
          (_orderId == null || _orderNumber == null)) {
        throw Exception(
          'Order details not found. Please try again from the My Orders screen.',
        );
      }

      // 2. Re-initialize Google Pay configuration with the LATEST amount to ensure
      // the gateway total matches the UI total (especially if coupons were applied).
      await _initializeGooglePay();

      final paymentItems = [
        PaymentItem(
          label: 'Total',
          amount: (_amount ?? 0.0).toStringAsFixed(2),
          status: PaymentItemStatus.final_price,
        ),
      ];

      if (Platform.isAndroid) {
        await _payClient!.showPaymentSelector(
          PayProvider.google_pay,
          paymentItems,
        );
      } else {
        final result = await _payClient!.showPaymentSelector(
          PayProvider.google_pay,
          paymentItems,
        );
        _handleGooglePayResult(result);
      }
    } catch (e) {
      debugPrint('Google Pay Launch Error: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Google Pay failed. Please try again.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ─── Payment Initialization ────────────────────────────────────────────────

  /// Fallback breakdown from stored order data when shipping API cannot run.
  _ShippingBreakdown _breakdownFromStoredOrder(Map<String, dynamic> data) {
    final order = data['order'] as Map<String, dynamic>?;

    /// Helper to parse values to double with fallback to 0.0
    double parseOrZero(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      final clean = v
          .toString()
          .replaceAll(',', '')
          .replaceAll('\$', '')
          .replaceAll('AUD', '')
          .trim();
      return double.tryParse(clean) ?? 0.0;
    }

    double subtotalExclGst = parseOrZero(data['subtotal_excluding_gst']) > 0
        ? parseOrZero(data['subtotal_excluding_gst'])
        : (parseOrZero(data['totalPrice']) > 0
              ? parseOrZero(data['totalPrice'])
              : (parseOrZero(order?['pay_amount']) > 0
                    ? parseOrZero(order?['pay_amount'])
                    : parseOrZero(order?['subtotal'])));

    double gstAmount = parseOrZero(data['tax']) > 0
        ? parseOrZero(data['tax'])
        : parseOrZero(order?['tax_amount']);

    String orderType = _extractOrderType(data: data, order: order);

    // In PayLater flow server returns order_type:"normal" even for large
    // products. Fall back to scanning cart items (both top-level cart key and
    // order['cart']) for product_sizeType.
    if (orderType.isEmpty || orderType == 'normal') {
      final fromDataCart = _extractOrderTypeFromCartContainer(data);
      final fromOrderCart = (order?['cart'] is Map)
          ? _extractOrderTypeFromCartContainer({'cart': order!['cart']})
          : '';
      if (fromDataCart.isNotEmpty && fromDataCart != 'normal') {
        orderType = fromDataCart;
      } else if (fromOrderCart.isNotEmpty && fromOrderCart != 'normal') {
        orderType = fromOrderCart;
      }
    }

    final double rawShippingCost = (orderType == 'large')
        ? parseOrZero(order?['shipping_cost'])
        : parseOrZero(order?['normal_shipping_cost']);

    final effectiveShowRequestFreightCost =
        data['show_request_freight_cost'] ??
        _extractFreightCostFlagFromCartItems(data) ??
        ((order?['cart'] is Map)
            ? _extractFreightCostFlagFromCartItems({'cart': order!['cart']})
            : null);

    final effectiveShowFreeShippingIcon =
        data['show_free_shipping_icon'] ??
        _extractFreeShippingIconFromCartItems(data) ??
        ((order?['cart'] is Map)
            ? _extractFreeShippingIconFromCartItems({'cart': order!['cart']})
            : null);

    final freightRule = _resolveFreightRule(
      rawShippingCost: rawShippingCost,
      orderType: orderType,
      showRequestFreightCost: effectiveShowRequestFreightCost,
      showFreeShippingIcon: effectiveShowFreeShippingIcon,
      shippingType: data['shipping_type'] ?? data['shipping_type_method'],
    );

    final double totalAmount = parseOrZero(data['grand_total']) > 0
        ? parseOrZero(data['grand_total'])
        : (parseOrZero(order?['total']) > 0
              ? parseOrZero(order?['total'])
              : parseOrZero(order?['pay_amount']));

    final double discountAmount = parseOrZero(data['discount']) > 0
        ? parseOrZero(data['discount'])
        : parseOrZero(order?['discount']);

    final orderSource =
        data['order_source']?.toString().toLowerCase() ??
        order?['order_source']?.toString().toLowerCase() ??
        '';
    double specialDiscount = 0.0;
    if (orderSource == 'mobile') {
      specialDiscount = parseOrZero(order?['special_discount']);
    }

    // Subtotal logic synced with Order Details (Work backwards from Grand Total)
    subtotalExclGst =
        (totalAmount - gstAmount - freightRule.shippingCost + specialDiscount);

    return _ShippingBreakdown(
      subtotalExclGst: subtotalExclGst,
      shippingCost: freightRule.shippingCost,
      gstAmount: gstAmount,
      discountAmount: discountAmount,
      amount: totalAmount,
      specialDiscount: specialDiscount,
      hasPendingFreightQuote: freightRule.hasPendingFreightQuote,
      isPayLater: false,
      showFreeShippingLabel: freightRule.showFreeShippingLabel,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FREIGHT & BREAKDOWN CALCULATION
  // ─────────────────────────────────────────────────────────────────────────

  bool get _isPickupShipping => _shippingType == 'pickup';

  String _normalizeShippingType(dynamic value) {
    final normalized = value?.toString().toLowerCase().trim() ?? '';
    if (normalized == 'pickup' || normalized.contains('pickup')) {
      return 'pickup';
    }
    return 'shipto';
  }

  /// Centralized freight rule resolution logic
  /// Determines whether to charge shipping, show free label, or pending quote
  /// Based on order type, product flags, and freight rules
  _FreightRuleResult _resolveFreightRule({
    required double rawShippingCost,
    dynamic orderType,
    dynamic showRequestFreightCost,
    dynamic showFreeShippingIcon,
    String? shippingType,
  }) {
    final normalizedOrderType = (orderType ?? '').toString().toLowerCase();
    final requestFreightCost = _toDouble(showRequestFreightCost) ?? 0.0;
    final freeShippingIcon = _toDouble(showFreeShippingIcon) ?? 0.0;
    final isPickup = _normalizeShippingType(shippingType) == 'pickup';

    final hasPendingFreightQuote =
        normalizedOrderType == 'large' || requestFreightCost >= 1;
    // Pickup: customer collects from office — never show "free delivery" promo.
    final showFreeShippingLabel =
        !isPickup && !hasPendingFreightQuote && freeShippingIcon == 1;

    final shippingCost = hasPendingFreightQuote || showFreeShippingLabel
        ? 0.0
        : (rawShippingCost < 0 ? 0.0 : rawShippingCost);

    return _FreightRuleResult(
      shippingCost: shippingCost,
      hasPendingFreightQuote: hasPendingFreightQuote,
      showFreeShippingLabel: showFreeShippingLabel,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DATA EXTRACTION HELPERS
  // Safely extract and normalize common fields from responses
  // ─────────────────────────────────────────────────────────────────────────

  String _extractOrderType({
    Map<String, dynamic>? data,
    Map<String, dynamic>? order,
  }) {
    final raw =
        data?['order_type'] ??
        data?['product_sizeType'] ??
        order?['order_type'] ??
        order?['product_sizeType'] ??
        '';

    return raw.toString().toLowerCase().trim();
  }

  String _extractOrderTypeFromCartContainer(Map<String, dynamic>? data) {
    final cart = data?['cart'];
    if (cart is! Map) return '';

    for (final rawEntry in cart.values) {
      if (rawEntry is! Map) continue;

      final entry = Map<String, dynamic>.from(rawEntry as Map);
      final itemRaw = entry['item'];
      final item = itemRaw is Map ? Map<String, dynamic>.from(itemRaw) : null;

      final value =
          entry['order_type'] ??
          entry['product_sizeType'] ??
          item?['order_type'] ??
          item?['product_sizeType'];

      final normalized = value?.toString().toLowerCase().trim() ?? '';
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    return '';
  }

  /// Returns the first non-null `show_free_shipping_icon` found across all
  /// cart items (entry level first, then item sub-object).
  dynamic _extractFreeShippingIconFromCartItems(Map<String, dynamic>? data) {
    final cart = data?['cart'];
    if (cart is! Map) return null;

    for (final rawEntry in cart.values) {
      if (rawEntry is! Map) continue;
      final entry = rawEntry as Map;

      var value = entry['show_free_shipping_icon'];
      if (value != null) return value;

      final itemRaw = entry['item'];
      if (itemRaw is Map) {
        value = itemRaw['show_free_shipping_icon'];
        if (value != null) return value;
      }
    }

    return null;
  }

  /// Returns the first non-null `show_request_freight_cost` found across all
  /// cart items (entry level first, then item sub-object).
  dynamic _extractFreightCostFlagFromCartItems(Map<String, dynamic>? data) {
    final cart = data?['cart'];
    if (cart is! Map) return null;

    for (final rawEntry in cart.values) {
      if (rawEntry is! Map) continue;
      final entry = rawEntry as Map;

      var value = entry['show_request_freight_cost'];
      if (value != null) return value;

      final itemRaw = entry['item'];
      if (itemRaw is Map) {
        value = itemRaw['show_request_freight_cost'];
        if (value != null) return value;
      }
    }

    return null;
  }

  /// Safely parse any value to double, handling strings with currency symbols
  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      return double.tryParse(
        v.replaceAll(',', '').replaceAll('\$', '').replaceAll('AUD', '').trim(),
      );
    }
    return null;
  }

  /// Safely parse dynamic value to int (supports num/string input)
  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final cleaned = v.trim();
      if (cleaned.isEmpty) return null;
      return int.tryParse(cleaned);
    }
    return null;
  }

  /// Extract shipping cost from response, checking multiple possible keys
  double _extractShippingCostFromResponse(Map<String, dynamic> response) {
    return _toDouble(response['shipping']) ??
        _toDouble(response['normal_shipping_cost']) ??
        _toDouble(response['shipping_cost']) ??
        0.0;
  }

  /// Extract order type from data, checking multiple sources with fallback chain
  String _resolveOrderType({
    Map<String, dynamic>? data,
    Map<String, dynamic>? cartResponse,
  }) {
    final fromShipping = _extractOrderType(data: data);
    if (fromShipping.isNotEmpty) return fromShipping;

    final fromSnapshot = _extractOrderType(data: cartResponse);
    if (fromSnapshot.isNotEmpty) return fromSnapshot;

    return _extractOrderTypeFromCartContainer(cartResponse);
  }

  double _subtotalFromCartResponse(Map<String, dynamic> response) {
    final cart = response['cart'];
    if (cart is! Map) return 0.0;

    double subtotal = 0.0;
    for (final entry in cart.values) {
      if (entry is! Map) continue;
      final qty = _toDouble(entry['qty']) ?? 0.0;
      final price = _toDouble(entry['price']) ?? 0.0;
      subtotal += qty * price;
    }
    return subtotal;
  }

  bool get _isFromMyOrdersPayment =>
      widget.arguments?['from_my_orders_payment'] == true;

  // ─────────────────────────────────────────────────────────────────────────
  // CART RETRIEVAL
  // Prioritizes sources: arguments → snapshot → stored cart_data
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _getPaymentCartContainer() async {
    if (_isFromMyOrdersPayment) {
      // Prefer direct argument cart first (avoids storage roundtrip)
      final argCart = widget.arguments?['order_cart'];
      if (argCart is Map && argCart.isNotEmpty) {
        //debugPrint('PAYMENT_CART_SOURCE: my_orders_flow (order_cart argument) - ${argCart.length} items');
        return {'cart': Map<String, dynamic>.from(argCart as Map)};
      }
      // Fallback: read cart from the full order_data argument
      final argOrderData = widget.arguments?['order_data'];
      if (argOrderData is Map) {
        final cart = (argOrderData as Map)['cart'];
        if (cart is Map && cart.isNotEmpty) {
          //debugPrint('PAYMENT_CART_SOURCE: my_orders_flow (order_data argument cart) - ${cart.length} items');
          return {'cart': Map<String, dynamic>.from(cart as Map)};
        }
      }
      //debugPrint('PAYMENT_CART_SOURCE: my_orders_flow (no cart available)');
      return null;
    }

    final snapshot = await StorageService.getPaymentCartSnapshot();
    if (snapshot != null && snapshot['cart'] is Map) {
      final cartItems = (snapshot['cart'] as Map).length;
      //debugPrint('PAYMENT_CART_SOURCE: payment_cart_snapshot - $cartItems items');
      return snapshot;
    }

    //debugPrint('PAYMENT_CART_SOURCE: snapshot null/empty, trying cart_data fallback');
    final cartData = await StorageService.getCartData();
    if (cartData != null && cartData['cart'] is Map) {
      final cartItems = (cartData['cart'] as Map).length;
      //debugPrint('PAYMENT_CART_SOURCE: cart_data_fallback - $cartItems items');
      return cartData;
    }

    //debugPrint('PAYMENT_CART_SOURCE: all sources null/empty');
    return null;
  }

  /// Applies pricing fields from `/user/cart/shipping` (or compatible) response.
  void _applyPricingFromShippingResponse(
    Map<String, dynamic> shippingResponse,
  ) {
    _shippingCost = _toDouble(shippingResponse['shipping']) ?? 0.0;
    _gstAmount = _toDouble(shippingResponse['tax']) ?? 0.0;
    _discountAmount = _toDouble(shippingResponse['discount']) ?? 0.0;

    _totalCostExclGst = _toDouble(shippingResponse['total_cost_excl_gst']);
    _totalWithoutGst = _toDouble(shippingResponse['total_without_gst']);
    _totalWithGst = _toDouble(shippingResponse['total_with_gst']);

    if (_totalCostExclGst == null || _totalCostExclGst == 0) {
      _totalCostExclGst = _totalWithoutGst;
    }
    if (_totalWithoutGst == null || _totalWithoutGst == 0) {
      _totalWithoutGst = _totalCostExclGst;
    }

    _subtotalExclGst = _totalCostExclGst;

    final shippingTotalWithGst = _totalWithGst;
    if (shippingTotalWithGst != null && shippingTotalWithGst > 0) {
      _amount = shippingTotalWithGst;
    } else {
      _amount =
          (_totalWithoutGst ?? 0) +
          (_gstAmount ?? 0) +
          (_shippingCost ?? 0) -
          (_discountAmount ?? 0);
      _totalWithGst = (_totalWithoutGst ?? 0) + (_gstAmount ?? 0);
      debugPrint(
        'REFRESH_PRICING: total_with_gst was 0 or null, calculated local totals',
      );
    }
  }

  /// Refresh all totals and breakdown from the centralized Shipping API.
  /// Returns true when pricing was loaded successfully.
  Future<bool> _refreshPricing({
    required String postcode,
    required dynamic oldCart,
  }) async {
    try {
      final bool isMyOrders = _isFromMyOrdersPayment;
      final Map<String, dynamic> shippingPayload;

      if (isMyOrders) {
        // 1. PayLater Case (My Orders Payment Flow)
        shippingPayload = {
          'order_id': _orderId.toString(), // Pass as String to match Postman
          'postcode': "",
          'code': "",
          'shipping_type_method': "",
          'old_cart': "",
        };
        debugPrint(
          'REFRESH_PRICING: PayLater Case Payload: ${jsonEncode(shippingPayload)}',
        );
      } else {
        // 2. Normal Flow Case (Standard Checkout)
        final checkoutData = await StorageService.getCheckoutData();
        final shippingMethod =
            checkoutData?['shipping_method'] as String? ?? 'Ship to Address';
        final shippingTypeMethod = shippingMethod == 'Pickup'
            ? 'pickup'
            : 'shipto';
        _shippingType = shippingTypeMethod;

        shippingPayload = {
          'order_id': "", // Empty or null for normal flow
          'postcode': postcode,
          'old_cart': oldCart,
          'code': _couponCode ?? "",
          'shipping_type_method': shippingTypeMethod,
        };
        debugPrint(
          'REFRESH_PRICING: Normal Flow Payload: ${jsonEncode(shippingPayload)}',
        );
      }

      final shippingResponse = await _cartService.calculateShipping(
        shippingPayload,
      );

      if (mounted) {
        setState(() {
          _pricingLoadFailed = false;
          _applyPricingFromShippingResponse(shippingResponse);

          // Only use freight rule to determine UI flag state (pending quote / free label),
          // NOT to override _shippingCost (API already returns the correct value).
          final orderType = _extractOrderType(data: shippingResponse);
          _shippingType = _normalizeShippingType(
            shippingResponse['shipping_type'] ??
                shippingResponse['shipping_type_method'],
          );

          final freightRule = _resolveFreightRule(
            rawShippingCost: _shippingCost!,
            orderType: orderType,
            showRequestFreightCost: shippingResponse['show_freight_cost_icon'],
            showFreeShippingIcon: shippingResponse['show_free_shipping_icon'],
            shippingType: _shippingType,
          );
          _hasPendingFreightQuote = freightRule.hasPendingFreightQuote;
          debugPrint(
            'REFRESH_PRICING: shipping_type=$_shippingType, show_freight_icon=${shippingResponse['show_freight_cost_icon']}, show_free_shipping_icon=${shippingResponse['show_free_shipping_icon']}, hasPendingFreightQuote=$_hasPendingFreightQuote',
          );
          _showFreeShippingLabel = freightRule.showFreeShippingLabel;
          _shippingTag = shippingResponse['shipping_tag']?.toString();

          // Set _isPayLater based on the API response flag
          _isPayLater = shippingResponse['paylater']?.toString() == '1';
          debugPrint(
            'REFRESH_PRICING: _isPayLater set to $_isPayLater (raw: ${shippingResponse['paylater']})',
          );

          // NOTE: We intentionally do NOT use freightRule.shippingCost here
          // because _shippingCost is already set from the API response above.
        });
      }
      return true;
    } catch (e) {
      debugPrint('Error refreshing pricing: $e');
      if (mounted) {
        setState(() => _pricingLoadFailed = true);
        _showShippingPricingErrorToast(e);
      }
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAYMENT INITIALIZATION
  // Loads order data, calculates breakdown, initializes payment status flags
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _initializePayment() async {
    try {
      //debugPrint('=== PAYMENT PAGE INITIALIZATION ===');

      // For PayLater flow, prefer the full response passed directly as argument
      // so we have the cart (product_sizeType etc.) without a storage roundtrip.
      Map<String, dynamic>? orderData =
          (widget.arguments?['order_data'] as Map?)?.cast<String, dynamic>() ??
          await StorageService.getOrderData();

      debugPrint(
        'Order data: ${orderData != null ? "Found (from: ${widget.arguments?['order_data'] != null ? 'argument' : 'storage'})" : "Not found"}',
      );

      // DEFERRED: For direct normal checkout, we no longer call _createOrderForDirectPayment
      // during initialization. Instead, we call it when the user clicks 'PAY NOW'.
      // This allows the user to see the breakdown and apply coupons before the order is created on the server.

      final resolvedOrderData = orderData;

      setState(() {
        _orderData = resolvedOrderData;
        if (resolvedOrderData != null) {
          final statusRoot = (resolvedOrderData['order_status'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          final statusOrder =
              (resolvedOrderData['order']?['order_status'] ?? '')
                  .toString()
                  .toLowerCase()
                  .trim();
          _isAwaitingFreight =
              statusRoot.contains('awaiting') ||
              statusOrder.contains('awaiting');
          debugPrint(
            'Freight Status Detected: $_isAwaitingFreight (Root: $statusRoot, Order: $statusOrder)',
          );
        } else {
          _isAwaitingFreight = false;
        }
      });

      final order = resolvedOrderData?['order'] as Map<String, dynamic>?;
      final orderNumber = order?['order_number'] as String?;
      final orderId = _toInt(order?['id']);

      setState(() {
        if (orderNumber != null) _orderNumber = orderNumber;
        if (orderId != null) _orderId = orderId;
      });

      // Initialize status-based flags
      _manualOrderByAdmin = _toInt(order?['manual_order_by_admin']) ?? 0;
      _orderPaymentStatus = (order?['payment_status'] ?? '')
          .toString()
          .toLowerCase();

      // Retrieve trade user status from StorageService
      final UserModel? currentUser = await StorageService.getUserData();
      final int tradeUserFlag = currentUser?.isTradeUser ?? 0;

      final payAmount = _toDouble(order?['pay_amount']);
      final totalAmount = _toDouble(order?['total']);
      double amount = payAmount ?? totalAmount ?? 0.0;

      // If orderData is null (normal checkout), these will be null initially.
      // This is acceptable as they will be populated when 'PAY NOW' is clicked.
      if (orderNumber != null && orderId != null) {
        debugPrint('Pre-existing order found: $orderNumber (ID: $orderId)');
      } else {
        debugPrint(
          'No pre-existing order. store-order API will be called on payment click.',
        );
      }

      double? subtotalExclGst;
      double? shippingCost;
      double? gstAmount;
      double? discountAmount;

      try {
        final checkoutData = await StorageService.getCheckoutData();
        final checkoutShippingMethod =
            checkoutData?['shipping_method'] as String? ?? 'Ship to Address';
        _shippingType = checkoutShippingMethod == 'Pickup'
            ? 'pickup'
            : 'shipto';
        final postcode = (checkoutData?['post_code'] as String?)?.trim() ?? '';
        final cartResponse = await _getPaymentCartContainer();
        final oldCart = cartResponse?['cart'] as Map<String, dynamic>?;
        final bool fromMyOrdersPayment =
            widget.arguments?['from_my_orders_payment'] == true;

        String activePostcode = postcode;
        if (fromMyOrdersPayment && resolvedOrderData != null) {
          final orderObj = resolvedOrderData['order'] as Map<String, dynamic>?;
          activePostcode =
              (orderObj?['shipping_zip']?.toString().trim()) ??
              (orderObj?['zip']?.toString().trim()) ??
              postcode;
        }

        //debugPrint('DEBUG_PAYMENT_INIT: fromMyOrdersPayment=$fromMyOrdersPayment, postcode="$activePostcode", hasOldCart=${oldCart != null}');

        if (activePostcode.isNotEmpty && oldCart != null) {
          _postcode = activePostcode;
          _oldCart = oldCart;
          // Ensure we have an order ID for PayLater flow before refreshing
          if (fromMyOrdersPayment && _orderId == null && orderId != null) {
            _orderId = orderId;
          }
          await _refreshPricing(postcode: activePostcode, oldCart: oldCart);
        } else {
          // Fallback for missing data
          final snap = _breakdownFromStoredOrder(resolvedOrderData ?? {});
          setState(() {
            _totalCostExclGst = snap.subtotalExclGst;
            _totalWithoutGst = snap.subtotalExclGst;
            _totalWithGst = snap.amount;
            _subtotalExclGst = snap.subtotalExclGst;
            _shippingCost = snap.shippingCost;
            _gstAmount = snap.gstAmount;
            _discountAmount = snap.discountAmount;
            _amount = snap.amount;
            _hasPendingFreightQuote = snap.hasPendingFreightQuote;
            _showFreeShippingLabel =
                !_isPickupShipping && snap.showFreeShippingLabel;
            _shippingTag =
                (resolvedOrderData?['shipping_tag'] ??
                        resolvedOrderData?['order']?['shipping_tag'])
                    ?.toString();
          });
        }
      } catch (e) {
        debugPrint('Error preparing payment breakdown: $e');
        final snap = _breakdownFromStoredOrder(orderData ?? {});
        subtotalExclGst = snap.subtotalExclGst;
        shippingCost = snap.shippingCost;
        gstAmount = snap.gstAmount;
        discountAmount = snap.discountAmount;
        amount = snap.amount;
        _hasPendingFreightQuote = snap.hasPendingFreightQuote;
        _showFreeShippingLabel = snap.showFreeShippingLabel;
      }

      // When user comes from My Orders → Pay Now, we usually show payment UI.
      // BUT Pay Later UI mode is controlled by both argument AND API flag.
      final bool argIsPayLater = widget.arguments?['is_pay_later'] == true;
      final bool isCheckoutFreightPayment =
          widget.arguments?['checkout_freight_payment'] == true;

      // If already true from API (_refreshPricing), keep it. Otherwise check arguments.
      if (!_isPayLater) {
        _isPayLater = argIsPayLater && !isCheckoutFreightPayment;
      }

      setState(() {
        _orderNumber = orderNumber;
        _orderId = orderId;
        _isTradeUser = tradeUserFlag;
        _currency = 'AUD';

        // ONLY set these from local variables if they haven't been set by _refreshPricing already
        if (_amount == null || _amount == 0) {
          _amount = amount > 0 ? amount : 0.0;
        }
        if (_shippingCost == null || _shippingCost == 0) {
          _shippingCost = shippingCost ?? 0.0;
        }
        if (_gstAmount == null || _gstAmount == 0) {
          _gstAmount = gstAmount ?? 0.0;
        }
        if (_discountAmount == null || _discountAmount == 0) {
          _discountAmount = discountAmount ?? 0.0;
        }

        _orderSource =
            (_orderData?['order_source'] ?? order?['order_source'] ?? '')
                .toString()
                .toLowerCase();

        final dynamic rawDisc =
            _orderData?['special_discount'] ?? order?['special_discount'];
        if (_orderSource == 'mobile' && rawDisc != null) {
          final String cleanPrice = rawDisc
              .toString()
              .replaceAll(',', '')
              .replaceAll('\$', '')
              .trim();
          _specialDiscount = double.tryParse(cleanPrice) ?? 0.0;
        } else {
          _specialDiscount = 0.0;
        }

        // Mathematically consistent Subtotal fallback
        if (_totalCostExclGst == null || _totalCostExclGst == 0) {
          _totalCostExclGst =
              (_amount! -
              _gstAmount! -
              _shippingCost! +
              (_specialDiscount ?? 0.0));
          _subtotalExclGst = _totalCostExclGst;
        }
        if (_totalWithoutGst == null || _totalWithoutGst == 0) {
          _totalWithoutGst = _totalCostExclGst;
        }
        if (_totalWithGst == null || _totalWithGst == 0) {
          _totalWithGst = _amount;
        }

        // ABSOLUTE OVERRIDE: If we have explicit values from Order Details, use them exactly.
        // BUT: For My Orders flow, we ignore these arguments because we just refreshed
        // with the fresh /user/cart/shipping API which is the new source of truth.
        if (!_isFromMyOrdersPayment &&
            widget.arguments?['summary_grand_total'] != null) {
          _amount =
              _toDouble(widget.arguments?['summary_grand_total']) ?? _amount;
          _gstAmount =
              _toDouble(widget.arguments?['summary_tax']) ?? _gstAmount;
          _shippingCost =
              _toDouble(widget.arguments?['summary_shipping']) ?? _shippingCost;
          _discountAmount =
              _toDouble(widget.arguments?['summary_discount']) ??
              _discountAmount;
          _specialDiscount =
              _toDouble(widget.arguments?['summary_special_discount']) ??
              _specialDiscount;
          _totalCostExclGst =
              _toDouble(widget.arguments?['summary_total_cost_excl_gst']) ??
              _toDouble(widget.arguments?['summary_subtotal']) ??
              _totalCostExclGst;
          _totalWithoutGst =
              _toDouble(widget.arguments?['summary_total_without_gst']) ??
              _toDouble(widget.arguments?['summary_subtotal']) ??
              _totalWithoutGst;
          _totalWithGst =
              _toDouble(widget.arguments?['summary_total_with_gst']) ??
              _toDouble(widget.arguments?['summary_grand_total']) ??
              _totalWithGst;
          _subtotalExclGst = _totalCostExclGst;
        }

        if (_gstAmount! > 0 && (_totalWithoutGst ?? 0) > 0) {
          _gstRate = (_gstAmount! / _totalWithoutGst!) * 100;
        } else {
          _gstRate = 10.0;
        }

        final argMethod = widget.arguments?['payment_method']?.toString();
        if ((_selectedPaymentMethod).isEmpty &&
            argMethod != null &&
            argMethod.isNotEmpty) {
          _selectedPaymentMethod = argMethod;
        }
        _isLoading = false;
      });

      if (mounted) {
        final cartSnap = await _getPaymentCartContainer();
        if (mounted) {
          setState(() {
            _couponCode = CouponCartDisplay.couponCode(cartSnap);
            _couponOfferSubtitle = CouponCartDisplay.offerSubtitle(cartSnap);
            _couponDiscount = CouponCartDisplay.savingsFromCart(
              cartSnap,
              grandTotalAfter: _amount,
            );
            _isCouponApplied = _couponCode != null && _couponCode!.isNotEmpty;
            if (_isCouponApplied) {
              _couponController.text = _couponCode!;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing payment: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _createOrderForDirectPayment() async {
    // Guard: If an order has already been created for this session, reuse it.
    // This prevents duplicate orders if the user switches payment methods after a failure.
    if (_orderId != null && _orderNumber != null) {
      debugPrint(
        'Order already exists: $_orderNumber (ID: $_orderId). Skipping creation.',
      );
      return _orderData;
    }

    try {
      final userData = await StorageService.getUserData();
      if (userData == null) {
        Fluttertoast.showToast(msg: 'Please login to continue');
        return null;
      }

      final cartResponse = await _getPaymentCartContainer();
      if (cartResponse == null || cartResponse['cart'] == null) {
        Fluttertoast.showToast(msg: 'Cart is empty');
        return null;
      }

      final checkoutData = await StorageService.getCheckoutData();
      if (checkoutData == null) {
        Fluttertoast.showToast(msg: 'Please complete checkout form');
        return null;
      }

      final payload = _buildOrderPayload(
        userData: userData,
        cartResponse: cartResponse,
        checkoutData: checkoutData,
      );
      payload['payment_method'] =
          widget.arguments?['payment_method'] ?? 'Credit Card';

      final response = await _orderService.storeOrder(payload);

      final order = response['order'] as Map<String, dynamic>?;
      final orderNumber = order?['order_number'] as String?;
      if (orderNumber == null || orderNumber.isEmpty) {
        Fluttertoast.showToast(msg: 'Failed to place order. Please try again.');
        return null;
      }

      await StorageService.saveOrderData(response);

      // SAVE SNAPSHOT before clearing: This allows us to re-calculate shipping
      // if the user navigates back and forth, even though the main cart is cleared.
      if (cartResponse != null) {
        await StorageService.savePaymentCartSnapshot(cartResponse);
      }

      // Update state with new order data
      if (mounted) {
        setState(() {
          _orderData = response;
          _orderNumber = orderNumber;
          _orderId = _toInt(order?['id']);

          // Set additional flags to avoid redundant _initializePayment() calls
          final statusRoot = (response['order_status'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          final statusOrder = (order?['order_status'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          _isAwaitingFreight =
              statusRoot.contains('awaiting') ||
              statusOrder.contains('awaiting');

          _manualOrderByAdmin = _toInt(order?['manual_order_by_admin']) ?? 0;
          _orderPaymentStatus = (order?['payment_status'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
        });
      }

      // Clear the main cart data now that the order is successfully placed on the server.
      // This prevents the items from remaining in the cart if the user navigates back
      // after a payment failure, which would lead to duplicate orders.
      await StorageService.clearCartData();

      return response;
    } on ApiException catch (_) {
      return null;
    } catch (e) {
      debugPrint('Error creating order for direct payment: $e');
      Fluttertoast.showToast(msg: 'Failed to place order. Please try again.');
      return null;
    }
  }

  Map<String, dynamic> _buildOrderPayload({
    required UserModel userData,
    required Map<String, dynamic> cartResponse,
    required Map<String, dynamic> checkoutData,
  }) {
    final cart = cartResponse['cart'] as Map<String, dynamic>? ?? {};
    final shippingMethod =
        checkoutData['shipping_method'] as String? ?? 'Ship to Address';
    final shipping = shippingMethod == 'Pickup' ? 'pickup' : 'shipto';

    dynamic pickupLocationId = '';
    if (shipping == 'pickup') {
      final raw = checkoutData['pickup_location'];
      if (raw != null && raw.toString().isNotEmpty) {
        if (raw is int) {
          pickupLocationId = raw;
        } else {
          pickupLocationId = int.tryParse(raw.toString()) ?? '';
        }
      }
    }

    String deviceType = 'other';
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        deviceType = 'android';
      } else if (Platform.isIOS) {
        deviceType = 'iphone';
      }
    }

    return <String, dynamic>{
      'cart': cart,
      'user_id': userData.id,
      'email': userData.email,
      'coupon_id': '',
      'multi_coupon_id': '',
      'coupon_code': _couponCode ?? '',
      'coupon_discount': _couponDiscount,
      'shipping': shipping,
      'pickup_location': pickupLocationId,
      'order_notes': checkoutData['order_note'] as String? ?? '',
      'ship_diff_address': 0,
      'dp': 0,
      'vendor_shipping_id': 1,
      'vendor_packing_id': 1,
      'order_source': 'mobile',
      'order_source_device': deviceType,
      'shipping_name': '',
      'shipping_email': '',
      'shipping_phone': '',
      'shipping_landline': '',
      'shipping_area_code': '',
      'shipping_unit_apartmentno': '',
      'shipping_address': '',
      'shipping_address1': '',
      'shipping_city': '',
      'shipping_state': '',
      'shipping_country': 'AU',
      'shipping_zip': '',
      'name': checkoutData['name'] as String? ?? userData.name,
      'companyname': checkoutData['company'] as String? ?? '',
      'phone': checkoutData['mobile'] as String? ?? userData.phone,
      'landline':
          checkoutData['landline'] as String? ?? userData.landline ?? '',
      'area_code':
          checkoutData['area_code'] as String? ?? userData.areaCode ?? '',
      'unit_apartmentno':
          checkoutData['unit'] as String? ?? userData.unitApartmentNo ?? '',
      'address': checkoutData['address'] as String? ?? userData.address ?? '',
      'address1': '',
      'city': checkoutData['suburb'] as String? ?? userData.city ?? '',
      'state': checkoutData['state'] as String? ?? userData.state ?? '',
      'country': 'AU',
      'zip': checkoutData['post_code'] as String? ?? userData.zip ?? '',
    };
  }

  void _navigateToOrderSuccess(Map<String, dynamic> response, String method) {
    if (!mounted) return;

    Fluttertoast.showToast(
      msg: 'Order placed successfully!',
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/order-placed',
      (route) => false,
      arguments: {
        'payment_token':
            response['transaction_id'] ??
            response['paymentId'] ??
            response['paymentID'] ??
            response['order']?['order_number'] ??
            _orderNumber,
        'payment_method': method,
      },
    );
  }

  void _navigateToPaymentFailure({String? orderNumber, String? paymentId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentFailureScreen(
          isPayLater: _isPayLater,
          orderNumber: orderNumber,
          paymentId: paymentId,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAYMENT PROCESSING
  // Handles direct card, PayPal, Google Pay, and Pay Later flows
  // ─────────────────────────────────────────────────────────────────────────

  /// Handle payment submission (Native direct API integration)
  Future<void> _handlePayment() async {
    // 0. Validation and Multiple Click Prevention
    if (!_formKey.currentState!.validate() || _isProcessing) {
      if (!_formKey.currentState!.validate()) {
        Fluttertoast.showToast(msg: 'Please fill all card details correctly.');
      }
      return;
    }

    setState(() => _isProcessing = true);
    debugPrint('=== _handlePayment (Direct API) START ===');

    try {
      // 1. Step A & B: Ensure order is created on server first (Normal Flow only)
      if (!_isPayLater &&
          !_isFromMyOrdersPayment &&
          (_orderId == null || _orderNumber == null)) {
        debugPrint(
          'Payment clicked: Creating order via store-order API first...',
        );
        final response = await _createOrderForDirectPayment();
        if (response == null) {
          if (mounted) setState(() => _isProcessing = false);
          return;
        }

        // CONDITIONAL FLOW: check process_payment
        if (response['process_payment'] == 0 &&
            response['show_order_success'] == 1) {
          _navigateToOrderSuccess(response, 'Credit Card');
          return;
        }

        debugPrint(
          'Order created successfully: $_orderNumber. Proceeding to payment...',
        );
      } else if (_isFromMyOrdersPayment &&
          (_orderId == null || _orderNumber == null)) {
        throw Exception(
          'Order details not found. Please try again from the My Orders screen.',
        );
      }

      // 3. Process expiry - MM/YY format to MM and YYYY
      final expiryValue = _expiryController.text.trim();
      final expiryParts = expiryValue.split('/');
      if (expiryParts.length != 2) throw Exception('Invalid expiry format');

      final String month = expiryParts[0].padLeft(2, '0');
      String year = expiryParts[1].trim();
      if (year.length == 2) {
        year = '20$year'; // Convert YY to YYYY
      }

      // 4. Call direct API for Payment Processing
      final response = await _paymentService.processCardPaymentRaw(
        orderId: _orderId!,
        orderNumber: _orderNumber!,
        amount: _amount ?? 0.0,
        currency: 'AUD',
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        expiryMonth: month,
        expiryYear: year,
        cvv: _cvvController.text.trim(),
        cardholderName: _cardholderNameController.text.trim(),
      );

      //debugPrint('***********payment sesssion start******');
      //debugPrint(const JsonEncoder.withIndent('  ').convert(response));
      //debugPrint('***********payment sesssion end******');

      // 3. Handle successful payment
      // Response format: { 'order': {...}, 'process_payment': 0, 'show_order_success': 1 }
      if (response['show_order_success'] == 1 ||
          response['payment_status'] == 'completed' ||
          response['order_status'] == 'paid' ||
          response['success'] == true) {
        // Clear cart as payment was successful (Normal Flow only)
        if (!_isPayLater) {
          await StorageService.clearCartData();
          await StorageService.clearPaymentCartSnapshot();
        }
        await StorageService.clearOrderData();
        await StorageService.clearCheckoutData();

        if (mounted) {
          _navigateToOrderSuccess(response, 'Credit Card');
        }
      } else {
        throw Exception(
          response['message'] ?? 'Payment failed. Please try again.',
        );
      }
    } on ApiException catch (e) {
      //debugPrint('***********payment sesssion start******');
      //debugPrint(const JsonEncoder.withIndent('  ').convert(e.responseData ?? {'message': e.message}));
      // debugPrint('***********payment sesssion end******');
      if (mounted) setState(() => _isProcessing = false);
      _navigateToPaymentFailure();
      Fluttertoast.showToast(msg: e.message);
    } catch (e) {
      debugPrint('Direct API payment error: $e');
      // IMPORTANT: Do NOT clear cart on failure.
      // User should be able to modify order and retry payment.
      // Cart is only cleared on SUCCESSFUL payment.
      if (mounted) {
        String errMsg = 'Payment failed. Please try again.';
        if (e.toString().contains('card_declined')) {
          errMsg = 'Your card was declined. Please try a different card.';
        } else if (e.toString().contains('invalid_cvv')) {
          errMsg = 'Invalid CVV. Please check your card details.';
        } else if (e.toString().contains('expired_card')) {
          errMsg = 'Your card has expired. Please use a different card.';
        } else if (e is Exception) {
          errMsg = e.toString().replaceAll('Exception: ', '');
        }

        _navigateToPaymentFailure();
        Fluttertoast.showToast(
          msg: errMsg,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Handle PayPal payment
  /*
  Future<void> _handlePayPalPayment() async {
    if (_isProcessing) return;

    // ─── TEMPORARY: Pause PayPal, open test URL ───
    /*const String _tempPaypalUrl =
        'https://www.gurgaonit.com/apc_production_dev/payment/paypal/MzMwMDM=';
    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _PayPalWebViewScreen(
            approvalUrl: _tempPaypalUrl,
            returnUrl: 'https://www.apc.com.au/payment/success',
            cancelUrl: 'https://www.apc.com.au/payment/cancel',
          ),
        ),
      );
    }
    return;*/
    // ─── END TEMPORARY ───────────────────────────

    setState(() => _isProcessing = true);

    try {
      // 1. Step A & B: Ensure order is created on server first (Normal Flow only)
      if (!_isPayLater &&
          !_isFromMyOrdersPayment &&
          (_orderId == null || _orderNumber == null)) {
        debugPrint(
          'PayPal clicked: Creating order via store-order API first...',
        );
        final response = await _createOrderForDirectPayment();
        if (response == null) {
          if (mounted) setState(() => _isProcessing = false);
          return;
        }

        // CONDITIONAL FLOW: check process_payment
        if (response['process_payment'] == 0 &&
            response['show_order_success'] == 1) {
          _navigateToOrderSuccess(response, 'PayPal');
          return;
        }

        debugPrint(
          'Order created successfully: $_orderNumber. Proceeding to PayPal flow...',
        );
      } else if (_isFromMyOrdersPayment &&
          (_orderId == null || _orderNumber == null)) {
        throw Exception(
          'Order details not found. Please try again from the My Orders screen.',
        );
      }

      if (_paypalConfig == null ||
          _paypalConfig!['client_key'] == null ||
          _paypalConfig!['secret_key'] == null) {
        debugPrint('PayPal keys missing, attempting refresh...');
        await _loadPayPalConfig();
      }

      final String? clientId = _paypalConfig?['client_key']?.toString();
      final String? secretKey = _paypalConfig?['secret_key']?.toString();
      final bool isSandbox = _paypalConfig?['mode'] == 'sandbox';

      if (clientId == null || secretKey == null) {
        throw Exception(
          'PayPal configuration could not be loaded. Please check your internet connection.',
        );
      }

      // MATHEMATICAL FIX: PayPal requires (subtotal + shipping + tax - discount) == total
      final double paypalTotal = _amount!;
      final double paypalTax = _gstAmount!;
      final double paypalShipping = _shippingCost!;
      final double paypalDiscount = _discountAmount!;
      final double paypalSubtotal =
          paypalTotal - paypalTax - paypalShipping + paypalDiscount;

      debugPrint(
        'Launching PayPal Webview for Order #$_orderNumber (Amount: $_amount)',
      );
      if (mounted) {
        // Get access token first
        final accessToken = await _paymentService.getPaypalAccessToken(
          clientId: clientId!,
          secretKey: secretKey!,
          isSandbox: isSandbox,
        );

        if (accessToken == null) {
          throw Exception('Failed to get PayPal access token.');
        }

        // Create PayPal payment and get approval URL
        final paypalPaymentData = await _paymentService.createPaypalPayment(
          accessToken: accessToken,
          isSandbox: isSandbox,
          total: paypalTotal,
          subtotal: paypalSubtotal,
          tax: paypalTax,
          shipping: paypalShipping,
          discount: paypalDiscount,
          currency: _currency ?? 'AUD',
          orderNumber: _orderNumber!,
          returnUrl: 'https://www.apc.com.au/payment/success',
          cancelUrl: 'https://www.apc.com.au/payment/cancel',
        );

        final approvalUrl = paypalPaymentData['approvalUrl'] as String?;
        final paymentId = paypalPaymentData['paymentId'] as String?;

        if (approvalUrl == null)
          throw Exception('No PayPal approval URL received.');
        debugPrint('PayPal approval URL: $approvalUrl');

        final result = await Navigator.of(context).push<Map<String, String?>>(
          MaterialPageRoute(
            builder: (_) => _PayPalWebViewScreen(
              approvalUrl: approvalUrl,
              returnUrl: 'https://www.apc.com.au/payment/success',
              cancelUrl: 'https://www.apc.com.au/payment/cancel',
            ),
          ),
        );

        debugPrint('PayPal WebView result: $result');

        if (result == null || result['status'] == 'cancelled') {
          debugPrint('PayPal: Cancelled or no result.');
          // _navigateToPaymentFailure();
          return;
        }

        if (result['status'] == 'success') {
          final returnedPaymentId = result['paymentId'] ?? paymentId ?? '';
          final payerId = result['payerId'] ?? '';
          final token = result['token'] ?? '';

          debugPrint(
            'PayPal success: paymentId=$returnedPaymentId, payerId=$payerId',
          );

          if (mounted) setState(() => _isProcessing = true);
          try {
            debugPrint(
              'Finalizing PayPal on server for order: #$_orderNumber (ID: $_orderId)',
            );
            final paypalResult = {
              'status': 'success',
              'paymentId': returnedPaymentId,
              'paymentID': returnedPaymentId,
              'payerID': payerId,
              'token': token,
            };
            final serverResponse = await _paymentService.processPayPal(
              orderNumber: _orderNumber!,
              orderId: _orderId!,
              amount: _amount!,
              currency: _currency ?? 'AUD',
              paymentResult: paypalResult,
            );

            if (!_isPayLater) {
              await StorageService.clearCartData();
              await StorageService.clearPaymentCartSnapshot();
            }
            await StorageService.clearOrderData();
            await StorageService.clearCheckoutData();

            if (mounted) {
              _navigateToOrderSuccess({
                ...paypalResult,
                ...serverResponse,
              }, 'PayPal');
            }
          } catch (e) {
            debugPrint('Error finalizing PayPal on backend: $e');
            if (mounted) {
              Fluttertoast.showToast(
                msg:
                    'Verification failed. Order: #$_orderNumber. Please contact support.',
                backgroundColor: Colors.red,
                textColor: Colors.white,
                toastLength: Toast.LENGTH_LONG,
              );
              _navigateToPaymentFailure(orderNumber: _orderNumber);
            }
          } finally {
            if (mounted) setState(() => _isProcessing = false);
          }
        }
      }
    } catch (e) {
      debugPrint('PayPal Error: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: e.toString().replaceAll('Exception: ', ''),
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
  */

  /* new updated method for paypal */

  // ─────────────────────────────────────────────────────────────────────────
  // REPLACEMENT FOR _handlePayPalPayment() in payment.dart
  //
  // OLD approach: Flutter calls PayPal REST API directly, opens approval URL
  //               in _PayPalWebViewScreen.
  //
  // NEW approach (SDD §4): Flutter opens Laravel's /payment page in WebView.
  //               Laravel hosts the full PayPal JS SDK page.
  //               Result comes back via PayPalResult JavaScript channel.
  //
  // REQUIRED: import 'package:apcproject/ui/screens/payment_page/payment_webview.dart';
  // ─────────────────────────────────────────────────────────────────────────

  /// Handle PayPal payment — JS SDK WebView approach (SDD §4)
  Future<void> _handlePayPalPayment() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // ── Step 1: Ensure order is created on server (Normal Flow only) ──────
      if (!_isPayLater &&
          !_isFromMyOrdersPayment &&
          (_orderId == null || _orderNumber == null)) {
        debugPrint(
          'PayPal (JS SDK): Creating order via store-order API first...',
        );
        final response = await _createOrderForDirectPayment();
        if (response == null) {
          if (mounted) setState(() => _isProcessing = false);
          return;
        }
        if (response['process_payment'] == 0 &&
            response['show_order_success'] == 1) {
          _navigateToOrderSuccess(response, 'PayPal');
          return;
        }
        debugPrint(
          'Order created: $_orderNumber. Opening PayPal JS SDK page...',
        );
      } else if (_isFromMyOrdersPayment &&
          (_orderId == null || _orderNumber == null)) {
        throw Exception(
          'Order details not found. Please try again from the My Orders screen.',
        );
      }

      if (!mounted) return;
      setState(
        () => _isProcessing = false,
      ); // release lock while WebView is open

      // ── Step 2: Open Laravel payment page in WebView ──────────────────────
      // Laravel hosts /payment?amount=X&currency=AUD&ref=ORDER_NUMBER
      // The page loads PayPal JS SDK and posts result via window.PayPalResult
      final Map<String, dynamic>?
      result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => PaymentWebView(
            amount: _amount ?? 0.0,
            currency: _currency ?? 'AUD',
            orderRef: base64Encode(utf8.encode(_orderId?.toString() ?? '')),
            onPaymentResult: (res) {
              // Callback fires when JS calls window.PayPalResult.postMessage(...)
              debugPrint('PayPal JS SDK result callback: $res');
            },
          ),
        ),
      );

      debugPrint('PayPal WebView dismissed. Result: $result');

      if (result == null || result['status'] == 'cancelled') {
        debugPrint(
          'PayPal: Cancelled or dismissed by user (X button / back press). Navigating to MyOrders.',
        );
        if (mounted) setState(() => _isProcessing = false);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MyOrdersPage()),
          );
        }
        return;
      }

      // ── Step 3: Handle success from JS SDK ────────────────────────────────
      if (result['status'] == 'COMPLETED') {
        if (mounted) setState(() => _isProcessing = true);

        final String? paymentSource = result['source']?.toString();
        final bool isUrlRedirect = paymentSource == 'url_redirect';

        debugPrint(
          'PayPal COMPLETED. source=$paymentSource, order#=$_orderNumber',
        );

        // ── Step 4: Finalise on server ────────────────────────────────────
        // URL redirect ka matlab: Laravel ne server-side payment already capture
        // kar liya hai — Flutter se dobara processPayPal() call karne ki zaroorat
        // nahi, warna empty token ki wajah se 400 error aata hai.
        // JS SDK postMessage se aaya ho tab hi processPayPal() call karo.
        if (isUrlRedirect) {
          // Laravel already handled capture — directly success navigate karo
          debugPrint(
            'PayPal: URL redirect detected. Skipping processPayPal() — Laravel already captured.',
          );
          if (!_isPayLater) {
            await StorageService.clearCartData();
            await StorageService.clearPaymentCartSnapshot();
          }
          await StorageService.clearOrderData();
          await StorageService.clearCheckoutData();

          if (mounted) {
            _navigateToOrderSuccess({
              ...result,
              'orderNumber': _orderNumber,
            }, 'PayPal');
          }
        } else {
          // JS SDK postMessage se aaya — normal server finalisation flow
          try {
            final orderId = result['orderId']?.toString() ?? '';
            debugPrint(
              'PayPal JS SDK flow. orderId=$orderId, order#=$_orderNumber',
            );

            final serverResponse = await _paymentService.processPayPal(
              orderNumber: _orderNumber!,
              orderId: _orderId!,
              amount: _amount!,
              currency: _currency ?? 'AUD',
              paymentResult: {
                'status': 'COMPLETED',
                'orderId': orderId,
                'paymentId': orderId,
                'paymentID': orderId,
                'payerID': result['payerID']?.toString() ?? '',
              },
            );

            if (!_isPayLater) {
              await StorageService.clearCartData();
              await StorageService.clearPaymentCartSnapshot();
            }
            await StorageService.clearOrderData();
            await StorageService.clearCheckoutData();

            if (mounted) {
              _navigateToOrderSuccess({...result, ...serverResponse}, 'PayPal');
            }
          } catch (e) {
            debugPrint('PayPal server finalisation error: $e');
            if (mounted) {
              Fluttertoast.showToast(
                msg:
                    'Payment received but verification failed. Order: #$_orderNumber. Contact support.',
                backgroundColor: Colors.red,
                textColor: Colors.white,
                toastLength: Toast.LENGTH_LONG,
              );
              _navigateToPaymentFailure(orderNumber: _orderNumber);
            }
          }
        }
      } else if (result['status'] == 'ERROR') {
        final errMsg = result['error']?.toString() ?? 'Payment failed.';
        debugPrint('PayPal ERROR: $errMsg');
        if (mounted) {
          Fluttertoast.showToast(
            msg: errMsg,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          _navigateToPaymentFailure();
        }
      }
    } catch (e) {
      debugPrint('PayPal Error: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: e.toString().replaceAll('Exception: ', ''),
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /* --------------------------method code end here --------------------------------*/

  // ─────────────────────────────────────────────────────────────────────────
  // COUPON MANAGEMENT
  // Apply and remove promo codes with dynamic breakdown recalculation
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _applyPromoCode() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter a promo code',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (_isProcessing || _isUpdatingCoupon) return;
    setState(() {
      _isProcessing = true;
      _isUpdatingCoupon = true;
    });

    try {
      final cartContainer = await _getPaymentCartContainer();
      final cartForCoupon = cartContainer?['cart'] as Map<String, dynamic>?;

      if (cartForCoupon == null || cartForCoupon.isEmpty) {
        Fluttertoast.showToast(msg: 'Cart is empty');
        return;
      }

      final response = await _cartService.applyCoupon({
        'old_cart': cartForCoupon,
        'code': code,
      });

      if (response['cart'] == null) {
        final errorMessage =
            (response['message']?.toString().trim().isNotEmpty ?? false)
            ? response['message'].toString().trim()
            : 'Unable to apply promo code.';
        Fluttertoast.showToast(
          msg: errorMessage,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      // Extract and apply coupon details
      final couponDetails = _extractCouponDetails(response);
      if (mounted) {
        setState(() {
          _couponCode = couponDetails['code'] as String;
          _couponOfferSubtitle = couponDetails['subtitle'] as String;
          _couponDiscount = couponDetails['discount'] as double;
          _isCouponApplied = true;
          _couponController.text = _couponCode ?? code;
        });
      }

      // Refresh pricing from central API
      if (_postcode != null && _oldCart != null) {
        await _refreshPricing(postcode: _postcode!, oldCart: _oldCart!);
      }

      final successMessage =
          (response['message']?.toString().trim().isNotEmpty ?? false)
          ? response['message'].toString().trim()
          : 'Promo code applied';
      Fluttertoast.showToast(
        msg: successMessage,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } on ApiException catch (e) {
      // Removed redundant logs as they are handled by ApiClient

      Fluttertoast.showToast(
        msg: e.message,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } catch (e) {
      debugPrint('Unexpected error applying promo code: $e');
      Fluttertoast.showToast(
        msg: 'Failed to apply promo code.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isUpdatingCoupon = false;
        });
      }
    }
  }

  Future<void> _fetchAvailableCoupons({VoidCallback? onUpdate}) async {
    if (_isLoadingCoupons) return;
    if (_hasAttemptedCouponFetch) return;

    if (mounted) setState(() => _isLoadingCoupons = true);
    if (onUpdate != null) onUpdate();

    try {
      final cartSnap = await _getPaymentCartContainer();
      final oldCart = cartSnap?['cart'] as Map<String, dynamic>? ?? {};
      final coupons = await _cartService.getAvailableCoupons(oldCart);
      if (mounted) {
        setState(() {
          _availableCoupons = coupons;
          _isLoadingCoupons = false;
          _hasAttemptedCouponFetch = true;
        });
      }
      if (onUpdate != null) onUpdate();
    } catch (e) {
      Logger.error('Error fetching coupons', e);
      if (mounted) setState(() => _isLoadingCoupons = false);
      if (onUpdate != null) onUpdate();
      Fluttertoast.showToast(msg: 'Failed to fetch available coupons');
    }
  }

  void _showCouponsModal() async {
    // If we haven't fetched coupons yet, fetch them first before showing modal
    // This allows showing a loader on the payment page button
    if (_availableCoupons.isEmpty) {
      await _fetchAvailableCoupons();
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Refresh logic if needed, but will return early if already fetched
            _fetchAvailableCoupons(onUpdate: () => setModalState(() {}));

            return Container(
              padding: const EdgeInsets.all(20),
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Offers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF151D51),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _isLoadingCoupons
                        ? const Center(child: CircularProgressIndicator())
                        : _availableCoupons.isEmpty
                        ? const Center(
                            child: Text('No coupons available at the moment'),
                          )
                        : ListView.builder(
                            itemCount: _availableCoupons.length,
                            itemBuilder: (context, index) {
                              final coupon = _availableCoupons[index];
                              final code = coupon['code']?.toString() ?? '';
                              final discountValue =
                                  coupon['price']?.toString() ?? '';
                              final discountType =
                                  (coupon['coupon_discount_type']?.toString() ??
                                          '')
                                      .toLowerCase();

                              String discountLabel = '';
                              if (discountType == 'percent' ||
                                  discountType == 'percentage') {
                                discountLabel = '$discountValue% OFF';
                              } else {
                                discountLabel = '\$$discountValue OFF';
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey[200]!),
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.local_offer,
                                    color: Color(0xFF151D51),
                                  ),
                                  title: Text(
                                    code,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    discountLabel,
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _couponController.text = code;
                                    _applyPromoCode();
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removeCoupon() async {
    if (_isProcessing || _isUpdatingCoupon) return;

    setState(() {
      _isProcessing = true;
      _isUpdatingCoupon = true;
    });

    try {
      final cartContainer = await _getPaymentCartContainer();
      final oldCart = cartContainer?['cart'] as Map<String, dynamic>?;

      if (oldCart != null) {
        final payload = {
          'old_cart': oldCart,
          'code': (_couponCode ?? _couponController.text.trim()),
        };

        final response = await _cartService.removeCoupon(payload);

        // Ensure coupon is cleared in response (backend may still return it)
        final sanitizedResponse = Map<String, dynamic>.from(response);
        sanitizedResponse.remove('coupon');
        sanitizedResponse['discount'] = 0;
        sanitizedResponse['coupon_discount'] = 0;

        // Clear UI coupon state
        if (mounted) {
          setState(() {
            _couponCode = null;
            _couponOfferSubtitle = null;
            _couponDiscount = 0.0;
            _isCouponApplied = false;
            _couponController.clear();
          });
        }

        // Refresh pricing from central API
        if (_postcode != null && _oldCart != null) {
          await _refreshPricing(postcode: _postcode!, oldCart: _oldCart!);
        }

        final removedMessage =
            (response['message']?.toString().trim().isNotEmpty ?? false)
            ? response['message'].toString().trim()
            : 'Promo code removed';
        Fluttertoast.showToast(
          msg: removedMessage,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Cart is empty',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to remove promo code.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isUpdatingCoupon = false;
        });
      }
    }
  }

  /// Handle Complete Order (Pay Later flow)
  Future<void> _handleCompleteOrder() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // 1. Step A & B: Ensure order is created on server first (Normal Flow only)
      if (!_isFromMyOrdersPayment &&
          (_orderId == null || _orderNumber == null)) {
        debugPrint(
          'Complete Order clicked: Creating order via store-order API first...',
        );
        final response = await _createOrderForDirectPayment();
        if (response == null) {
          if (mounted) setState(() => _isProcessing = false);
          return;
        }
        debugPrint(
          'Order created successfully: $_orderNumber. Proceeding to order completion...',
        );
      } else if (_isFromMyOrdersPayment &&
          (_orderId == null || _orderNumber == null)) {
        throw Exception(
          'Order details not found. Please try again from the My Orders screen.',
        );
      }

      // Log current order data for verification
      final order = _orderData?['order'] as Map?;
      final apiPrice = order?['pay_amount'] ?? order?['total'];
      debugPrint('###############Start COMPLETE ORDER####################');
      debugPrint('API ORDER PRICE: $apiPrice');
      debugPrint('UI TOTAL PAYABLE: $_amount');
      debugPrint('###############End COMPLETE ORDER#######################');

      // Since it's Pay Later, we bypass payment gateways
      if (!_isPayLater) {
        await StorageService.clearCartData();
        await StorageService.clearPaymentCartSnapshot();
      }
      await StorageService.clearOrderData();
      await StorageService.clearCheckoutData();

      if (mounted) {
        _navigateToOrderSuccess(_orderData ?? {}, 'Manual / Freight Quote');
      }
    } catch (e) {
      debugPrint('Complete Order Error: $e');
      if (mounted) {
        Fluttertoast.showToast(msg: 'Failed to complete order.');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _navigateToProfile() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/main',
      (route) => false,
      arguments: {'tabIndex': 5},
    );
  }

  /// Extract coupon details from API response
  Map<String, dynamic> _extractCouponDetails(Map<String, dynamic> response) {
    final coupon = response['coupon'] as Map<String, dynamic>?;
    final couponCode = coupon?['code']?.toString();
    final couponPrice = _toDouble(coupon?['price']) ?? 0.0;
    final couponType = (coupon?['coupon_discount_type'] ?? '')
        .toString()
        .toLowerCase();
    final discountFromResponse = _toDouble(response['discount']) ?? 0.0;

    double computedCouponDiscount = discountFromResponse;
    if (computedCouponDiscount <= 0 && couponPrice > 0) {
      if (couponType == 'percentage' || couponType == 'percent') {
        computedCouponDiscount = (_subtotalExclGst ?? 0) * couponPrice / 100;
      } else {
        computedCouponDiscount = couponPrice;
      }
    }

    String offerSubtitle = '';
    if (couponType == 'percentage' || couponType == 'percent') {
      offerSubtitle = '${couponPrice.toStringAsFixed(0)}% OFF';
    } else {
      offerSubtitle = '\$${couponPrice.toStringAsFixed(2)} OFF';
    }

    return {
      'code': couponCode ?? '',
      'discount': computedCouponDiscount > 0 ? computedCouponDiscount : 0.0,
      'subtitle': offerSubtitle,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATE MANAGEMENT & UI VISIBILITY
  // Getters for conditional payment options visibility and method selection
  // ─────────────────────────────────────────────────────────────────────────

  bool get _canShowPaymentOptionsByStatus {
    // Normal flow + large order (freight pending): payment options hide karo
    if (_hasPendingFreightQuote && !_isPayLater) return false;

    return _isPayLater ||
        _orderData == null ||
        _orderPaymentStatus == 'partial' ||
        _orderPaymentStatus == 'unpaid';
  }

  bool get _canShowAlternativePaymentMethods =>
      _isPayLater || (_manualOrderByAdmin == 0 && _isTradeUser == 0);

  String get _effectiveSelectedPaymentMethod {
    final method = _selectedPaymentMethod.trim();

    // Default: PayPal selected (Credit Card / Google Pay UI hidden — PayPal-only flow)
    if (method.isEmpty) {
      return _canShowAlternativePaymentMethods ? 'PayPal' : 'Credit Card';
    }

    final isAlternativeMethod =
        method == 'PayPal' || method == 'Google Pay' || method == 'Apple Pay';
    if (isAlternativeMethod && !_canShowAlternativePaymentMethods) {
      return 'Credit Card';
    }

    return method;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI BUILDING
  // Build payment page scaffold, forms, and order summary
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isPayLaterFlow = widget.arguments?['is_pay_later'] == true;
    final bool fromMyOrdersPayment =
        widget.arguments?['from_my_orders_payment'] == true;
    final bool isDirectCheckout = !fromMyOrdersPayment;

    // REDIRECTION LOGIC:
    // 1. Normal Flow (Direct Checkout):
    //    - If order NOT processed: Standard pop (back to Shipping/Address).
    //    - If order PROCESSED: Redirect to Home (Tab 0) + Reset Stack.
    final bool shouldRedirectToHome = !fromMyOrdersPayment && _orderId != null;

    // 2. Pay Later Flow / From My Orders:
    //    - If it's a standard 'From My Orders' payment (but NOT the specific Pay Later flow),
    //      redirect back to Profile Tab 5 to avoid landing back on the Order Details sub-page.
    final bool useProfileBack = fromMyOrdersPayment && !isPayLaterFlow;

    final effectivePaymentMethod = _effectiveSelectedPaymentMethod;
    return PopScope(
      canPop: false, // Force all pops through onPopInvokedWithResult for safety
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        if (useProfileBack) {
          _navigateToProfile();
        } else if (shouldRedirectToHome) {
          debugPrint('BACK_DEBUG: Order processed. Redirecting to Home.');
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/main',
            (route) => false,
            arguments: {'tabIndex': 0},
          );
        } else {
          // Standard pop (back to Address/Shipping or previous screen)
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F8F8),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              debugPrint('BACK_DEBUG: AppBar leading pressed');
              if (useProfileBack) {
                _navigateToProfile();
              } else if (shouldRedirectToHome) {
                debugPrint(
                  'BACK_DEBUG: AppBar Redirecting to Home (Order Processed)',
                );
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/main',
                  (route) => false,
                  arguments: {'tabIndex': 0},
                );
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            'Payment',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: isPayLaterFlow
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(38),
                  child: Container(
                    width: double.infinity,
                    color: Colors.black.withValues(alpha: 0.05),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.navigation_rounded,
                          color: Colors.black54,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'My Orders  ›  Order Details  ›  Pay Later',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
        body: Stack(
          children: [
            _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF151D51),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Securing your order...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preparing payment details',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _onPullToRefreshPricing,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        16.0,
                        16.0,
                        100.0,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (_pricingLoadFailed) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.refresh,
                                      color: Colors.orange.shade800,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Pricing could not be loaded. Pull down to refresh.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.orange.shade900,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            _buildOrderSummaryCard(),
                            const SizedBox(height: 24),

                            if (_canShowPaymentOptionsByStatus) ...[
                              _buildPaymentMethodSection(),
                              const SizedBox(height: 24),

                              if (effectivePaymentMethod == 'Credit Card') ...[
                                const SizedBox(height: 12),
                                _buildCardInputFields(),
                                const SizedBox(height: 24),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
            if (_isUpdatingCoupon || _isRefreshingPricing)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF151D51),
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: (_isLoading || _pricingLoadFailed)
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_hasPendingFreightQuote && !_isPayLater) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFCC02)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Color(0xFFF9A825),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'By clicking request freight quote a team member will update your online quote within one business day with the freight delivery cost. The updated Quote can be viewed though your online accounts "My Orders" section',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5D4037),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _canShowPaymentOptionsByStatus
                          ? (effectivePaymentMethod == 'PayPal'
                                ? _buildPayPalButton()
                                : _buildSubmitButton())
                          : _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    // ignore: unused_local_variable
    final bool isIOS = Platform.isIOS; // kept for future Apple Pay re-enable
    final effectivePaymentMethod = _effectiveSelectedPaymentMethod;

    // Payment options sirf tab dikhein jab Partial ya Unpaid ho
    final bool canShowPayments = _canShowPaymentOptionsByStatus;

    if (!canShowPayments) return const SizedBox.shrink();

    // PayPal-only flow: tile hidden hai, section dikhane ki zarurat nahi
    if (_canShowAlternativePaymentMethods) return const SizedBox.shrink();

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PAYMENT METHOD',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 1. Credit Card — sirf restricted case me dikhega
            // (jab PayPal allowed nahi hai e.g. trade user / admin order).
            // Normal flow me Credit Card option hidden hai — PayPal-only.
            if (!_canShowAlternativePaymentMethods) ...[
              GestureDetector(
                onTap: () {
                  setState(() => _selectedPaymentMethod = 'Credit Card');
                  // Auto-scroll to card form after frame renders
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_cardFormKey.currentContext != null) {
                      Scrollable.ensureVisible(
                        _cardFormKey.currentContext!,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        alignment: 0.0,
                      );
                    }
                  });
                },
                child: _paymentOptionRow(
                  'Credit Card',
                  Icons.credit_card,
                  effectivePaymentMethod == 'Credit Card',
                ),
              ),
            ],

            // Info banner when alternative methods are restricted
            if (!_canShowAlternativePaymentMethods) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFCC02)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Color(0xFFF9A825),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _manualOrderByAdmin != 0
                            ? 'This order was created by admin. Only Credit Card payment is available.'
                            : 'Only Credit Card payment is available for trade accounts.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // 2. PayPal — sirf option jo by default dikhta hai aur pre-selected hai.
            // Google Pay row hata diya gaya hai (UI se hidden, by request).
            if (_canShowAlternativePaymentMethods) ...[
              GestureDetector(
                onTap: () => setState(() => _selectedPaymentMethod = 'PayPal'),
                child: _paymentOptionRow(
                  'PayPal',
                  'assets/images/paypal.png',
                  effectivePaymentMethod == 'PayPal',
                  fallbackAsset: 'assets/images/paypal.png',
                ),
              ),
              // Google Pay UI hidden — by request (point 1).
              // Backend/Google Pay logic untouched; sirf option row remove kiya gaya.
              /*
              if (!kIsWeb) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () =>
                      setState(() => _selectedPaymentMethod = 'Google Pay'),
                  child: _paymentOptionRow(
                    'Google Pay',
                    'assets/images/gpay.png',
                    effectivePaymentMethod == 'Google Pay',
                    isEnabled: true,
                    fallbackAsset: 'assets/images/gpay.png',
                    trailing: _isInitializingGooglePay
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                ),
                if (!kIsWeb && isIOS) ...[
                  const SizedBox(height: 12),
                  _paymentOptionRow(
                    'Apple Pay',
                    Icons.apple,
                    _selectedPaymentMethod == 'Apple Pay',
                    isEnabled: false,
                  ),
                ],
              ],
              */
            ],
          ],
        ),
      ),
    );
  }

  Widget _paymentOptionRow(
    String title,
    dynamic iconOrImage,
    bool isSelected, {
    bool isEnabled = true,
    Widget? trailing,
    String? fallbackAsset,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF002e5b).withValues(alpha: 0.05)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF002e5b) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (iconOrImage is IconData)
              Icon(
                iconOrImage,
                color: isSelected ? const Color(0xFF002e5b) : Colors.grey[600],
              )
            else if (iconOrImage is String)
              iconOrImage.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: iconOrImage,
                      height: 24,
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          const SizedBox(width: 24, height: 20),
                      errorWidget: (context, url, error) =>
                          fallbackAsset != null
                          ? Image.asset(
                              fallbackAsset,
                              height: 24,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.payment,
                                    color: isSelected
                                        ? const Color(0xFF002e5b)
                                        : Colors.grey[600],
                                  ),
                            )
                          : Icon(
                              Icons.payment,
                              color: isSelected
                                  ? const Color(0xFF002e5b)
                                  : Colors.grey[600],
                            ),
                    )
                  : Image.asset(
                      iconOrImage,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.payment,
                        color: isSelected
                            ? const Color(0xFF002e5b)
                            : Colors.grey[600],
                      ),
                    ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF002e5b) : Colors.black,
              ),
            ),
            const Spacer(),
            if (trailing != null)
              trailing
            else if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF002e5b)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    final orderNumber = _orderNumber ?? '-';
    final total = _amount ?? 0.0;
    final String rawDataStr = _orderData.toString().toLowerCase();
    final currencySign = _orderData?['currency_sign']?.toString() ?? '\$';
    final hasAppliedCoupon =
        _isCouponApplied && _couponCode != null && _couponCode!.isNotEmpty;

    String formatPrice(double? v) =>
        v != null ? '$currencySign${v.toStringAsFixed(2)}' : '-';

    debugPrint('BUILD_SUMMARY_CARD: _isPayLater = $_isPayLater');

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: PRICE DETAILS
            const Text(
              'PRICE DETAILS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF151D51),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),

            // Items total (excl. GST)
            _summaryRow(
              'Total of Items(excl. GST)',
              formatPrice(_totalCostExclGst),
            ),
            const SizedBox(height: 12),

            // Shipping Cost
            _summaryRow(
              'Shipping Cost(excl. GST)',
              _showFreeShippingLabel
                  ? '${currencySign}0.00'
                  : formatPrice(_shippingCost),
              valueColor: _hasPendingFreightQuote
                  ? Colors.red
                  : (_showFreeShippingLabel
                        ? Colors.green
                        : const Color(0xFFF44336)),
              labelColor: _hasPendingFreightQuote
                  ? Colors.red
                  : (_showFreeShippingLabel
                        ? Colors.green
                        : const Color(0xFFF44336)),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.8),
            const SizedBox(height: 12),

            // Total without GST
            _summaryRow('Total without GST', formatPrice(_totalWithoutGst)),
            const SizedBox(height: 12),

            // GST Row
            _summaryRow('GST @ 10%', formatPrice(_gstAmount)),
            const SizedBox(height: 12),

            // Total incl. GST
            _summaryRow('Total(incl. GST)', formatPrice(_totalWithGst)),
            const SizedBox(height: 12),

            // Discount Row - ONLY visible if discount > 0
            if (_discountAmount != null && _discountAmount! > 0) ...[
              _summaryRow(
                'Discount',
                '-${formatPrice(_discountAmount)}',
                valueColor: Colors.red[700],
                labelColor: Colors.red[700],
              ),
              const SizedBox(height: 12),
            ],

            // Promo Code Section (Hide if PayLater)
            if (!_isPayLater) ...[
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _couponController,
                        readOnly: hasAppliedCoupon ||
                            _isUpdatingCoupon ||
                            _isProcessing,
                        enabled: !hasAppliedCoupon &&
                            !_isUpdatingCoupon &&
                            !_isProcessing,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.done,
                        onSubmitted: hasAppliedCoupon ||
                                _isUpdatingCoupon ||
                                _isProcessing
                            ? null
                            : (_) => _applyPromoCode(),
                        decoration: InputDecoration(
                          hintText: 'Enter promo code',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          border: InputBorder.none,
                          suffixIcon: hasAppliedCoupon
                              ? null
                              : IconButton(
                                  onPressed: (_isLoadingCoupons ||
                                          _isProcessing ||
                                          _isUpdatingCoupon)
                                      ? null
                                      : _showCouponsModal,
                                  icon: const Icon(
                                    Icons.local_offer_outlined,
                                    size: 20,
                                    color: Color(0xFF151D51),
                                  ),
                                  tooltip: 'Browse offers',
                                ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : (hasAppliedCoupon ? _removeCoupon : _applyPromoCode),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasAppliedCoupon
                          ? Colors.orange
                          : const Color(0xFF151D51),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(90, 44),
                      elevation: 0,
                    ),
                    child: _isUpdatingCoupon
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            hasAppliedCoupon ? 'Remove' : 'Apply',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: (_isLoadingCoupons || _isProcessing)
                      ? null
                      : _showCouponsModal,
                  icon: _isLoadingCoupons
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF151D51),
                            ),
                          ),
                        )
                      : const Icon(Icons.local_offer_outlined, size: 16),
                  label: Text(
                    _isLoadingCoupons
                        ? 'Loading Offers...'
                        : 'View Available Offers',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF151D51),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 0.8),
              const SizedBox(height: 12),
              // Show applied promo code message
              if (hasAppliedCoupon) ...[
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _couponOfferSubtitle != null &&
                              _couponOfferSubtitle!.isNotEmpty
                          ? '$_couponCode $_couponOfferSubtitle'
                          : '$_couponCode',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ] else ...[
              const Divider(height: 1, thickness: 0.8),
              const SizedBox(height: 16),
            ],

            // Total Payable Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Payble Amount :',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  formatPrice(total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),

            // Pending Freight Quote (Shows when show_freight_cost_icon is 1)
            if (_hasPendingFreightQuote) ...[
              const SizedBox(height: 8),
              Text(
                (_shippingTag != null && _shippingTag!.isNotEmpty)
                    ? _shippingTag!
                    : 'Pending Freight Cost',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (!_hasPendingFreightQuote &&
                _showFreeShippingLabel &&
                !_isPickupShipping) ...[
              const SizedBox(height: 8),
              Text(
                'Your Order Eligible for Free Delivery',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    Color? labelColor,
    Color? valueColor,
    bool isBoldLabel = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: labelColor ?? const Color(0xFF151D51),
              fontWeight: isBoldLabel ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> Function()? _submitButtonAction() {
    if (_effectiveSelectedPaymentMethod == 'Google Pay') {
      return _handleGooglePayClick;
    }
    return _handlePayment;
  }

  Widget _buildSubmitButton() {
    final isBusy = _isProcessing || _isPaymentProcessing;
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isBusy ? null : _submitButtonAction(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF002e5b),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: const StadiumBorder(),
          elevation: 2,
        ),
        child: isBusy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                (_hasPendingFreightQuote && !_isPayLater)
                    ? 'REQUEST FREIGHT QUOTE'
                    : 'PAY NOW',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildPayPalButton() {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _handlePayPalPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF002e5b),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: const StadiumBorder(),
          elevation: 2,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'PAY NOW',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildCardInputFields() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: _cardFormKey, // scroll target for auto-scroll
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF151D51),
              ),
            ),
            const SizedBox(height: 16),

            // Cardholder Name
            _buildTextField(
              label: 'Cardholder Name',
              controller: _cardholderNameController,
              focusNode: _cardholderNameFocus,
              hint: 'E.g. Full Name',
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              onSubmitted: () =>
                  FocusScope.of(context).requestFocus(_cardNumberFocus),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Enter cardholder name' : null,
            ),
            const SizedBox(height: 12),

            // Card Number
            _buildTextField(
              label: 'Card Number',
              controller: _cardNumberController,
              focusNode: _cardNumberFocus,
              hint: 'XXXX XXXX XXXX XXXX',
              keyboardType: TextInputType.number,
              maxLength: 19,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CardNumberFormatter(),
              ],
              textInputAction: TextInputAction.next,
              onSubmitted: () =>
                  FocusScope.of(context).requestFocus(_expiryFocus),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter card number';
                final clean = v.replaceAll(' ', '');
                if (clean.length < 13 || clean.length > 19)
                  return 'Enter valid card number';
                return null;
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // Expiry Date
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    label: 'Expiry Date',
                    controller: _expiryController,
                    focusNode: _expiryFocus,
                    hint: 'MM/YY',
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ExpiryDateFormatter(),
                    ],
                    textInputAction: TextInputAction.next,
                    onSubmitted: () =>
                        FocusScope.of(context).requestFocus(_cvvFocus),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 5) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // CVV
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                    label: 'CVV',
                    controller: _cvvController,
                    focusNode: _cvvFocus,
                    hint: 'CVV',
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: () {
                      FocusScope.of(context).unfocus();
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 3) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          validator: validator,
          textInputAction: textInputAction,
          cursorColor: const Color(0xFF002e5b),
          showCursor: true,
          cursorWidth: 2.0,
          onFieldSubmitted: (_) {
            if (onSubmitted != null) {
              onSubmitted();
            } else {
              FocusScope.of(context).nextFocus();
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF002e5b),
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(height: 0.8, fontSize: 11),
          ),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.replaceAll(' ', '');
    if (newText.length > 16) newText = newText.substring(0, 16);

    String formattedText = '';
    for (int i = 0; i < newText.length; i++) {
      formattedText += newText[i];
      if ((i + 1) % 4 == 0 && (i + 1) != newText.length) {
        formattedText += ' ';
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.replaceAll('/', '');
    if (newText.length > 4) newText = newText.substring(0, 4);

    String formattedText = '';
    for (int i = 0; i < newText.length; i++) {
      formattedText += newText[i];
      if (i == 1 && newText.length > 2) {
        formattedText += '/';
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom PayPal WebView Screen
// Intercepts the returnURL to extract payment details from query parameters
// instead of relying on flutter_paypal's buggy onSuccess callback.
// ─────────────────────────────────────────────────────────────────────────────

/*
class _PayPalWebViewScreen extends StatefulWidget {
  final String approvalUrl;
  final String returnUrl;
  final String cancelUrl;

  const _PayPalWebViewScreen({
    required this.approvalUrl,
    required this.returnUrl,
    required this.cancelUrl,
  });

  @override
  State<_PayPalWebViewScreen> createState() => _PayPalWebViewScreenState();
}

class _PayPalWebViewScreenState extends State<_PayPalWebViewScreen> 
{
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('PayPalWebView: Loading $url');
            if (mounted) setState(() => _isLoading = true);
            _checkUrl(url);
          },
          onPageFinished: (url) {
            debugPrint('PayPalWebView: Finished loading $url');
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            debugPrint('PayPalWebView: Navigation request to ${request.url}');
            _checkUrl(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.approvalUrl));
  }

  void _checkUrl(String url) {
    if (_hasPopped) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final returnUri = Uri.tryParse(widget.returnUrl);
    final cancelUri = Uri.tryParse(widget.cancelUrl);

    // Check for success returnURL
    if (returnUri != null &&
        uri.host == returnUri.host &&
        uri.path == returnUri.path) {
      _hasPopped = true;
      final paymentId = uri.queryParameters['paymentId'];
      final payerId = uri.queryParameters['PayerID'];
      final token = uri.queryParameters['token'];
      debugPrint(
        'PayPalWebView: SUCCESS! paymentId=$paymentId, payerId=$payerId, token=$token',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop({
            'status': 'success',
            'paymentId': paymentId,
            'payerId': payerId,
            'token': token,
          });
        }
      });
      return;
    }

    // Check for cancel cancelURL
    if (cancelUri != null &&
        uri.host == cancelUri.host &&
        uri.path == cancelUri.path) {
      _hasPopped = true;
      debugPrint('PayPalWebView: CANCELLED by user.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop({'status': 'cancelled'});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayPal Payment'),
        backgroundColor: const Color(0xFF003087),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close'),
          onPressed: () {
            if (!_hasPopped) {
              _hasPopped = true;
              Navigator.of(context).pop({'status': 'cancelled'});
            }
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF003087)),
            ),
        ],
      ),
    );
  }
}
*/
