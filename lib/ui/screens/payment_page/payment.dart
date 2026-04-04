import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:apcproject/services/storage_service.dart';
import 'package:apcproject/data/services/payment_service.dart';
import 'package:apcproject/data/services/cart_service.dart';
import 'package:cybersource_inapp/cybersource_inapp.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:apcproject/ui/screens/payment_page/cybersource_webview_page.dart';
import 'package:pay/pay.dart';
import 'package:apcproject/config/environment.dart';
import 'package:apcproject/data/models/user_model.dart';

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

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const PaymentPage({super.key, this.arguments});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final PaymentService _paymentService = PaymentService();
  final CartService _cartService = CartService();
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

  // Coupon variables
  final TextEditingController _couponController = TextEditingController();
  String? _couponCode;
  double _couponDiscount = 0.0;
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
    _paymentResultSubscription?.cancel();
    _couponController.dispose();
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
      _isGooglePayAvailable =
          await _payClient!.userCanPay(PayProvider.google_pay);
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
    const eventChannel =
        EventChannel('plugins.flutter.io/pay/payment_result');
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

      final orderData = await StorageService.getOrderData();
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
  _ShippingBreakdown _breakdownFromStoredOrder(
    Map<String, dynamic> data,
  ) {
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
        : (parse(order?['pay_amount']) > 0 ? parse(order?['pay_amount']) : parse(order?['subtotal']));

    double gstAmount = parse(data['tax']) > 0
        ? parse(data['tax'])
        : parse(order?['tax_amount']);

    final orderType = (order?['order_type'] ?? '').toString().toLowerCase();
    final double shippingCost = (orderType == 'large')
        ? parse(order?['shipping_cost'])
        : parse(order?['normal_shipping_cost']);

    final double totalAmount = parse(data['grand_total']) > 0
        ? parse(data['grand_total'])
        : (parse(order?['total']) > 0
            ? parse(order?['total'])
            : parse(order?['pay_amount']));

    final double discountAmount = parse(data['discount']) > 0
        ? parse(data['discount'])
        : parse(order?['discount']);

    final orderSource = data['order_source']?.toString().toLowerCase() ?? 
                       order?['order_source']?.toString().toLowerCase() ?? '';
    double specialDiscount = 0.0;
    if (orderSource == 'mobile') {
      specialDiscount = parse(order?['special_discount']);
    }

    // Subtotal logic synced with Order Details (Work backwards from Grand Total)
    subtotalExclGst = (totalAmount - gstAmount - shippingCost + specialDiscount);

    return _ShippingBreakdown(
      subtotalExclGst: subtotalExclGst,
      shippingCost: shippingCost,
      gstAmount: gstAmount,
      discountAmount: discountAmount,
      amount: totalAmount,
      specialDiscount: specialDiscount,
      hasPendingFreightQuote: orderType == 'large' || parse(data['show_request_freight_cost']) == 1,
      isPayLater: false,
      showFreeShippingLabel: !(orderType == 'large' || parse(data['show_request_freight_cost']) == 1) &&
          parse(data['show_free_shipping_icon']) == 1,
    );
  }

  Future<void> _initializePayment() async {
    try {
      debugPrint('=== PAYMENT PAGE INITIALIZATION ===');

      final orderData = await StorageService.getOrderData();

      debugPrint(
        'Order data: ${orderData != null ? "Found" : "Not found"}',
      );

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

      setState(() {
        _orderData = orderData;
        final statusRoot =
            (orderData['order_status'] ?? '').toString().toLowerCase().trim();
        final statusOrder = (orderData['order']?['order_status'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
        _isAwaitingFreight =
            statusRoot.contains('awaiting') || statusOrder.contains('awaiting');
        debugPrint(
          'Freight Status Detected: $_isAwaitingFreight (Root: $statusRoot, Order: $statusOrder)',
        );
      });

      final order = orderData['order'] as Map<String, dynamic>?;
      final orderNumber = order?['order_number'] as String?;
      final orderId = order?['id'] as int?;

      // Initialize status-based flags
      _manualOrderByAdmin = (order?['manual_order_by_admin'] as num?)?.toInt() ?? 0;
      _orderPaymentStatus = (order?['payment_status'] ?? '').toString().toLowerCase();

      // Retrieve trade user status from StorageService
      final UserModel? currentUser = await StorageService.getUserData();
      _isTradeUser = currentUser?.isTradeUser ?? 0;

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
        final postcode =
            (checkoutData?['post_code'] as String?)?.trim() ?? '';
        final cartResponse = await StorageService.getCartData();
        final oldCart = cartResponse?['cart'] as Map<String, dynamic>?;
        final bool fromMyOrdersPayment = widget.arguments?['from_my_orders_payment'] == true;

        if (!fromMyOrdersPayment && postcode.isNotEmpty && oldCart != null) {
          final shippingResponse = await _cartService.calculateShipping({
            'postcode': postcode,
            'old_cart': oldCart,
          });

          double? toDouble(dynamic v) {
            if (v == null) return null;
            if (v is num) return v.toDouble();
            if (v is String) return double.tryParse(v.replaceAll(',', ''));
            return null;
          }

          final orderType = (shippingResponse['order_type'] ?? '').toString().toLowerCase();
          shippingCost = (orderType == 'large')
              ? toDouble(shippingResponse['shipping_cost']) ?? 0.0
              : toDouble(shippingResponse['normal_shipping_cost']) ?? 0.0;
 
          gstAmount = toDouble(shippingResponse['tax']);
          subtotalExclGst = toDouble(cartResponse?['totalPrice']);
 
          final discount = toDouble(cartResponse?['discount']);
          final couponDiscount = toDouble(cartResponse?['coupon_discount']);
          discountAmount = discount ?? couponDiscount;
 
          amount = toDouble(shippingResponse['total_with_gst']) ?? amount;

          final showRequest =
              (shippingResponse['show_request_freight_cost'] as num?)
                      ?.toDouble() ??
                  0;
          _isPayLater = (shippingResponse['show_freight_cost_icon'] as num?)?.toInt() == 1;

          if (orderType == 'large' || showRequest > 0) {
            _hasPendingFreightQuote = true;
            _showFreeShippingLabel = false;
          } else {
            _hasPendingFreightQuote = false;
            _showFreeShippingLabel = (shippingResponse['show_free_shipping_icon'] as num?)?.toInt() == 1;
          }
        } else {
          final snap = _breakdownFromStoredOrder(orderData);
          subtotalExclGst = snap.subtotalExclGst;
          shippingCost = snap.shippingCost;
          gstAmount = snap.gstAmount;
          discountAmount = snap.discountAmount;
          amount = snap.amount;
          _hasPendingFreightQuote = snap.hasPendingFreightQuote;
          _isPayLater = snap.isPayLater;
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
        _isPayLater = snap.isPayLater;
        _showFreeShippingLabel = snap.showFreeShippingLabel;
      }

      // When user comes from My Orders → Pay Now, they are here to pay an
      // already-placed order. Freight/pay-later flags must not block payment UI.
      // My Orders Pay Now, Pay Later UI, or checkout freight — show payment UI
      final bool forcePaymentUi =
          widget.arguments?['is_pay_later'] == true ||
          widget.arguments?['checkout_freight_payment'] == true ||
          widget.arguments?['from_my_orders_payment'] == true;
      if (forcePaymentUi) {
        _isPayLater = false;
      }

      setState(() {
        _orderNumber = orderNumber;
        _orderId = orderId;
        _amount = amount > 0 ? amount : 0.0;
        _currency = 'AUD';
        
        _shippingCost = shippingCost ?? 0.0;
        _gstAmount = gstAmount ?? 0.0;
        _discountAmount = discountAmount ?? 0.0;
        
        _orderSource = (_orderData?['order_source'] ?? order?['order_source'] ?? '').toString().toLowerCase();
        
        final dynamic rawDisc = _orderData?['special_discount'] ?? order?['special_discount'];
        if (_orderSource == 'mobile' && rawDisc != null) {
          final String cleanPrice = rawDisc.toString().replaceAll(',', '').replaceAll('\$', '').trim();
          _specialDiscount = double.tryParse(cleanPrice) ?? 0.0;
        } else {
          _specialDiscount = 0.0;
        }

        // Mathematically consistent Subtotal (Total - GST - Shipping + Special Discount)
        // This ensures the breakdown always matches the final total exactly.
        _subtotalExclGst = (_amount! - _gstAmount! - _shippingCost! + (_specialDiscount ?? 0.0));

        if (_gstAmount! > 0 && _subtotalExclGst! > 0) {
          _gstRate = (_gstAmount! / _subtotalExclGst!) * 100;
        } else {
          _gstRate = 10.0;
        }
        _isLoading = false;
      });

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

  /// Handle payment submission
  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate() || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    debugPrint('=== _handlePayment START ===');
    try {
      debugPrint('Fetching capture context...');
      final captureContext = await CybersourceInapp.getCaptureContext();
      debugPrint('Capture context fetched successfully: ${captureContext.substring(0, 10)}...');

      if (mounted) {
        debugPrint('Pushing CybersourceWebViewPage...');
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CybersourceWebViewPage(
              captureContext: captureContext,
              orderId: _orderId!,
              orderNumber: _orderNumber!,
              amount: _amount ?? 0.0,
            ),
          ),
        );

        if (result != null && result['success'] == true) {
          await StorageService.clearCartData();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/order-placed',
              (route) => false,
              arguments: {
                'payment_token': result['token'],
                'payment_method': 'Cybersource Card',
              },
            );
          }
        } else {
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Payment cancelled or failed. Please try again.',
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
            setState(() => _isProcessing = false);
          }
        }
      }
    } catch (e) {
      debugPrint('Payment error: $e');
      if (mounted) {
        Fluttertoast.showToast(msg: 'Payment failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Handle PayPal payment
  Future<void> _handlePayPalPayment() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // Logic for real PayPal SDK would go here
      // For testing, mock success
      await _paymentService.processPayPal(
        orderNumber: _orderNumber!,
        orderId: _orderId!,
        amount: _amount!,
        currency: _currency ?? 'AUD',
        paymentResult: {'orderID': 'PAYPAL_MOCK_TOKEN'},
      );
      await StorageService.clearCartData();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/order-placed',
          (route) => false,
          arguments: {'payment_method': 'PayPal'},
        );
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: 'PayPal payment failed.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
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
      final cartResponse = await StorageService.getCartData();
      if (cartResponse == null || cartResponse['cart'] == null) {
        Fluttertoast.showToast(msg: 'Cart is empty');
        return;
      }

      final response = await _cartService.applyCoupon({
        'old_cart': cartResponse['cart'],
        'code': code,
      });

      if (response['cart'] == null) {
        Fluttertoast.showToast(
          msg: 'Unable to apply promo code.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      await StorageService.saveCartData(response);
      await _initializePayment(); // Refresh UI totals

      if (mounted) {
        setState(() {
          _couponCode = code;
          _isCouponApplied = true;
          final oldTotal = (cartResponse['totalPrice'] as num?)?.toDouble();
          final newTotal = (response['totalPrice'] as num?)?.toDouble();
          _couponDiscount = (oldTotal != null && newTotal != null) ? (oldTotal - newTotal) : 0.0;
        });
      }

      Fluttertoast.showToast(
        msg: response['message'] ?? 'Promo code applied',
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

  Future<void> _removeCoupon() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final cartResponse = await StorageService.getCartData();
      final oldCart = cartResponse?['cart'] as Map<String, dynamic>?;

      if (oldCart != null) {
        final payload = {
          'old_cart': oldCart,
          'code': _couponCode ?? '',
        };

        final response = await _cartService.removeCoupon(payload);
        
        await StorageService.saveCartData(response);
        await _initializePayment(); // Refresh UI totals

        if (mounted) {
          setState(() {
            _couponCode = null;
            _couponDiscount = 0.0;
            _isCouponApplied = false;
            _couponController.clear();
          });
        }

        Fluttertoast.showToast(
          msg: response['message'] ?? 'Promo code removed',
          backgroundColor: Colors.orange,
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

  @override
  Widget build(BuildContext context) {
    final bool isPayLaterFlow = widget.arguments?['is_pay_later'] == true;
    final bool fromMyOrdersPayment =
        widget.arguments?['from_my_orders_payment'] == true;
    // Back from My Orders payment → Profile (avoid popping to Order Details)
    // EXCEPT for Pay Later flow where we explicitly want to go back to Order Details.
    final bool useProfileBack = fromMyOrdersPayment && !isPayLaterFlow;
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
          isPayLaterFlow ? 'Review Order' : 'Payment',
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

                    if (!_isPayLater) ...[
                      _buildPaymentMethodSection(),
                      const SizedBox(height: 24),

                      if (_selectedPaymentMethod == 'Credit Card') ...[
                        const SizedBox(height: 12),
                        _buildSubmitButton(),
                      ] else if (_selectedPaymentMethod == 'PayPal') ...[
                        _buildPayPalButton(),
                      ] else if (_selectedPaymentMethod == 'Google Pay') ...[
                        _buildGooglePayButton(),
                      ] else if (_selectedPaymentMethod.isNotEmpty) ...[
                        _buildSubmitButton(),
                      ],
                    ] else ...[
                      _buildSubmitButton(),
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

    // Payment options sirf tab dikhein jab Partial ya Unpaid ho
    final bool canShowPayments =
        _orderPaymentStatus == 'partial' || _orderPaymentStatus == 'unpaid';

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
                _selectedPaymentMethod == 'Credit Card',
              ),
            ),
            const SizedBox(height: 12),

            // 2. PayPal + Google/Apple Pay —
            // sirf jab manual_order_by_admin == 0 AND is_trade_user == 0
            if (_manualOrderByAdmin == 0 && _isTradeUser == 0) ...[
              GestureDetector(
                onTap: () => setState(() => _selectedPaymentMethod = 'PayPal'),
                child: _paymentOptionRow(
                  'PayPal',
                  Icons.payment,
                  _selectedPaymentMethod == 'PayPal',
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
                    _selectedPaymentMethod == 'Google Pay',
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
              ] else if (!kIsWeb && isIOS) ...[
                const SizedBox(height: 12),
                _paymentOptionRow(
                  'Apple Pay',
                  Icons.apple,
                  _selectedPaymentMethod == 'Apple Pay',
                  isEnabled: false,
                ),
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
              formatPrice((_subtotalExclGst ?? 0.0) + (_shippingCost ?? 0.0) - (_specialDiscount ?? 0.0)),
            ),
            const SizedBox(height: 8),

            // GST Row
            _summaryRow(
              'GST',
              formatPrice(_gstAmount),
            ),
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
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _applyPromoCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(90, 44),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            // Show applied promo code message
            if (_couponCode != null && _couponCode!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Promo code "$_couponCode" applied',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isProcessing ? null : _removeCoupon,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
}
