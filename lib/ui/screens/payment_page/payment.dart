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
import 'package:flutter_paypal/flutter_paypal.dart';

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

  // Order breakdown (from cart, for display before payment)
  double? _subtotalExclGst;
  double? _shippingCost;
  double? _gstAmount;
  double? _discountAmount; // stored for future display use
  double? _gstRate;
  bool _hasPendingFreightQuote = false;
  bool _isPayLater = false;
  bool _showFreeShippingLabel = false;
  bool _isAwaitingFreight = false;
  String _selectedPaymentMethod = '';
  int _manualOrderByAdmin = 0;
  int _isTradeUser = 0;
  String _orderPaymentStatus = '';
  double? _specialDiscount;
  String _orderSource = '';

  // Google Pay
  Pay? _payClient;
  PaymentConfiguration? _googlePayConfig;
  bool _isGooglePayAvailable = false;
  bool _isInitializingGooglePay = true;
  StreamSubscription? _paymentResultSubscription;
  bool _isPaymentProcessing = false;
  bool _hasNavigatedAway = false;

  final _formKey = GlobalKey<FormState>();

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

  @override
  void initState() {
    super.initState();
    _initializePayment();
    _loadPayPalConfig();
    _initializeGooglePay();
  }

  /// Load PayPal configuration from assets
  Future<void> _loadPayPalConfig() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/paypal_config.json',
      );
      _paypalConfig = jsonDecode(jsonString) as Map<String, dynamic>;
      debugPrint('PayPal config loaded: ${_paypalConfig?['mode']}');
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
    super.dispose();
  }

  void _printLongString(String text, String label) {
    debugPrint('=== $label (Length: ${text.length}) ===');
    const int chunkSize = 800;
    for (int i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      debugPrint(text.substring(i, end));
    }
    debugPrint('=== END $label ===');
  }

  Future<void> _clearCartOnPaymentExit() async {
    try {
      await StorageService.clearCartData();
    } catch (e) {
      debugPrint('Failed to clear cart data: $e');
    }
  }

  // ─── Google Pay ────────────────────────────────────────────────────────────

  Future<void> _initializeGooglePay() async {
    if (kIsWeb || !Platform.isAndroid) {
      if (mounted) setState(() => _isInitializingGooglePay = false);
      return;
    }
    try {
      if (mounted) setState(() => _isInitializingGooglePay = true);
      _googlePayConfig = await PaymentConfiguration.fromAsset(
        BuildConfig.googlePayConfigAsset,
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
              _clearCartOnPaymentExit();
              setState(() => _isProcessing = false);
              Fluttertoast.showToast(
                msg: 'Google Pay failed. Please try again.',
                toastLength: Toast.LENGTH_LONG,
                backgroundColor: Colors.red,
                textColor: Colors.white,
              );
            }
          },
        );
  }

  Future<void> _handleGooglePayResult(
    Map<String, dynamic> paymentResult,
  ) async {
    if (_isPaymentProcessing || _hasNavigatedAway || !mounted) return;

    try {
      _isPaymentProcessing = true;
      if (mounted) setState(() => _isProcessing = true);

      Map<String, dynamic>? orderData = await StorageService.getOrderData();
      final order = orderData?['order'] as Map<String, dynamic>?;
      final orderNumber = order?['order_number'] as String?;
      final amount =
          _amount ?? (order?['pay_amount'] as num?)?.toDouble() ?? 0.0;

      if (orderNumber == null) throw Exception('Order number not found');

      debugPrint(
        'Processing Google Pay for order: $orderNumber, amount: $amount',
      );

      final response = await _paymentService.processGooglePay(
        orderNumber: orderNumber,
        amount: amount,
        paymentResult: paymentResult,
      );

      final paymentToken = response['payment_token'] as String?;
      if (paymentToken != null && paymentToken.isNotEmpty) {
        _printLongString(paymentToken, 'GOOGLE_PAY_TOKEN_RAW');
        _printLongString(
          base64Encode(utf8.encode(paymentToken)),
          'GOOGLE_PAY_TOKEN_BASE64',
        );
      }

      await StorageService.clearCartData();
      _paymentResultSubscription?.cancel();
      _paymentResultSubscription = null;

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Payment successful!',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        _hasNavigatedAway = true;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/order-placed',
          (route) => false,
          arguments: {
            'payment_token': paymentToken,
            'payment_method': 'Google Pay',
          },
        );
      }
    } catch (e) {
      debugPrint('Google Pay error: $e');
      _isPaymentProcessing = false;
      await _clearCartOnPaymentExit();
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Something went wrong. Please try again.',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
    if (_isPaymentProcessing || _hasNavigatedAway) return;

    try {
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
      debugPrint('Google Pay error: $e');
      _isPaymentProcessing = false;
      await _clearCartOnPaymentExit();
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Google Pay failed. Please try again.',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  // ─── Payment Initialization ────────────────────────────────────────────────

  /// Fallback breakdown from stored order data when shipping API cannot run.
  _ShippingBreakdown _breakdownFromStoredOrder(Map<String, dynamic> data) {
    final order = data['order'] as Map<String, dynamic>?;

    double parse(dynamic v) {
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

    double subtotalExclGst = parse(data['subtotal_excluding_gst']) > 0
        ? parse(data['subtotal_excluding_gst'])
        : (parse(order?['pay_amount']) > 0
              ? parse(order?['pay_amount'])
              : parse(order?['subtotal']));

    double gstAmount = parse(data['tax']) > 0
        ? parse(data['tax'])
        : parse(order?['tax_amount']);

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
        ? parse(order?['shipping_cost'])
        : parse(order?['normal_shipping_cost']);

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
    );

    final double totalAmount = parse(data['grand_total']) > 0
        ? parse(data['grand_total'])
        : (parse(order?['total']) > 0
              ? parse(order?['total'])
              : parse(order?['pay_amount']));

    final double discountAmount = parse(data['discount']) > 0
        ? parse(data['discount'])
        : parse(order?['discount']);

    final orderSource =
        data['order_source']?.toString().toLowerCase() ??
        order?['order_source']?.toString().toLowerCase() ??
        '';
    double specialDiscount = 0.0;
    if (orderSource == 'mobile') {
      specialDiscount = parse(order?['special_discount']);
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

  _FreightRuleResult _resolveFreightRule({
    required double rawShippingCost,
    dynamic orderType,
    dynamic showRequestFreightCost,
    dynamic showFreeShippingIcon,
  }) {
    final normalizedOrderType = (orderType ?? '').toString().toLowerCase();
    final requestFreightCost = _toDouble(showRequestFreightCost) ?? 0.0;
    final freeShippingIcon = _toDouble(showFreeShippingIcon) ?? 0.0;

    final hasPendingFreightQuote =
        normalizedOrderType == 'large' || requestFreightCost > 0;
    final showFreeShippingLabel =
        !hasPendingFreightQuote && freeShippingIcon == 1;

    final shippingCost = hasPendingFreightQuote || showFreeShippingLabel
        ? 0.0
        : (rawShippingCost < 0 ? 0.0 : rawShippingCost);

    return _FreightRuleResult(
      shippingCost: shippingCost,
      hasPendingFreightQuote: hasPendingFreightQuote,
      showFreeShippingLabel: showFreeShippingLabel,
    );
  }

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

  Future<Map<String, dynamic>?> _getPaymentCartContainer() async {
    if (_isFromMyOrdersPayment) {
      // Prefer direct argument cart first (avoids storage roundtrip)
      final argCart = widget.arguments?['order_cart'];
      if (argCart is Map && argCart.isNotEmpty) {
        debugPrint('PAYMENT_CART_SOURCE: my_orders_flow (order_cart argument) - ${argCart.length} items');
        return {'cart': Map<String, dynamic>.from(argCart as Map)};
      }
      // Fallback: read cart from the full order_data argument
      final argOrderData = widget.arguments?['order_data'];
      if (argOrderData is Map) {
        final cart = (argOrderData as Map)['cart'];
        if (cart is Map && cart.isNotEmpty) {
          debugPrint('PAYMENT_CART_SOURCE: my_orders_flow (order_data argument cart) - ${cart.length} items');
          return {'cart': Map<String, dynamic>.from(cart as Map)};
        }
      }
      debugPrint('PAYMENT_CART_SOURCE: my_orders_flow (no cart available)');
      return null;
    }

    final snapshot = await StorageService.getPaymentCartSnapshot();
    if (snapshot != null && snapshot['cart'] is Map) {
      final cartItems = (snapshot['cart'] as Map).length;
      debugPrint('PAYMENT_CART_SOURCE: payment_cart_snapshot - $cartItems items');
      return snapshot;
    }

    debugPrint('PAYMENT_CART_SOURCE: snapshot null/empty, trying cart_data fallback');
    final cartData = await StorageService.getCartData();
    if (cartData != null && cartData['cart'] is Map) {
      final cartItems = (cartData['cart'] as Map).length;
      debugPrint('PAYMENT_CART_SOURCE: cart_data_fallback - $cartItems items');
      return cartData;
    }

    debugPrint('PAYMENT_CART_SOURCE: all sources null/empty');
    return null;
  }

  Future<void> _initializePayment() async {
    try {
      debugPrint('=== PAYMENT PAGE INITIALIZATION ===');

      // For PayLater flow, prefer the full response passed directly as argument
      // so we have the cart (product_sizeType etc.) without a storage roundtrip.
      Map<String, dynamic>? orderData =
          (widget.arguments?['order_data'] as Map?)?.cast<String, dynamic>() ??
          await StorageService.getOrderData();

      debugPrint('Order data: ${orderData != null ? "Found (from: ${widget.arguments?['order_data'] != null ? 'argument' : 'storage'})" : "Not found"}');

      if (orderData == null) {
        final bool fromMyOrdersPayment =
            widget.arguments?['from_my_orders_payment'] == true;

        // Direct normal checkout may land here without a pre-seeded order.
        if (!fromMyOrdersPayment) {
          final created = await _createOrderForDirectPayment();
          if (!created) {
            if (mounted) setState(() => _isLoading = false);
            return;
          }
          orderData = await StorageService.getOrderData();
        }

        if (orderData == null) {
          debugPrint('ERROR: Order data is null');
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Order data not found. Please try again.',
              toastLength: Toast.LENGTH_LONG,
            );
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      final resolvedOrderData = orderData;

      setState(() {
        _orderData = resolvedOrderData;
        final statusRoot = (resolvedOrderData['order_status'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
        final statusOrder = (resolvedOrderData['order']?['order_status'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
        _isAwaitingFreight =
            statusRoot.contains('awaiting') || statusOrder.contains('awaiting');
        debugPrint(
          'Freight Status Detected: $_isAwaitingFreight (Root: $statusRoot, Order: $statusOrder)',
        );
      });

      final order = resolvedOrderData['order'] as Map<String, dynamic>?;
      final orderNumber = order?['order_number'] as String?;
      final orderId = order?['id'] as int?;

      // Initialize status-based flags
      _manualOrderByAdmin =
          (order?['manual_order_by_admin'] as num?)?.toInt() ?? 0;
      _orderPaymentStatus = (order?['payment_status'] ?? '')
          .toString()
          .toLowerCase();

      // Retrieve trade user status from StorageService
      final UserModel? currentUser = await StorageService.getUserData();
      _isTradeUser = currentUser?.isTradeUser ?? 0;

      debugPrint(
        '╔══════ PAYMENT OPTIONS VISIBILITY FLAGS ══════╗\n'
        '║ manual_order_by_admin : $_manualOrderByAdmin\n'
        '║ is_trade_user         : $_isTradeUser  (user: ${currentUser?.name ?? "null"})\n'
        '║ payment_status        : $_orderPaymentStatus\n'
        '║ canShowByStatus       : ${_orderPaymentStatus == "partial" || _orderPaymentStatus == "unpaid"}\n'
        '║ canShowAltMethods     : ${_manualOrderByAdmin == 0 && _isTradeUser == 0}\n'
        '╚══════════════════════════════════════════════╝',
      );

      final payAmount = order?['pay_amount'] as num?;
      final totalAmount = order?['total'] as num?;
      double amount = (payAmount ?? totalAmount)?.toDouble() ?? 0.0;

      if (orderNumber == null || orderId == null) {
        if (mounted) {
          Fluttertoast.showToast(msg: 'Invalid order data.');
          setState(() => _isLoading = false);
        }
        return;
      }

      double? subtotalExclGst;
      double? shippingCost;
      double? gstAmount;
      double? discountAmount;

      try {
        final checkoutData = await StorageService.getCheckoutData();
        final postcode = (checkoutData?['post_code'] as String?)?.trim() ?? '';
        final cartResponse = await _getPaymentCartContainer();
        final oldCart = cartResponse?['cart'] as Map<String, dynamic>?;
        final bool fromMyOrdersPayment =
            widget.arguments?['from_my_orders_payment'] == true;

        if (!fromMyOrdersPayment && postcode.isNotEmpty && oldCart != null) {
          final shippingResponse = await _cartService.calculateShipping({
            'postcode': postcode,
            'old_cart': oldCart,
          });

          final shippingOrderType = _extractOrderType(data: shippingResponse);
          final snapshotOrderType = _extractOrderType(data: cartResponse);
          final cartItemOrderType = _extractOrderTypeFromCartContainer(
            cartResponse,
          );
          final orderType = shippingOrderType.isNotEmpty
              ? shippingOrderType
              : (snapshotOrderType.isNotEmpty
                    ? snapshotOrderType
                    : cartItemOrderType);

          final effectiveShowRequestFreightCost =
              (shippingResponse['show_request_freight_cost'] != null)
              ? shippingResponse['show_request_freight_cost']
              : (cartResponse?['show_request_freight_cost'] ??
                 _extractFreightCostFlagFromCartItems(cartResponse));
          final effectiveShowFreeShippingIcon =
              (shippingResponse['show_free_shipping_icon'] != null)
              ? shippingResponse['show_free_shipping_icon']
              : (cartResponse?['show_free_shipping_icon'] ??
                 _extractFreeShippingIconFromCartItems(cartResponse));

          // Map shipping cost using prioritized keys from API
          final rawShippingCost =
              _toDouble(shippingResponse['shipping']) ??
              _toDouble(shippingResponse['normal_shipping_cost']) ??
              _toDouble(shippingResponse['shipping_cost']) ??
              0.0;

          final freightRule = _resolveFreightRule(
            rawShippingCost: rawShippingCost,
            orderType: orderType,
            showRequestFreightCost: effectiveShowRequestFreightCost,
            showFreeShippingIcon: effectiveShowFreeShippingIcon,
          );

          shippingCost = freightRule.shippingCost;

          gstAmount = _toDouble(shippingResponse['tax']);
          
          // Use total_with_gst from shipping API ONLY as a fallback when
          // order amount is 0 or unavailable. The stored order amount is the
          // source of truth — overriding it with a shipping API response that
          // may have used a stale/wrong cart causes wrong totals on retry.
          final shippingTotalWithGst = _toDouble(shippingResponse['total_with_gst']);
          if (amount <= 0 && shippingTotalWithGst != null && shippingTotalWithGst > 0) {
            amount = shippingTotalWithGst;
            debugPrint(
              'PAYMENT_TOTAL_DEBUG[init]: order amount was 0, using API total_with_gst=$shippingTotalWithGst',
            );
          } else {
            debugPrint(
              'PAYMENT_TOTAL_DEBUG[init]: keeping order amount=$amount (API total_with_gst=$shippingTotalWithGst)',
            );
          }

          // Back-calculate subtotal to ensure mathematical consistency in UI
          // Subtotal (Items) = Grand Total - GST - Shipping
          subtotalExclGst = amount - (gstAmount ?? 0.0) - (shippingCost ?? 0.0);

          final discount = _toDouble(cartResponse?['discount']);
          final couponDiscount = _toDouble(cartResponse?['coupon_discount']);
          discountAmount = discount ?? couponDiscount;

            // Pending freight affects UI messaging; Pay Later UI mode is controlled
            // only by route arguments from My Orders flow.
            _hasPendingFreightQuote = freightRule.hasPendingFreightQuote;
            _showFreeShippingLabel = freightRule.showFreeShippingLabel;
        } else {
          final snap = _breakdownFromStoredOrder(orderData);
          subtotalExclGst = snap.subtotalExclGst;
          shippingCost = snap.shippingCost;
          gstAmount = snap.gstAmount;
          discountAmount = snap.discountAmount;
          amount = snap.amount;
          _hasPendingFreightQuote = snap.hasPendingFreightQuote;
          _showFreeShippingLabel = snap.showFreeShippingLabel;
        }
      } catch (e) {
        debugPrint('Error preparing payment breakdown: $e');
        final snap = _breakdownFromStoredOrder(orderData);
        subtotalExclGst = snap.subtotalExclGst;
        shippingCost = snap.shippingCost;
        gstAmount = snap.gstAmount;
        discountAmount = snap.discountAmount;
        amount = snap.amount;
        _hasPendingFreightQuote = snap.hasPendingFreightQuote;
        _showFreeShippingLabel = snap.showFreeShippingLabel;
      }

      // When user comes from My Orders → Pay Now, we usually show payment UI.
      // BUT Pay Later UI mode is controlled ONLY by `is_pay_later` argument.
      final bool argIsPayLater = widget.arguments?['is_pay_later'] == true;
      final bool isCheckoutFreightPayment =
          widget.arguments?['checkout_freight_payment'] == true;
      _isPayLater = argIsPayLater && !isCheckoutFreightPayment;

      setState(() {
        _orderNumber = orderNumber;
        _orderId = orderId;
        _amount = amount > 0 ? amount : 0.0;
        _currency = 'AUD';

        _shippingCost = shippingCost ?? 0.0;
        _gstAmount = gstAmount ?? 0.0;
        _discountAmount = discountAmount ?? 0.0;

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

        // Mathematically consistent Subtotal (Total - GST - Shipping + Special Discount)
        // This ensures the breakdown always matches the final total exactly.
        _subtotalExclGst =
            (_amount! -
            _gstAmount! -
            _shippingCost! +
            (_specialDiscount ?? 0.0));

        // ABSOLUTE OVERRIDE: If we have explicit values from Order Details, use them exactly.
        // This prevents different roundings or back-calculations from creating discrepancies.
        if (widget.arguments?['summary_grand_total'] != null) {
          _amount = (widget.arguments?['summary_grand_total'] as num)
              .toDouble();
          _gstAmount = (widget.arguments?['summary_tax'] as num).toDouble();
          _shippingCost = (widget.arguments?['summary_shipping'] as num)
              .toDouble();
          _discountAmount = (widget.arguments?['summary_discount'] as num)
              .toDouble();
          _specialDiscount =
              (widget.arguments?['summary_special_discount'] as num).toDouble();
          _subtotalExclGst = (widget.arguments?['summary_subtotal'] as num)
              .toDouble();
        }

        if (_gstAmount! > 0 && _subtotalExclGst! > 0) {
          _gstRate = (_gstAmount! / _subtotalExclGst!) * 100;
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
            _isCouponApplied =
                _couponCode != null && _couponCode!.isNotEmpty;
          });
        }
      }

      try {
        await _paymentService.createPaymentIntent(
          orderNumber: orderNumber,
          amount: amount > 0 ? amount : 0.0,
          currency: 'AUD',
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('Error initializing payment: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _createOrderForDirectPayment() async {
    try {
      final userData = await StorageService.getUserData();
      if (userData == null) {
        Fluttertoast.showToast(msg: 'Please login to continue');
        return false;
      }

      final cartResponse = await _getPaymentCartContainer();
      if (cartResponse == null || cartResponse['cart'] == null) {
        Fluttertoast.showToast(msg: 'Cart is empty');
        return false;
      }

      final checkoutData = await StorageService.getCheckoutData();
      if (checkoutData == null) {
        Fluttertoast.showToast(msg: 'Please complete checkout form');
        return false;
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
        return false;
      }

      await StorageService.saveOrderData(response);
      return true;
    } catch (e) {
      debugPrint('Error creating order for direct payment: $e');
      Fluttertoast.showToast(msg: 'Failed to place order. Please try again.');
      return false;
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
      final pickupLocation = checkoutData['pickup_location'] as String?;
      if (pickupLocation == '53 Cochranes Road, Moorabbin, VIC 3189') {
        pickupLocationId = 1;
      } else if (pickupLocation ==
          'Unit 2, 2 Commercial Dr, Shailer Park QLD 4128') {
        pickupLocationId = 2;
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

  /// Handle payment submission (Native direct API integration)
  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate() || _isProcessing) {
      if (!_formKey.currentState!.validate()) {
        Fluttertoast.showToast(msg: 'Please fill all card details correctly.');
      }
      return;
    }

    setState(() => _isProcessing = true);

    debugPrint('=== _handlePayment (Direct API) START ===');
    try {
      // 1. Process expiry - MM/YY format to MM and YYYY
      final expiryValue = _expiryController.text.trim();
      final expiryParts = expiryValue.split('/');
      if (expiryParts.length != 2) throw Exception('Invalid expiry format');

      final String month = expiryParts[0].padLeft(2, '0');
      String year = expiryParts[1].trim();
      if (year.length == 2) {
        year = '20$year'; // Convert YY to YYYY
      }

      // 2. Call direct API
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

      debugPrint('Direct API payment response received: $response');

      // 3. Handle successful payment
      // Response format: { 'order': {...}, 'process_payment': 0, 'show_order_success': 1 }
      if (response['show_order_success'] == 1 ||
          response['payment_status'] == 'completed' ||
          response['order_status'] == 'paid' ||
          response['success'] == true) {
        // Clear cart as payment was successful
        await StorageService.clearCartData();

        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Payment successful!',
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
                  response['order']?['order_number'] ??
                  _orderNumber,
              'payment_method': 'Credit Card',
            },
          );
        }
      } else {
        throw Exception(
          response['message'] ?? 'Payment failed. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('Direct API payment error: $e');
      await _clearCartOnPaymentExit();
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
  Future<void> _handlePayPalPayment() async {
    if (_isProcessing) return;

    if (_paypalConfig == null) {
      Fluttertoast.showToast(msg: 'PayPal configuration not loaded.');
      return;
    }

    final isSandbox = _paypalConfig!['mode'] == 'sandbox';
    final clientId = isSandbox
        ? _paypalConfig!['sandbox_client_id']
        : _paypalConfig!['production_client_id'];
    final secretKey = isSandbox
        ? _paypalConfig!['sandbox_secret_key']
        : _paypalConfig!['production_secret_key'];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => UsePaypal(
          sandboxMode: isSandbox,
          clientId: clientId,
          secretKey: secretKey,
          returnURL: "https://www.apc.com.au/payment/success",
          cancelURL: "https://www.apc.com.au/payment/cancel",
          transactions: [
            {
              "amount": {
                "total": _amount!.toStringAsFixed(2),
                "currency": _currency ?? 'AUD',
                "details": {
                  "subtotal": _subtotalExclGst!.toStringAsFixed(2),
                  "shipping": _shippingCost!.toStringAsFixed(2),
                  "tax": _gstAmount!.toStringAsFixed(2),
                  "shipping_discount": _discountAmount!.toStringAsFixed(2)
                }
              },
              "description": "Order #$_orderNumber",
              "item_list": {
                "items": [
                  {
                    "name": "Order #$_orderNumber Payment",
                    "quantity": 1,
                    "price": _subtotalExclGst!.toStringAsFixed(2),
                    "currency": _currency ?? 'AUD'
                  }
                ],
              }
            }
          ],
          note: "Contact us for any questions on your order.",
          onSuccess: (Map params) async {
            Logger.info('PayPal success: $params');
            setState(() => _isProcessing = true);
            try {
              // Call backend to fix order status
              await _paymentService.processPayPal(
                orderNumber: _orderNumber!,
                orderId: _orderId!,
                amount: _amount!,
                currency: _currency ?? 'AUD',
                paymentResult: Map<String, dynamic>.from(params),
              );

              await StorageService.clearCartData();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/order-placed',
                  (route) => false,
                  arguments: {
                    'payment_method': 'PayPal',
                    'payment_token': params['orderID'] ?? params['paymentID'],
                  },
                );
              }
            } catch (e) {
              Logger.error('Error processing PayPal on backend', e);
              if (mounted) {
                Fluttertoast.showToast(msg: 'Payment success but failed to update order.');
              }
            } finally {
              if (mounted) setState(() => _isProcessing = false);
            }
          },
          onError: (error) {
            Logger.error('PayPal error', error);
            Fluttertoast.showToast(msg: 'PayPal Error: ${error.toString()}');
          },
          onCancel: (params) {
            Logger.info('PayPal cancelled: $params');
            Fluttertoast.showToast(msg: 'PayPal payment cancelled.');
          },
        ),
      ),
    );
  }

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

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final previousPayable = _amount;
      
      // DEBUG: Print values BEFORE applying coupon
      debugPrint('╔════════════════════════════════════════════════════════════╗');
      debugPrint('║          VALUE BEFORE APPLY COUPON                         ║');
      debugPrint('╠════════════════════════════════════════════════════════════╣');
      debugPrint('║ Total Amount: $_amount');
      debugPrint('║ Subtotal: $_subtotalExclGst');
      debugPrint('║ Shipping: $_shippingCost');
      debugPrint('║ GST/Tax: $_gstAmount');
      debugPrint('║ Discount: $_discountAmount');
      debugPrint('║ Coupon Code: $_couponCode');
      debugPrint('║ Coupon Applied: $_isCouponApplied');
      debugPrint('╚════════════════════════════════════════════════════════════╝');
      
      final cartContainer = await _getPaymentCartContainer();
      final cartForCoupon = cartContainer?['cart'] as Map<String, dynamic>?;

      debugPrint('╔════════════════ COUPON APPLY CART DEBUG ════════════════╗');
      debugPrint('║ cartContainer keys: ${cartContainer?.keys.join(", ") ?? "null"}');
      debugPrint('║ cartForCoupon: ${cartForCoupon?.length ?? 0} items');
      if (cartForCoupon != null) {
        cartForCoupon.forEach((key, item) {
          debugPrint('║   - $key: qty=${item['qty']}, price=${item['price']}');
        });
      }
      debugPrint('╚════════════════════════════════════════════════════════╝');

      if (cartForCoupon == null || cartForCoupon.isEmpty) {
        Fluttertoast.showToast(msg: 'Cart is empty');
        return;
      }

      final response = await _cartService.applyCoupon({
        'old_cart': cartForCoupon,
        'code': code,
      });

      if (response['cart'] == null) {
        final errorMessage = (response['message']?.toString().trim().isNotEmpty ?? false)
            ? response['message'].toString().trim()
            : 'Unable to apply promo code.';
        Fluttertoast.showToast(
          msg: errorMessage,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      final shipping = _toDouble(response['shipping']) ??
          _toDouble(response['normal_shipping_cost']) ??
          _toDouble(response['shipping_cost']) ??
          0.0;
      final freightRule = _resolveFreightRule(
        rawShippingCost: shipping,
        orderType: (() {
          final fromRoot = _extractOrderType(data: response);
          if (fromRoot.isNotEmpty) return fromRoot;
          return _extractOrderTypeFromCartContainer(response);
        })(),
        showRequestFreightCost:
            response['show_request_freight_cost'] ??
            _extractFreightCostFlagFromCartItems(response),
        showFreeShippingIcon:
            response['show_free_shipping_icon'] ??
            _extractFreeShippingIconFromCartItems(response),
      );
      final effectiveShipping = freightRule.shippingCost;
      final gst = _toDouble(response['tax']) ?? 0.0;
      final totalWithGstFromResponse =
          _toDouble(response['total_with_gst']) ?? 0.0;
      final discountFromResponse = _toDouble(response['discount']) ?? 0.0;

      double subtotal = totalWithGstFromResponse - effectiveShipping - gst;
      if (subtotal <= 0) {
        subtotal = _subtotalFromCartResponse(response);
      }

      final totalWithGst = totalWithGstFromResponse > 0
          ? totalWithGstFromResponse
          : (subtotal + effectiveShipping + gst);
      debugPrint(
        'PAYMENT_TOTAL_DEBUG[apply]: api_total=$totalWithGstFromResponse, subtotal=$subtotal, shipping=$effectiveShipping, gst=$gst, final_total=$totalWithGst',
      );

      if (mounted) {
        setState(() {
          _shippingCost = effectiveShipping;
          _gstAmount = gst;
          _amount = totalWithGst;
          _subtotalExclGst = subtotal;
          _discountAmount = discountFromResponse;

          _hasPendingFreightQuote = freightRule.hasPendingFreightQuote;
          _showFreeShippingLabel = freightRule.showFreeShippingLabel;
        });
      }

      if (mounted) {
        final coupon = response['coupon'] as Map<String, dynamic>?;
        final couponCode = coupon?['code']?.toString();
        final couponPrice = _toDouble(coupon?['price']) ?? 0.0;
        final couponType =
            (coupon?['coupon_discount_type'] ?? '').toString().toLowerCase();

        double computedCouponDiscount = discountFromResponse;
        if (computedCouponDiscount <= 0 && couponPrice > 0) {
          if (couponType == 'percentage' || couponType == 'percent') {
            computedCouponDiscount = (subtotal * couponPrice) / 100;
          } else {
            computedCouponDiscount = couponPrice;
          }
        }

        if (mounted) {
          setState(() {
            // Use only API response data - trust backend to handle coupon correctly
            _couponCode = couponCode ?? code;
            
            // Format offer subtitle from coupon response
            if (couponType == 'percentage' || couponType == 'percent') {
              _couponOfferSubtitle = '${couponPrice.toStringAsFixed(0)}% OFF';
            } else {
              _couponOfferSubtitle = '\$${couponPrice.toStringAsFixed(2)} OFF';
            }
            
            _couponDiscount = computedCouponDiscount > 0 ? computedCouponDiscount : 0.0;
            _isCouponApplied = true;
          });
        }
      }

      try {
        if (_orderNumber != null) {
          await _paymentService.createPaymentIntent(
            orderNumber: _orderNumber!,
            amount: _amount ?? 0.0,
            currency: _currency ?? 'AUD',
          );
        }
      } catch (_) {}

      // DEBUG: Print values AFTER applying coupon
      debugPrint('╔════════════════════════════════════════════════════════════╗');
      debugPrint('║          VALUE AFTER APPLY COUPON                          ║');
      debugPrint('╠════════════════════════════════════════════════════════════╣');
      debugPrint('║ Total Amount: $_amount');
      debugPrint('║ Subtotal: $_subtotalExclGst');
      debugPrint('║ Shipping: $_shippingCost');
      debugPrint('║ GST/Tax: $_gstAmount');
      debugPrint('║ Discount: $_discountAmount');
      debugPrint('║ Coupon Code: $_couponCode');
      debugPrint('║ Coupon Discount: $_couponDiscount');
      debugPrint('║ Coupon Applied: $_isCouponApplied');
      debugPrint('║ Coupon Offer: $_couponOfferSubtitle');
      debugPrint('╚════════════════════════════════════════════════════════════╝');

      final successMessage = (response['message']?.toString().trim().isNotEmpty ?? false)
          ? response['message'].toString().trim()
          : 'Promo code applied';
      Fluttertoast.showToast(
        msg: successMessage,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to apply promo code.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _fetchAvailableCoupons({VoidCallback? onUpdate}) async {
    if (_isLoadingCoupons) return;
    if (_availableCoupons.isNotEmpty) return;

    if (mounted) setState(() => _isLoadingCoupons = true);
    if (onUpdate != null) onUpdate();

    try {
      final coupons = await _cartService.getAvailableCoupons();
      if (mounted) {
        setState(() {
          _availableCoupons = coupons;
          _isLoadingCoupons = false;
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
                                  final discountValue = coupon['price']?.toString() ?? '';
                                  final discountType = (coupon['coupon_discount_type']?.toString() ?? '').toLowerCase();
                                  
                                  String discountLabel = '';
                                  if (discountType == 'percent' || discountType == 'percentage') {
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
                                      leading: const Icon(Icons.local_offer, color: Color(0xFF151D51)),
                                      title: Text(
                                        code,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      subtitle: Text(
                                        discountLabel,
                                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600),
                                      ),
                                      trailing: const Icon(Icons.chevron_right, size: 20),
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
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // DEBUG: Print values BEFORE removing coupon
      debugPrint('╔════════════════════════════════════════════════════════════╗');
      debugPrint('║          VALUE BEFORE REMOVE COUPON                        ║');
      debugPrint('╠════════════════════════════════════════════════════════════╣');
      debugPrint('║ Total Amount: $_amount');
      debugPrint('║ Subtotal: $_subtotalExclGst');
      debugPrint('║ Shipping: $_shippingCost');
      debugPrint('║ GST/Tax: $_gstAmount');
      debugPrint('║ Discount: $_discountAmount');
      debugPrint('║ Coupon Code: $_couponCode');
      debugPrint('║ Coupon Discount: $_couponDiscount');
      debugPrint('║ Coupon Applied: $_isCouponApplied');
      debugPrint('╚════════════════════════════════════════════════════════════╝');
      
      final cartContainer = await _getPaymentCartContainer();
      final oldCart = cartContainer?['cart'] as Map<String, dynamic>?;

      debugPrint('COUPON_REMOVE_CART_PAYLOAD_SOURCE: ${cartContainer != null ? "ok (${oldCart?.length ?? 0} items)" : "null"}');

      if (oldCart != null) {
        final payload = {
          'old_cart': oldCart,
          'code': (_couponCode ?? _couponController.text.trim()),
        };

        final response = await _cartService.removeCoupon(payload);

        final sanitizedResponse = Map<String, dynamic>.from(response);
        // Backend may still return a coupon object even after remove.
        // Keep local state source-of-truth as coupon removed.
        sanitizedResponse.remove('coupon');
        sanitizedResponse['discount'] = 0;
        sanitizedResponse['coupon_discount'] = 0;

        final shipping = _toDouble(sanitizedResponse['shipping']) ??
            _toDouble(sanitizedResponse['normal_shipping_cost']) ??
            _toDouble(sanitizedResponse['shipping_cost']) ??
            0.0;
        final freightRule = _resolveFreightRule(
          rawShippingCost: shipping,
          orderType: (() {
            final fromRoot = _extractOrderType(data: sanitizedResponse);
            if (fromRoot.isNotEmpty) return fromRoot;
            return _extractOrderTypeFromCartContainer(sanitizedResponse);
          })(),
          showRequestFreightCost:
              sanitizedResponse['show_request_freight_cost'] ??
              _extractFreightCostFlagFromCartItems(sanitizedResponse),
          showFreeShippingIcon:
              sanitizedResponse['show_free_shipping_icon'] ??
              _extractFreeShippingIconFromCartItems(sanitizedResponse),
        );
        final effectiveShipping = freightRule.shippingCost;
        final gst = _toDouble(sanitizedResponse['tax']) ?? 0.0;
        final totalWithGstFromResponse =
            _toDouble(sanitizedResponse['total_with_gst']) ?? 0.0;

        double subtotal = totalWithGstFromResponse - effectiveShipping - gst;
        if (subtotal <= 0) {
          subtotal = _subtotalFromCartResponse(sanitizedResponse);
        }

        final totalWithGst = totalWithGstFromResponse > 0
            ? totalWithGstFromResponse
            : (subtotal + effectiveShipping + gst);
        debugPrint(
          'PAYMENT_TOTAL_DEBUG[remove]: api_total=$totalWithGstFromResponse, subtotal=$subtotal, shipping=$effectiveShipping, gst=$gst, final_total=$totalWithGst',
        );

        if (mounted) {
          setState(() {
            _shippingCost = effectiveShipping;
            _gstAmount = gst;
            _amount = totalWithGst;
            _subtotalExclGst = subtotal;
            _discountAmount = _toDouble(sanitizedResponse['discount']) ?? 0.0;

            _hasPendingFreightQuote = freightRule.hasPendingFreightQuote;
            _showFreeShippingLabel = freightRule.showFreeShippingLabel;

            _couponCode = null;
            _couponOfferSubtitle = null;
            _couponDiscount = 0.0;
            _isCouponApplied = false;
            _couponController.clear();
          });
        }

        if (mounted) {
          try {
            if (_orderNumber != null) {
              await _paymentService.createPaymentIntent(
                orderNumber: _orderNumber!,
                amount: _amount ?? 0.0,
                currency: _currency ?? 'AUD',
              );
            }
          } catch (_) {}
        }

        // DEBUG: Print values AFTER removing coupon
        debugPrint('╔════════════════════════════════════════════════════════════╗');
        debugPrint('║          VALUE AFTER REMOVE COUPON                         ║');
        debugPrint('╠════════════════════════════════════════════════════════════╣');
        debugPrint('║ Total Amount: $_amount');
        debugPrint('║ Subtotal: $_subtotalExclGst');
        debugPrint('║ Shipping: $_shippingCost');
        debugPrint('║ GST/Tax: $_gstAmount');
        debugPrint('║ Discount: $_discountAmount');
        debugPrint('║ Coupon Code: $_couponCode');
        debugPrint('║ Coupon Discount: $_couponDiscount');
        debugPrint('║ Coupon Applied: $_isCouponApplied');
        debugPrint('╚════════════════════════════════════════════════════════════╝');

        final removedMessage = (response['message']?.toString().trim().isNotEmpty ?? false)
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
        });
      }
    }
  }

  /// Handle Complete Order (Pay Later flow)
  Future<void> _handleCompleteOrder() async {
    if (_isProcessing) return;

    // Log current order data for verification
    final order = _orderData?['order'] as Map?;
    final apiPrice = order?['pay_amount'] ?? order?['total'];
    debugPrint('###############Start COMPLETE ORDER####################');
    debugPrint('API ORDER PRICE: $apiPrice');
    debugPrint('UI TOTAL PAYABLE: $_amount');
    debugPrint('###############End COMPLETE ORDER#######################');

    setState(() => _isProcessing = true);

    try {
      // Since it's Pay Later, we bypass payment gateways
      await StorageService.clearCartData();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/order-placed',
          (route) => false,
          arguments: {'payment_method': 'Manual / Freight Quote'},
        );
      }
    } catch (e) {
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

  bool get _canShowPaymentOptionsByStatus =>
      _orderPaymentStatus == 'partial' || _orderPaymentStatus == 'unpaid';

  bool get _canShowAlternativePaymentMethods =>
      _manualOrderByAdmin == 0 && _isTradeUser == 0;

  String get _effectiveSelectedPaymentMethod {
    final method = _selectedPaymentMethod.trim();
    if (method.isEmpty) return 'Credit Card';

    final isAlternativeMethod =
        method == 'PayPal' || method == 'Google Pay' || method == 'Apple Pay';
    if (isAlternativeMethod && !_canShowAlternativePaymentMethods) {
      return 'Credit Card';
    }

    return method;
  }

  @override
  Widget build(BuildContext context) {
    final bool isPayLaterFlow = widget.arguments?['is_pay_later'] == true;
    final bool fromMyOrdersPayment =
        widget.arguments?['from_my_orders_payment'] == true;
    // Back from My Orders payment → Profile (avoid popping to Order Details)
    // EXCEPT for Pay Later flow where we explicitly want to go back to Order Details.
    final bool useProfileBack = fromMyOrdersPayment && !isPayLaterFlow;
    final effectivePaymentMethod = _effectiveSelectedPaymentMethod;
    return PopScope(
      canPop: !useProfileBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && useProfileBack) {
          _navigateToProfile();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F8F8),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          leading: useProfileBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _navigateToProfile,
                )
              : null,
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildOrderSummaryCard(),
                      const SizedBox(height: 24),

                      if (_isPayLater) ...[
                        _buildSubmitButton(),
                      ] else if (_canShowPaymentOptionsByStatus) ...[
                        _buildPaymentMethodSection(),
                        const SizedBox(height: 24),

                        if (effectivePaymentMethod == 'Credit Card') ...[
                          const SizedBox(height: 12),
                          _buildCardInputFields(),
                          const SizedBox(height: 12),
                          _buildSubmitButton(),
                        ] else if (effectivePaymentMethod == 'PayPal') ...[
                          _buildPayPalButton(),
                        ] else if (effectivePaymentMethod == 'Google Pay') ...[
                          _buildGooglePayButton(),
                        ] else if (effectivePaymentMethod.isNotEmpty) ...[
                          _buildSubmitButton(),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    final bool isIOS = Platform.isIOS;
    final effectivePaymentMethod = _effectiveSelectedPaymentMethod;

    // Payment options sirf tab dikhein jab Partial ya Unpaid ho
    final bool canShowPayments = _canShowPaymentOptionsByStatus;

    if (!canShowPayments) return const SizedBox.shrink();

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

            // 1. Credit Card — hamesha dikhega
            GestureDetector(
              onTap: () =>
                  setState(() => _selectedPaymentMethod = 'Credit Card'),
              child: _paymentOptionRow(
                'Credit Card',
                Icons.credit_card,
                effectivePaymentMethod == 'Credit Card',
              ),
            ),

            // Info banner when alternative methods are restricted
            if (!_canShowAlternativePaymentMethods) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFCC02)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Color(0xFFF9A825)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _manualOrderByAdmin == 1
                            ? 'This order was created by admin. Only Credit Card payment is available.'
                            : 'Trade account orders can only be paid via Credit Card.',
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

            // 2. PayPal + Google/Apple Pay —
            // sirf jab manual_order_by_admin == 0 AND is_trade_user == 0
            if (_canShowAlternativePaymentMethods) ...[
              GestureDetector(
                onTap: () => setState(() => _selectedPaymentMethod = 'PayPal'),
                child: _paymentOptionRow(
                  'PayPal',
                  Icons.payment,
                  effectivePaymentMethod == 'PayPal',
                ),
              ),
              if (!kIsWeb && !isIOS) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () =>
                      setState(() => _selectedPaymentMethod = 'Google Pay'),
                  child: _paymentOptionRow(
                    'Google Pay',
                    Icons.account_balance_wallet,
                    effectivePaymentMethod == 'Google Pay',
                    isEnabled: true,
                    trailing: _isInitializingGooglePay
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                ),
                /*
                if (!kIsWeb && isIOS) ...[
                  const SizedBox(height: 12),
                  _paymentOptionRow(
                    'Apple Pay',
                    Icons.apple,
                    _selectedPaymentMethod == 'Apple Pay',
                    isEnabled: false,
                  ),
                ],
                */
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _paymentOptionRow(
    String title,
    IconData icon,
    bool isSelected, {
    bool isEnabled = true,
    Widget? trailing,
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
            Icon(
              icon,
              color: isSelected ? const Color(0xFF002e5b) : Colors.grey[600],
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

            // Item Total
            _summaryRow(
              'Total Of Items (excl. GST)',
              formatPrice(_subtotalExclGst),
            ),
            if (hasAppliedCoupon) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _couponOfferSubtitle != null && _couponOfferSubtitle!.isNotEmpty
                        ? '$_couponCode $_couponOfferSubtitle'
                        : '$_couponCode',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_couponDiscount > 0)
                    Text(
                      '-${formatPrice(_couponDiscount)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),

            // Special Discount (Red) - Mobile Only
            if (_orderSource == 'mobile' && (_specialDiscount ?? 0) > 0) ...[
              _summaryRow(
                'Special Discount',
                '-$currencySign${_specialDiscount!.toStringAsFixed(2)}',
                valueColor: Colors.red,
                labelColor: Colors.red,
              ),
              const SizedBox(height: 8),
            ],

            // Shipping Cost (Red)
            _summaryRow(
              '*Shipping Cost (excl. GST)',
              formatPrice(_shippingCost),
              valueColor: const Color(0xFFF44336),
              labelColor: const Color(0xFFF44336),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.8),
            const SizedBox(height: 12),

            // Total without GST
            _summaryRow(
              'Total without GST',
              formatPrice(
                (_subtotalExclGst ?? 0.0) +
                    (_shippingCost ?? 0.0) -
                    (_specialDiscount ?? 0.0),
              ),
            ),
            const SizedBox(height: 8),

            // GST Row
            _summaryRow('GST', formatPrice(_gstAmount)),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.8),
            const SizedBox(height: 12),

            // Total (incl. GST)
            _summaryRow(
              'Total (incl. GST)',
              formatPrice(total),
              isBoldLabel: true,
            ),
            const SizedBox(height: 16),

            // Promo Code Section
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showCouponsModal,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AbsorbPointer(
                        absorbing: true,
                        child: TextField(
                          controller: _couponController,
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
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
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
                  child: Text(
                    hasAppliedCoupon ? 'Remove' : 'Apply',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: (_isLoadingCoupons || _isProcessing) ? null : _showCouponsModal,
                icon: _isLoadingCoupons
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF151D51)),
                        ),
                      )
                    : const Icon(Icons.local_offer_outlined, size: 16),
                label: Text(
                  _isLoadingCoupons ? 'Loading Offers...' : 'View Available Offers',
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
            // Show applied promo code message
            if (hasAppliedCoupon) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
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
            ],
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 0.8),
            const SizedBox(height: 16),

            // Total Payable Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '*Total Payable Amount :',
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

            // Pending Freight Quote
            if (_hasPendingFreightQuote) ...[
              const SizedBox(height: 8),
              const Text(
                'Pending Freight Quote',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (!_hasPendingFreightQuote && _showFreeShippingLabel) ...[
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing
            ? null
            : (_isPayLater ? _handleCompleteOrder : _handlePayment),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF002e5b),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _isPayLater ? 'COMPLETE ORDER' : 'PAY NOW',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildPayPalButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _handlePayPalPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF002e5b),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'PAY NOW',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildGooglePayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isProcessing || _isPaymentProcessing)
            ? null
            : _handleGooglePayClick,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF002e5b),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'PAY NOW',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildCardInputFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CARD DETAILS',
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
            hint: 'E.g. JOHN DOE',
            textCapitalization: TextCapitalization.characters,
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
                  obscureText: true,
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
