import 'package:flutter/material.dart';
import 'package:apcproject/services/storage_service.dart';
import 'package:apcproject/data/services/payment_service.dart';
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
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, dynamic>? _orderData;
  String? _orderNumber;
  int? _orderId;
  double? _amount;
  String? _currency;

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
          // Don't pop immediately, show error and let user see it
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      debugPrint('Order data keys: ${orderData.keys.join(", ")}');
      setState(() {
        _orderData = orderData;
      });

      // Extract order details from API response
      // Response structure: { "order": { "order_number": "...", "pay_amount": 100 }, ... }
      final order = orderData['order'] as Map<String, dynamic>?;
      debugPrint('Order object: ${order != null ? "Found" : "Not found"}');

      if (order != null) {
        debugPrint('Order keys: ${order.keys.join(", ")}');
      }

      final orderNumber = order?['order_number'] as String?;
      final orderId = order?['id'] as int?;
      debugPrint('Order number: $orderNumber');
      debugPrint('Order ID: $orderId');

      // Use 'pay_amount' instead of 'total' based on API response
      // Try multiple possible field names
      final payAmount = order?['pay_amount'] as num?;
      final totalAmount = order?['total'] as num?;
      final amount = (payAmount ?? totalAmount)?.toDouble() ?? 0.0;

      debugPrint(
        'Pay amount: $payAmount, Total: $totalAmount, Final amount: $amount',
      );

      if (orderNumber == null || orderNumber.isEmpty) {
        debugPrint('ERROR: Order number is null or empty');
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Invalid order number. Please try again.',
            toastLength: Toast.LENGTH_LONG,
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      if (orderId == null) {
        debugPrint('ERROR: Order ID is null');
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Invalid order ID. Please try again.',
            toastLength: Toast.LENGTH_LONG,
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Validate amount - allow 0 for now, just log warning
      if (amount <= 0) {
        debugPrint('WARNING: Payment amount is 0 or negative: $amount');
        // Don't block navigation, just show warning
      }

      setState(() {
        _orderNumber = orderNumber;
        _orderId = orderId;
        _amount = amount > 0 ? amount : 0.0;
        _currency = 'AUD';
      });

      debugPrint(
        'Creating payment intent for order: $orderNumber, amount: ${amount > 0 ? amount : 0.0}',
      );

      // Create payment intent (even if amount is 0, for testing)
      try {
        await _paymentService.createPaymentIntent(
          orderNumber: orderNumber,
          amount: amount > 0 ? amount : 0.0,
          currency: 'AUD',
        );
        debugPrint('Payment intent created successfully');
      } catch (e) {
        debugPrint('Error creating payment intent: $e');
        // Don't block the UI, just log the error
      }

      setState(() {
        _isLoading = false;
      });

      debugPrint('=== PAYMENT PAGE INITIALIZATION COMPLETE ===');
    } on ApiException catch (e) {
      if (mounted) {
        if (e.statusCode == 401) {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          await authProvider.logout();
          if (!mounted) return;
          Fluttertoast.showToast(
            msg: 'Session expired. Please login again.',
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/signin',
            (route) => false,
          );
        } else {
          Fluttertoast.showToast(
            msg: e.message,
            toastLength: Toast.LENGTH_LONG,
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to initialize payment. Please try again.',
          toastLength: Toast.LENGTH_LONG,
        );
        Navigator.pop(context);
      }
      debugPrint('Error initializing payment: $e');
    }
  }

  /// Handle payment submission
  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate() || _isProcessing) {
      return;
    }

    if (_orderNumber == null || _amount == null) {
      Fluttertoast.showToast(
        msg: 'Payment data is incomplete. Please try again.',
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Format card number (remove spaces)
      final cardNumber = _cardNumberController.text.replaceAll(' ', '');

      // Format expiry date (MM/YY)
      final expiryParts = _expiryController.text.split('/');
      if (expiryParts.length != 2) {
        throw Exception('Invalid expiry date format');
      }

      final expiryMonth = expiryParts[0].padLeft(2, '0');
      final expiryYear = '20${expiryParts[1]}'; // Convert YY to YYYY

      // If backend card-payment API is enabled, send raw JSON body to server.
      // Otherwise, keep existing (tokenize-only) test flow.
      if (PaymentService.enableCardPaymentApi) {
        if (_orderId == null || _orderNumber == null) {
          throw Exception(
            'Order ID and Order Number are required for card payment',
          );
        }
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

        // Check response format: { 'order': {...}, 'process_payment': 0, 'show_order_success': 1 }
        final showOrderSuccess = response['show_order_success'] as int? ?? 0;
        final processPayment = response['process_payment'] as int? ?? 1;

        debugPrint(
          'Card Payment Response - show_order_success: $showOrderSuccess, process_payment: $processPayment',
        );

        // If we reach here, API call was successful (status code 200)
        // Clear cart data ONLY after successful payment
        await StorageService.clearCartData();

        // Show success toast and navigate forward
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Payment successful!',
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );

          // Navigate to order success page if show_order_success is 1
          if (showOrderSuccess == 1) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/order-placed',
              (route) => false,
              arguments: {'payment_method': 'Card'},
            );
          } else {
            // Fallback: still navigate to order-placed if flag is not set
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/order-placed',
              (route) => false,
              arguments: {'payment_method': 'Card'},
            );
          }
        }
        return;
      }

      // === Cybersource transient token flow (mobile side) ===
      // Get (dummy) capture context from the plugin – this will later come
      // from backend / Cybersource, but for now enables end‑to‑end testing.
      final captureContext = await CybersourceInapp.getCaptureContext();

      final token = await CybersourceInapp.tokenizeCard(
        captureContext: captureContext,
        cardNumber: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvv: _cvvController.text,
        cardholderName: _cardholderNameController.text,
      );

      debugPrint('Cybersource transient token: $token');

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Card token: $token',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Navigate to order success page and display the token,
        // similar to Google Pay token handling.
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

      // NOTE: The previous backend `processPayment` call is intentionally
      // skipped here for now so that the UI flow can be validated first.
      // Once the backend is ready to accept transient tokens, the token
      // can be sent to the server from this method.
    } on ApiException catch (e) {
      // Handle API exceptions - check status code
      debugPrint(
        'Card payment API error: ${e.message}, Status: ${e.statusCode}',
      );

      if (mounted) {
        if (e.statusCode == 401) {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          await authProvider.logout();
          if (!mounted) return;
          Fluttertoast.showToast(
            msg: 'Session expired. Please login again.',
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/signin',
            (route) => false,
          );
        } else if (e.statusCode == 403) {
          // Handle 403 Forbidden - Payment not successful
          // Show API response message in toast
          final errorMessage = e.message.isNotEmpty
              ? e.message
              : 'Payment is not successful, please try again later.';
          Fluttertoast.showToast(
            msg: errorMessage,
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          // User stays on the same page (no navigation)
        } else if (e.statusCode == 200) {
          // If status code is 200, clear cart and show success
          // Clear cart data ONLY after successful payment
          await StorageService.clearCartData();
          if (!mounted) return;

          Fluttertoast.showToast(
            msg: 'Payment successful!',
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );

          // Navigate to order success page
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/order-placed',
            (route) => false,
            arguments: {'payment_method': 'Card'},
          );
        } else {
          // Status code is not 200/401/403 - show error toast and stay on page
          // Use API message if available, otherwise show generic message
          final errorMessage = e.message.isNotEmpty
              ? e.message
              : 'Something went wrong. Please try again.';
          Fluttertoast.showToast(
            msg: errorMessage,
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          // User stays on the same page (no navigation)
        }
      }

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      // Handle other exceptions
      debugPrint('Error processing card payment: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Something went wrong Please try again',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        // User stays on the same page (no navigation)
      }

      setState(() {
        _isProcessing = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Format card number with spaces
  String _formatCardNumber(String value) {
    final cleaned = value.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: true, // Fix keyboard visibility
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        title: const Text(
          'Payment',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom +
                        16.0, // Add keyboard padding
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Order Summary Card
                        _buildOrderSummaryCard(),
                        const SizedBox(height: 24),

                        // Payment Details Card
                        _buildPaymentDetailsCard(),
                        const SizedBox(height: 24),

                        // Security Notice
                        _buildSecurityNotice(),
                        const SizedBox(height: 24),

                        // Divider with "OR" text
                        _buildDivider(),
                        const SizedBox(height: 24),

                        // PayPal Payment Button
                        _buildPayPalButton(),
                        const SizedBox(height: 24),

                        // Submit Payment Button
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildOrderSummaryCard() {
    final order = _orderData?['order'] as Map<String, dynamic>?;
    final orderNumber = order?['order_number'] as String? ?? 'N/A';
    // Use pay_amount/total from order, fallback to _amount
    double total = 0.0;
    final dynamic payAmountRaw = order?['pay_amount'];
    final dynamic totalRaw = order?['total'];

    if (payAmountRaw is num) {
      total = payAmountRaw.toDouble();
    } else if (totalRaw is num) {
      total = totalRaw.toDouble();
    } else if (_amount != null) {
      total = _amount!;
    }

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
                const Text('Order Number:', style: TextStyle(fontSize: 14)),
                Text(
                  orderNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
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
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Card Number
            TextFormField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
              maxLength: 19, // 16 digits + 3 spaces
              onChanged: (value) {
                final formatted = _formatCardNumber(value);
                if (formatted != value) {
                  _cardNumberController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(
                      offset: formatted.length,
                    ),
                  );
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter card number';
                }
                final cleaned = value.replaceAll(' ', '');
                if (cleaned.length < 13 || cleaned.length > 19) {
                  return 'Invalid card number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Cardholder Name
            TextFormField(
              controller: _cardholderNameController,
              decoration: const InputDecoration(
                labelText: 'Cardholder Name',
                hintText: 'John Doe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter cardholder name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Expiry and CVV Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: const InputDecoration(
                      labelText: 'Expiry (MM/YY)',
                      hintText: '12/25',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    onChanged: (value) {
                      if (value.length == 2 && !value.contains('/')) {
                        _expiryController.value = TextEditingValue(
                          text: '$value/',
                          selection: TextSelection.collapsed(offset: 3),
                        );
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final parts = value.split('/');
                      if (parts.length != 2) {
                        return 'Invalid format';
                      }
                      final month = int.tryParse(parts[0]);
                      final year = int.tryParse(parts[1]);
                      if (month == null ||
                          year == null ||
                          month < 1 ||
                          month > 12) {
                        return 'Invalid date';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (value.length < 3) {
                        return 'Invalid CVV';
                      }
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

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.lock, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your payment information is encrypted and secure.',
              style: TextStyle(color: Colors.blue[900], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildPayPalButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isProcessing ? null : _handlePayPalPayment,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0070BA), // PayPal blue
          side: const BorderSide(color: Color(0xFF0070BA), width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Pay with',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0070BA),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PayPal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle PayPal payment using flutter_paypal SDK
  Future<void> _handlePayPalPayment() async {
    if (_isProcessing) {
      return;
    }

    if (_orderNumber == null || _orderId == null || _amount == null) {
      Fluttertoast.showToast(
        msg: 'Payment data is incomplete. Please try again.',
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    // Load PayPal credentials from config (sandbox or production based on mode)
    final String paypalMode = _paypalConfig?['mode'] as String? ?? 'sandbox';
    final bool isSandbox = paypalMode != 'production';
    String paypalClientId = isSandbox
        ? (_paypalConfig?['sandbox_client_id'] as String? ??
              _paypalConfig?['client_id'] as String? ??
              '')
        : (_paypalConfig?['production_client_id'] as String? ??
              _paypalConfig?['client_id'] as String? ??
              '');
    String paypalSecretKey = isSandbox
        ? (_paypalConfig?['sandbox_secret_key'] as String? ??
              _paypalConfig?['secret_key'] as String? ??
              '')
        : (_paypalConfig?['production_secret_key'] as String? ??
              _paypalConfig?['secret_key'] as String? ??
              '');

    // For testing: If credentials not configured, use mock/test mode
    if (paypalClientId.isEmpty || paypalSecretKey.isEmpty) {
      debugPrint('PayPal Client ID/Secret not configured. Using test mode.');

      // For testing: Use mock PayPal flow (no real SDK call)
      setState(() {
        _isProcessing = true;
      });

      try {
        // Simulate PayPal payment with test token (for testing only)
        final testToken =
            'PP_TEST_ORDER_${DateTime.now().millisecondsSinceEpoch}';

        final response = await _paymentService.processPayPal(
          orderNumber: _orderNumber!,
          orderId: _orderId!,
          amount: _amount!,
          currency: _currency ?? 'AUD',
          paymentResult: {
            'orderID': testToken, // Test token for console logging
          },
        );

        // Log token for debugging
        final paymentToken = response['payment_token'] as String?;
        debugPrint('=== PAYPAL PAYMENT TOKEN (TEST MODE) ===');
        debugPrint('Token: $paymentToken');
        debugPrint('Token Length: ${paymentToken?.length ?? 0}');
        debugPrint('=== END PAYPAL TOKEN ===');

        final showOrderSuccess = response['show_order_success'] as int? ?? 0;
        final processPayment = response['process_payment'] as int? ?? 1;

        debugPrint(
          'PayPal Payment Response - show_order_success: $showOrderSuccess, process_payment: $processPayment',
        );

        // Clear cart after successful payment
        await StorageService.clearCartData();

        if (mounted) {
          Fluttertoast.showToast(
            msg: 'PayPal payment successful! (Test Mode)',
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/order-placed',
            (route) => false,
            arguments: {'payment_method': 'PayPal'},
          );
        }
      } catch (e) {
        debugPrint('Error in PayPal test mode: $e');
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'PayPal test payment failed. Please try again.',
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
      return; // Exit early - using test mode
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Navigate to PayPal checkout page (WebView-based)
      if (!mounted) return;

      final amount = _amount!;
      final amountString = amount.toStringAsFixed(2);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => UsePaypal(
            sandboxMode: isSandbox,
            clientId: paypalClientId,
            secretKey: paypalSecretKey,
            returnURL: "https://samplesite.com/return",
            cancelURL: "https://samplesite.com/cancel",
            transactions: [
              {
                "amount": {
                  "total": amountString,
                  "currency": _currency ?? "AUD",
                  "details": {"subtotal": amountString, "shipping": "0"},
                },
              },
            ],
            note: "Order #${_orderNumber}",
            onSuccess: (Map params) async {
              debugPrint('PayPal onSuccess: $params');

              // Extract orderID/token from PayPal response
              String? paypalOrderId;
              try {
                final response = params["response"] as Map<String, dynamic>?;
                if (response != null) {
                  paypalOrderId = response["id"] as String?;
                }
              } catch (e) {
                debugPrint('Error extracting PayPal orderID: $e');
              }

              // Fallback: try other possible keys
              if (paypalOrderId == null || paypalOrderId.isEmpty) {
                paypalOrderId = params["id"] as String?;
              }
              if (paypalOrderId == null || paypalOrderId.isEmpty) {
                paypalOrderId = params["orderID"] as String?;
              }
              if (paypalOrderId == null || paypalOrderId.isEmpty) {
                paypalOrderId = params["token"] as String?;
              }

              debugPrint('PayPal OrderID/Token extracted: $paypalOrderId');

              if (paypalOrderId == null || paypalOrderId.isEmpty) {
                if (mounted) {
                  Fluttertoast.showToast(
                    msg:
                        'Failed to get PayPal payment token. Please try again.',
                    toastLength: Toast.LENGTH_LONG,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                  Navigator.pop(context); // Close PayPal page
                }
                return;
              }

              // Process PayPal payment through backend with token (Google Pay style)
              try {
                final response = await _paymentService.processPayPal(
                  orderNumber: _orderNumber!,
                  orderId: _orderId!,
                  amount: amount,
                  currency: _currency ?? 'AUD',
                  paymentResult: {
                    'orderID': paypalOrderId, // Real PayPal orderID token
                  },
                );

                // Log token for debugging
                final paymentToken = response['payment_token'] as String?;
                debugPrint('=== PAYPAL PAYMENT TOKEN ===');
                debugPrint('Token: $paymentToken');
                debugPrint('Token Length: ${paymentToken?.length ?? 0}');
                debugPrint('=== END PAYPAL TOKEN ===');

                final showOrderSuccess =
                    response['show_order_success'] as int? ?? 0;
                final processPayment = response['process_payment'] as int? ?? 1;

                debugPrint(
                  'PayPal Payment Response - show_order_success: $showOrderSuccess, process_payment: $processPayment',
                );

                // Close PayPal page first
                if (mounted) {
                  Navigator.pop(context);
                }

                // Clear cart after successful payment
                await StorageService.clearCartData();

                if (mounted) {
                  Fluttertoast.showToast(
                    msg: 'PayPal payment successful!',
                    toastLength: Toast.LENGTH_LONG,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                  );

                  // Navigate to order success page
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/order-placed',
                    (route) => false,
                    arguments: {'payment_method': 'PayPal'},
                  );
                }
              } on ApiException catch (e) {
                debugPrint(
                  'PayPal payment API error: ${e.message}, Status: ${e.statusCode}',
                );

                if (mounted) {
                  Navigator.pop(context); // Close PayPal page

                  if (e.statusCode == 401) {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    await authProvider.logout();
                    if (!mounted) return;
                    Fluttertoast.showToast(
                      msg: 'Session expired. Please login again.',
                      toastLength: Toast.LENGTH_LONG,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                    );
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/signin',
                      (route) => false,
                    );
                  } else {
                    final errorMessage = e.message.isNotEmpty
                        ? e.message
                        : 'PayPal payment failed. Please try again.';
                    Fluttertoast.showToast(
                      msg: errorMessage,
                      toastLength: Toast.LENGTH_LONG,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                    );
                  }
                }
              } catch (e) {
                debugPrint('Error processing PayPal payment: $e');
                if (mounted) {
                  Navigator.pop(context); // Close PayPal page
                  Fluttertoast.showToast(
                    msg: 'Something went wrong. Please try again',
                    toastLength: Toast.LENGTH_LONG,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isProcessing = false;
                  });
                }
              }
            },
            onError: (error) {
              debugPrint('PayPal onError: $error');
              if (mounted) {
                Navigator.pop(context); // Close PayPal page
                Fluttertoast.showToast(
                  msg: 'PayPal payment error: $error',
                  toastLength: Toast.LENGTH_LONG,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
                setState(() {
                  _isProcessing = false;
                });
              }
            },
            onCancel: (params) {
              debugPrint('PayPal onCancel: $params');
              if (mounted) {
                Navigator.pop(context); // Close PayPal page
                Fluttertoast.showToast(
                  msg: 'PayPal payment cancelled',
                  toastLength: Toast.LENGTH_SHORT,
                );
                setState(() {
                  _isProcessing = false;
                });
              }
            },
          ),
        ),
      );

      // Reset processing flag when PayPal page is closed (user navigates back)
      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('Error starting PayPal checkout: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to start PayPal payment. Please try again.',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }

      setState(() {
        _isProcessing = false;
      });
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _handlePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF002e5b),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'PAY NOW',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
