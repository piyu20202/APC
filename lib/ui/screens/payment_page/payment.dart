import 'package:flutter/material.dart';
import 'package:apcproject/services/storage_service.dart';
import 'package:apcproject/data/services/payment_service.dart';
import 'package:apcproject/data/services/cart_service.dart';
import 'package:cybersource_inapp/cybersource_inapp.dart';
import 'package:apcproject/core/exceptions/api_exception.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:apcproject/providers/auth_provider.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

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
  double? _discountAmount;
  double? _gstRate;
  bool _hasPendingFreightQuote = false;
  bool _isPayLater = false;
  bool _showFreeShippingLabel = false;

  // Payment form controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // PayPal config cache
  Map<String, dynamic>? _paypalConfig;

  @override
  void initState() {
    super.initState();
    // Pre-fill test card details for testing
    _cardNumberController.text = '4111 1111 1111 1111';
    _cardholderNameController.text = 'Test User';
    _expiryController.text = '12/25';
    _cvvController.text = '123';
    _initializePayment();
    _loadPayPalConfig();
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
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  /// Initialize payment by loading order data and creating payment intent
  Future<void> _initializePayment() async {
    try {
      debugPrint('=== PAYMENT PAGE INITIALIZATION ===');

      // Get order data from storage
      final orderData = await StorageService.getOrderData();
      debugPrint(
        'Order data from storage: ${orderData != null ? "Found" : "Not found"}',
      );

      if (orderData == null) {
        debugPrint('ERROR: Order data is null');
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Order data not found. Please try again.',
            toastLength: Toast.LENGTH_LONG,
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      setState(() {
        _orderData = orderData;
      });

      // Extract order details from API response
      final order = orderData['order'] as Map<String, dynamic>?;
      final orderNumber = order?['order_number'] as String?;
      final orderId = order?['id'] as int?;

      // Use 'pay_amount' instead of 'total' based on API response
      final payAmount = order?['pay_amount'] as num?;
      final totalAmount = order?['total'] as num?;
      double amount = (payAmount ?? totalAmount)?.toDouble() ?? 0.0;

      if (orderNumber == null || orderId == null) {
        if (mounted) {
          Fluttertoast.showToast(msg: 'Invalid order data.');
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Call shipping API to get updated shipping, tax, and total
      double? subtotalExclGst;
      double? shippingCost;
      double? gstAmount;
      double? discountAmount;

      try {
        final checkoutData = await StorageService.getCheckoutData();
        final postcode = checkoutData?['post_code'] as String?;
        final cartResponse = await StorageService.getCartData();
        final oldCart = cartResponse?['cart'] as Map<String, dynamic>?;

        if (postcode != null && oldCart != null) {
          final shippingPayload = {
            'postcode': postcode,
            'old_cart': oldCart,
          };

          // Call shipping API
          final shippingResponse =
              await _cartService.calculateShipping(shippingPayload);

          // Helper function to convert to double
          double? toDouble(dynamic v) {
            if (v == null) return null;
            if (v is num) return v.toDouble();
            if (v is String) return double.tryParse(v.replaceAll(',', ''));
            return null;
          }

          shippingCost = toDouble(shippingResponse['shipping']) ?? 0.0;
          gstAmount = toDouble(shippingResponse['tax']);
          subtotalExclGst = toDouble(cartResponse?['totalPrice']);

          final discount = toDouble(cartResponse?['discount']);
          final couponDiscount = toDouble(cartResponse?['coupon_discount']);
          discountAmount = discount ?? couponDiscount;

          amount = toDouble(shippingResponse['total_with_gst']) ?? amount;

          // Set pending freight quote flag inside this block where shippingResponse is available
          final showRequest = (shippingResponse['show_request_freight_cost'] as num?)?.toDouble() ?? 0;
          _hasPendingFreightQuote = showRequest > 0;
          
          // Scenario 1 & 3: If any item has freight icon, it's a Pay Later order
          _isPayLater = (shippingResponse['show_freight_cost_icon'] as num?)?.toInt() == 1;
          
          // Scenario 2: Show free shipping label only if it's NOT a pay later order
          _showFreeShippingLabel = !_isPayLater && (shippingResponse['show_free_shipping_icon'] as num?)?.toInt() == 1;
        }
      } catch (e) {
        debugPrint('Error calling shipping API: $e');
      }

      setState(() {
        _orderNumber = orderNumber;
        _orderId = orderId;
        _amount = amount > 0 ? amount : 0.0;
        _currency = 'AUD';
        _subtotalExclGst = subtotalExclGst;
        _shippingCost = shippingCost;
        _gstAmount = gstAmount;
        _discountAmount = discountAmount;
        _isPayLater = _isPayLater;
        _showFreeShippingLabel = _showFreeShippingLabel;
        
        // Dynamic GST rate calculation: calculate based on subtotal (excl. GST)
        if (gstAmount != null && subtotalExclGst != null && subtotalExclGst > 0) {
          _gstRate = (gstAmount / subtotalExclGst) * 100;
        } else {
          _gstRate = 10.0;
        }
        _isLoading = false;
      });

      // Create payment intent
      try {
        await _paymentService.createPaymentIntent(
          orderNumber: orderNumber,
          amount: amount > 0 ? amount : 0.0,
          currency: 'AUD',
        );
      } catch (_) {}

    } catch (e) {
      debugPrint('Error initializing payment: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

    try {
      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      final expiryParts = _expiryController.text.split('/');
      final expiryMonth = expiryParts[0].padLeft(2, '0');
      final expiryYear = '20${expiryParts[1]}';

      if (PaymentService.enableCardPaymentApi) {
        final response = await _paymentService.processCardPaymentRaw(
          orderId: _orderId!,
          orderNumber: _orderNumber!,
          amount: _amount ?? 0.0,
          currency: _currency ?? 'AUD',
          cardNumber: cardNumber,
          expiryMonth: expiryMonth,
          expiryYear: expiryYear,
          cvv: _cvvController.text,
          cardholderName: _cardholderNameController.text,
        );

        await StorageService.clearCartData();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/order-placed',
            (route) => false,
            arguments: {'payment_method': 'Card'},
          );
        }
      } else {
        final captureContext = await CybersourceInapp.getCaptureContext();
        final token = await CybersourceInapp.tokenizeCard(
          captureContext: captureContext,
          cardNumber: cardNumber,
          expiryMonth: expiryMonth,
          expiryYear: expiryYear,
          cvv: _cvvController.text,
          cardholderName: _cardholderNameController.text,
        );

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/order-placed',
            (route) => false,
            arguments: {
              'payment_token': token,
              'payment_method': 'Cybersource Card',
            },
          );
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
        paymentResult: {
          'orderID': 'PAYPAL_MOCK_TOKEN',
        },
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

  /// Handle Complete Order (Pay Later flow)
  Future<void> _handleCompleteOrder() async {
    if (_isProcessing) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Payment'),
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
                      _buildPaymentDetailsCard(),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                      const SizedBox(height: 24),
                      _buildPayPalButton(),
                    ] else ...[
                      _buildSubmitButton(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOrderSummaryCard() {
    final order = _orderData?['order'] as Map<String, dynamic>?;
    final orderNumber = order?['order_number'] as String? ?? 'N/A';
    double total = _amount ?? 0.0;

    String formatPrice(double? v) =>
        v != null ? '\$${v.toStringAsFixed(2)}' : '-';

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Order Number:'),
                Text(orderNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            _summaryRow('Subtotal (excl. GST)', formatPrice(_subtotalExclGst)),
            _summaryRow('Shipping', formatPrice(_shippingCost)),
            _summaryRow(
              'GST @ ${_gstRate?.toStringAsFixed(0) ?? "x"}%',
              formatPrice(_gstAmount),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Payable:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
            if (_isPayLater) ...[
              const SizedBox(height: 8),
              const Text(
                'Pending Freight Quote',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (_showFreeShippingLabel) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'This order qualifies for Free Standard Shipping',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            // Keep existing fallback for pending quote if needed
            if (_hasPendingFreightQuote && !_isPayLater) ...[
              const SizedBox(height: 8),
              const Text(
                '*Pending Freight Quote',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (_shippingCost == 0.0 && !_hasPendingFreightQuote && !_showFreeShippingLabel && !_isPayLater) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '*This order qualifies for FREE shipping',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _cardNumberController,
              decoration: const InputDecoration(labelText: 'Card Number'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cardholderNameController,
              decoration: const InputDecoration(labelText: 'Cardholder Name'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: const InputDecoration(labelText: 'CVV'),
                    obscureText: true,
                  ),
                ),
              ],
            ),
          ],
        ),
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
      child: OutlinedButton(
        onPressed: _isProcessing ? null : _handlePayPalPayment,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Pay with PayPal'),
      ),
    );
  }
}
