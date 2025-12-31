import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:apcproject/services/storage_service.dart';
import 'package:apcproject/data/services/order_service.dart';
import 'package:apcproject/data/services/cart_service.dart';
import 'package:apcproject/data/models/user_model.dart';
import 'package:apcproject/core/exceptions/api_exception.dart';
import 'package:apcproject/providers/auth_provider.dart';
import 'package:apcproject/data/services/payment_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pay/pay.dart';
import 'package:flutter/services.dart';
import 'package:apcproject/config/environment.dart';

class OrderPriceDetailPage extends StatefulWidget {
  const OrderPriceDetailPage({super.key});

  @override
  State<OrderPriceDetailPage> createState() => _OrderPriceDetailPageState();
}

class _OrderPriceDetailPageState extends State<OrderPriceDetailPage> {
  final OrderService _orderService = OrderService();
  final CartService _cartService = CartService();
  final PaymentService _paymentService = PaymentService();
  bool _isSubmitting = false;
  String? _couponCode;
  double _couponDiscount = 0.0;
  final TextEditingController _couponController = TextEditingController();
  String _selectedPaymentMethod = 'Credit Card'; // Default selection

  // Cart totals
  double? _subtotalExclGst;
  double? _shippingCost;
  double? _totalExclGst;
  double? _gstAmount;
  double? _totalInclGst;
  double? _totalPayable;
  bool _hasPendingFreightQuote = false;

  // Google Pay variables
  Pay? _payClient;
  PaymentConfiguration? _googlePayConfig;
  bool _isGooglePayAvailable = false;
  bool _isInitializingGooglePay = true;
  StreamSubscription? _paymentResultSubscription;
  bool _isPaymentProcessing =
      false; // Flag to prevent duplicate payment processing
  bool _hasNavigatedAway =
      false; // Flag to track if we've navigated away after successful payment

  /// Helper function to print long strings in chunks (to avoid truncation)
  void _printLongString(String text, String label) {
    debugPrint('=== $label (Length: ${text.length}) ===');
    const int chunkSize = 800; // Print in chunks of 800 chars
    for (int i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      debugPrint(text.substring(i, end));
    }
    debugPrint('=== END $label ===');
  }

  /// Safely convert API values (which may be num or String with commas) to double
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      // Remove thousand separators like "10,616.73"
      final normalized = value.replaceAll(',', '');
      return double.tryParse(normalized);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadCartTotals();
    _initializeGooglePay(); // Initialize Google Pay
    // Add listener to enable/disable apply button based on input length
    _couponController.addListener(_onCouponTextChanged);
  }

  void _onCouponTextChanged() {
    // Trigger rebuild when text changes to update button state
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _couponController.removeListener(_onCouponTextChanged);
    _couponController.dispose();
    _paymentResultSubscription?.cancel();
    super.dispose();
  }

  /// Load cart totals from storage
  Future<void> _loadCartTotals() async {
    try {
      final cartResponse = await StorageService.getCartData();
      if (cartResponse != null) {
        // Use totals returned by cart/update API
        final totalPrice = _toDouble(cartResponse['totalPrice']);
        final taxAmount = _toDouble(cartResponse['tax']);
        final totalWithGst = _toDouble(cartResponse['total_with_gst']);

        // Shipping may be num or string
        final shippingCost = _toDouble(cartResponse['shipping']);

        // Freight quote flag: show only if > 0
        final showRequestFreight =
            (cartResponse['show_request_freight_cost'] as num?)?.toDouble() ??
            0;
        final hasPendingFreight = showRequestFreight > 0;

        if (totalPrice != null) {
          final totalExclGst = totalPrice + (shippingCost ?? 0.0);
          final gstAmount =
              taxAmount ??
              (totalWithGst != null ? totalWithGst - totalExclGst : null);

          setState(() {
            _subtotalExclGst = totalPrice;
            _shippingCost = shippingCost;
            _totalExclGst = totalExclGst;
            _gstAmount = gstAmount;
            _totalInclGst =
                totalWithGst ??
                (totalPrice + (shippingCost ?? 0.0) + (gstAmount ?? 0.0));
            _totalPayable = _totalInclGst;
            _hasPendingFreightQuote = hasPendingFreight;
          });
        } else {
          // If totals are not available, keep values null
          setState(() {
            _totalPayable = null;
            _subtotalExclGst = null;
            _shippingCost = null;
            _totalExclGst = null;
            _gstAmount = null;
            _totalInclGst = null;
            _hasPendingFreightQuote = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading cart totals: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        title: const Text(
          'Checkout-Payment',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price Details Section
              _buildPriceDetailsSection(),
              const SizedBox(height: 24),

              // Order Summary Section
              //_buildOrderSummarySection(),
              //const SizedBox(height: 24),

              // Payment Method Section
              _buildPaymentMethodSection(),
              const SizedBox(height: 32),

              // Proceed to Payment Button
              _buildProceedButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceDetailsSection() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PRICE DETAILS Header
            const Text(
              'PRICE DETAILS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF151D51),
              ),
            ),
            const SizedBox(height: 16),

            // Total Of Items (excl. GST)
            _buildPriceRow(
              'Total Of Items (excl. GST)',
              _subtotalExclGst != null
                  ? '\$${_subtotalExclGst!.toStringAsFixed(2)}'
                  : '-',
            ),
            const SizedBox(height: 4),

            // Shipping Cost (excl. GST) - in red
            _buildPriceRow(
              '*Shipping Cost (excl. GST)',
              _shippingCost != null
                  ? '\$${_shippingCost!.toStringAsFixed(2)}'
                  : '-',
              isRed: true,
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Total without GST
            _buildPriceRow(
              'Total without GST',
              _totalExclGst != null
                  ? '\$${_totalExclGst!.toStringAsFixed(2)}'
                  : '-',
            ),
            const SizedBox(height: 4),

            // GST @ 10%
            _buildPriceRow(
              'GST @ 10%',
              _gstAmount != null ? '\$${_gstAmount!.toStringAsFixed(2)}' : '-',
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Total (incl. GST)
            _buildPriceRow(
              'Total (incl. GST)',
              _totalInclGst != null
                  ? '\$${_totalInclGst!.toStringAsFixed(2)}'
                  : '-',
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Promo Code Section
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _couponController,
                      decoration: InputDecoration(
                        hintText: 'Enter promo code',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (context) {
                    final textLength = _couponController.text.trim().length;
                    final isEnabled = !_isSubmitting && textLength > 3;

                    return ElevatedButton(
                      onPressed: isEnabled ? _applyPromoCode : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEnabled
                            ? const Color(0xFF151D51)
                            : Colors.grey[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(80, 40),
                        disabledBackgroundColor: Colors.grey[400],
                        disabledForegroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
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
                ],
              ),
            ],
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

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
                  _totalPayable != null
                      ? '\$${_totalPayable!.toStringAsFixed(2)}'
                      : '-',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),

            // Pending Freight Quote (in red) - only show if API indicates freight quote is pending
            if (_hasPendingFreightQuote) ...[
              const SizedBox(height: 4),
              const Text(
                '*Pending Freight Quote',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            // Shipping notice (only show if shipping is free)
            if (_shippingCost == 0.0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: const Text(
                  '*This order qualifies for FREE Standard shipping',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
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

            // Payment options - now clickable
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = 'Credit Card';
                });
              },
              child: _buildPaymentOption(
                'Credit Card',
                Icons.credit_card,
                _selectedPaymentMethod == 'Credit Card',
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = 'PayPal';
                });
              },
              child: _buildPaymentOption(
                'PayPal',
                Icons.payment,
                _selectedPaymentMethod == 'PayPal',
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = 'Afterpay';
                });
              },
              child: _buildPaymentOption(
                'Afterpay',
                Icons.account_balance,
                _selectedPaymentMethod == 'Afterpay',
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = 'Zip Pay';
                });
              },
              child: _buildPaymentOption(
                'Zip Pay',
                Icons.money,
                _selectedPaymentMethod == 'Zip Pay',
              ),
            ),
            const SizedBox(height: 12),
            // Google Pay Option (always show; enable only when available)
            GestureDetector(
              onTap: () {
                // Only select Google Pay, don't trigger payment yet
                // Payment will be triggered when user presses "Proceed Payment" button
                setState(() {
                  _selectedPaymentMethod = 'Google Pay';
                });
              },
              child: _buildPaymentOption(
                'Google Pay',
                Icons.account_balance_wallet,
                _selectedPaymentMethod == 'Google Pay',
                isEnabled: !_isInitializingGooglePay && _isGooglePayAvailable,
                trailing: _isInitializingGooglePay
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isRed ? Colors.red : const Color(0xFF151D51),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              color: isRed ? Colors.red : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String title,
    IconData icon,
    bool isSelected, {
    bool isEnabled = true,
    Widget? trailing,
  }) {
    final baseTextColor = isEnabled ? Colors.black : Colors.grey[600];
    final selectedColor = const Color(0xFF002e5b);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? selectedColor : baseTextColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (trailing != null) trailing,
            if (isSelected)
              Icon(Icons.check_circle, color: selectedColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProceedButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleProceedToPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF002e5b),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'PROCEED TO PAYMENT',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  /// Handle order placement and payment gateway integration when proceed to payment button is clicked
  Future<void> _handleProceedToPayment() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get user data (must be logged in)
      final userData = await StorageService.getUserData();
      if (userData == null) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Please login to continue',
            toastLength: Toast.LENGTH_SHORT,
          );
          Navigator.pop(context);
        }
        return;
      }

      // Get cart data
      final cartResponse = await StorageService.getCartData();
      if (cartResponse == null || cartResponse['cart'] == null) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Cart is empty',
            toastLength: Toast.LENGTH_SHORT,
          );
        }
        return;
      }

      // Get checkout form data
      final checkoutData = await StorageService.getCheckoutData();
      if (checkoutData == null) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Please complete checkout form',
            toastLength: Toast.LENGTH_SHORT,
          );
          Navigator.pop(context);
        }
        return;
      }

      // Build order payload
      final orderPayload = await _buildOrderPayload(
        userData: userData,
        cartResponse: cartResponse,
        checkoutData: checkoutData,
      );

      // Add selected payment method to payload
      orderPayload['payment_method'] = _selectedPaymentMethod;

      // Log POST body with proper formatting
      final prettyPayload = const JsonEncoder.withIndent(
        '  ',
      ).convert(orderPayload);
      debugPrint('************checkout post body start************');
      debugPrint(prettyPayload);
      debugPrint('*************checkout post body end***********');

      // Call API to place order BEFORE payment gateway
      final response = await _orderService.storeOrder(orderPayload);

      // Save order response for later (payment gateway, order success page, etc.)
      await StorageService.saveOrderData(response);

      // Log API response with proper formatting
      final prettyResponse = const JsonEncoder.withIndent(
        '  ',
      ).convert(response);
      debugPrint('----------api response start------------');
      debugPrint(prettyResponse);
      debugPrint('-----------api reponse end-------------');

      // Check if order was successfully placed with order_number
      final order = response['order'] as Map<String, dynamic>?;
      final orderNumber = order?['order_number'] as String?;

      if (orderNumber == null || orderNumber.isEmpty) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Failed to place order. Please try again.',
            toastLength: Toast.LENGTH_LONG,
          );
        }
        return;
      }

      // DO NOT clear cart here - cart will be cleared only after successful payment
      // Cart will be cleared in payment.dart (card payment) or here (Google Pay) after payment success

      if (mounted) {
        // Show success toast
        Fluttertoast.showToast(
          msg: 'Order placed successfully!',
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Debug logging before navigation
        debugPrint('=== NAVIGATION DEBUG ===');
        debugPrint('Selected Payment Method: "$_selectedPaymentMethod"');
        debugPrint('Process Payment Flag: ${response['process_payment']}');
        debugPrint('Order Number: $orderNumber');
        debugPrint('Order Response keys: ${response.keys.join(", ")}');

        // Verify order data is saved
        final savedOrderData = await StorageService.getOrderData();
        debugPrint(
          'Order data saved: ${savedOrderData != null ? "Yes" : "No"}',
        );
        if (savedOrderData != null) {
          debugPrint(
            'Saved order data keys: ${savedOrderData.keys.join(", ")}',
          );
        }

        // Route to appropriate payment flow based on selected payment method
        // Credit Card should always go to payment page
        if (_selectedPaymentMethod == 'Credit Card') {
          debugPrint('Credit Card selected - Navigating to payment page');
          // Clear checkout data after successful order (but keep order data)
          await StorageService.clearCheckoutData();
          debugPrint('Checkout data cleared, navigating to payment page...');
          if (mounted) {
            Navigator.pushNamed(context, '/payment');
          }
          return;
        }

        // For Google Pay - trigger payment when proceed button is pressed
        if (_selectedPaymentMethod == 'Google Pay') {
          debugPrint('Google Pay selected - handling from proceed button');

          if (_isInitializingGooglePay) {
            Fluttertoast.showToast(
              msg: 'Checking Google Pay availability...',
              toastLength: Toast.LENGTH_SHORT,
            );
            return;
          }

          if (!_isGooglePayAvailable) {
            Fluttertoast.showToast(
              msg:
                  'Google Pay is not available on this device/emulator (requires Google Play services).',
              toastLength: Toast.LENGTH_LONG,
            );
            return;
          }

          // Attempt Google Pay flow if available
          await StorageService.clearCheckoutData();
          await _handleGooglePayClick();
          return;
        }

        // For other payment methods
        if (_selectedPaymentMethod == 'PayPal' ||
            _selectedPaymentMethod == 'Afterpay' ||
            _selectedPaymentMethod == 'Zip Pay') {
          debugPrint(
            '$_selectedPaymentMethod selected - Navigating to payment page',
          );
          await StorageService.clearCheckoutData();
          if (!mounted) return;
          Navigator.pushNamed(
            context,
            '/payment',
            arguments: {'payment_method': _selectedPaymentMethod},
          );
          return;
        }

        // Fallback: Check process_payment flag from order response
        debugPrint('Default case - checking process_payment flag');
        final processPayment = response['process_payment'] as int? ?? 0;
        await StorageService.clearCheckoutData();
        if (!mounted) return;
        if (processPayment == 1) {
          debugPrint('Process payment = 1, navigating to payment page');
          Navigator.pushNamed(context, '/payment');
        } else {
          debugPrint('Process payment = 0, navigating to order-placed page');
          Navigator.pushNamed(context, '/order-placed');
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        // Check if it's an unauthorized error (401)
        if (e.statusCode == 401) {
          // Logout user and clear auth data
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          await authProvider.logout();
          if (!mounted) return;

          // Show error message
          Fluttertoast.showToast(
            msg: 'Session expired. Please login again.',
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );

          // Navigate to login screen and clear navigation stack
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/signin',
            (route) => false,
          );
        } else {
          // Show error message for other API errors
          Fluttertoast.showToast(
            msg: e.message,
            toastLength: Toast.LENGTH_LONG,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to place order. Please try again.',
          toastLength: Toast.LENGTH_LONG,
        );
      }
      debugPrint('Error placing order: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _buildOrderPayload({
    required UserModel userData,
    required Map<String, dynamic> cartResponse,
    required Map<String, dynamic> checkoutData,
  }) async {
    // Extract cart data
    final cart = cartResponse['cart'] as Map<String, dynamic>? ?? {};

    // Determine shipping method
    final shippingMethod =
        checkoutData['shipping_method'] as String? ?? 'Ship to Address';
    final shipping = shippingMethod == 'Pickup' ? 'pickup' : 'shipto';

    // Map pickup location to ID
    dynamic pickupLocationId = '';
    if (shipping == 'pickup') {
      final pickupLocation = checkoutData['pickup_location'] as String?;
      if (pickupLocation == '53 Cochranes Road, Moorabbin, VIC 3189') {
        pickupLocationId = 1; // Adjust based on your actual IDs
      } else if (pickupLocation ==
          'Unit 2, 2 Commercial Dr, Shailer Park QLD 4128') {
        pickupLocationId = 2;
      }
    }

    // Build payload
    final payload = <String, dynamic>{
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

      // Shipping address (empty if same as billing)
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

      // Billing address
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
      'address1': '', // Address line 2 (optional)
      'city': checkoutData['suburb'] as String? ?? userData.city ?? '',
      'state': checkoutData['state'] as String? ?? userData.state ?? '',
      'country': 'AU', // Fixed
      'zip': checkoutData['post_code'] as String? ?? userData.zip ?? '',
    };

    return payload;
  }

  Future<void> _applyPromoCode() async {
    final code = _couponController.text.trim();

    if (code.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter a promo code',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Read existing cart – this is what must remain if coupon fails
      final cartResponse = await StorageService.getCartData();
      if (cartResponse == null || cartResponse['cart'] == null) {
        Fluttertoast.showToast(
          msg: 'Cart is empty',
          toastLength: Toast.LENGTH_SHORT,
        );
        return;
      }

      final oldCart = cartResponse['cart'] as Map<String, dynamic>;

      final payload = <String, dynamic>{'old_cart': oldCart, 'code': code};

      // 200 responses come here; non‑2xx go to on ApiException
      final response = await _cartService.applyCoupon(payload);

      final updatedCart = response['cart'] as Map<String, dynamic>?;
      if (updatedCart == null) {
        // Treat as logical failure, but do not change existing totals
        Fluttertoast.showToast(
          msg: 'Unable to apply promo code. Please try again.',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      // Optional: compute discount
      final oldTotal = (cartResponse['totalPrice'] as num?)?.toDouble();
      final newTotal = (response['totalPrice'] as num?)?.toDouble();
      final discount = (oldTotal != null && newTotal != null)
          ? (oldTotal - newTotal)
          : 0.0;

      // Persist new cart + refresh totals shown on card
      await StorageService.saveCartData(response);
      await _loadCartTotals();

      if (mounted) {
        setState(() {
          _couponCode = code;
          _couponDiscount = discount > 0 ? discount : 0.0;
        });
      }

      // Use server success message if present
      final successMsg =
          (response['message'] as String?) ??
          'Promo code "$code" applied successfully';

      Fluttertoast.showToast(
        msg: successMsg,
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } on ApiException catch (e) {
      // 403 and other non‑2xx: keep old totals, show backend message
      Fluttertoast.showToast(
        msg: e.message,
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to apply promo code. Please try again.',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      } else {
        _isSubmitting = false;
      }
    }
  }

  /// Initialize Google Pay
  Future<void> _initializeGooglePay() async {
    try {
      setState(() {
        _isInitializingGooglePay = true;
      });

      // Load Google Pay configuration
      _googlePayConfig = await PaymentConfiguration.fromAsset(
        BuildConfig.googlePayConfigAsset,
      );

      // Initialize Pay client
      _payClient = Pay({PayProvider.google_pay: _googlePayConfig!});

      // Check if Google Pay is available
      _isGooglePayAvailable = await _payClient!.userCanPay(
        PayProvider.google_pay,
      );

      // Setup payment result listener for Android
      _setupPaymentResultListener();

      debugPrint('Google Pay initialized. Available: $_isGooglePayAvailable');

      setState(() {
        _isInitializingGooglePay = false;
      });
    } catch (e) {
      debugPrint('Error initializing Google Pay: $e');
      _isGooglePayAvailable = false;
      _isInitializingGooglePay = false;
      setState(() {});
    }
  }

  /// Setup payment result listener for Android
  void _setupPaymentResultListener() {
    const eventChannel = EventChannel('plugins.flutter.io/pay/payment_result');
    _paymentResultSubscription = eventChannel
        .receiveBroadcastStream()
        .map((result) => jsonDecode(result as String) as Map<String, dynamic>)
        .listen(
          (result) {
            debugPrint('Google Pay result received: $result');
            _handleGooglePayResult(result);
          },
          onError: (error) {
            debugPrint('Google Pay result error: $error');
            if (mounted) {
              setState(() {
                _isSubmitting = false;
              });
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

  /// Handle Google Pay payment result
  Future<void> _handleGooglePayResult(
    Map<String, dynamic> paymentResult,
  ) async {
    // Prevent duplicate processing
    if (_isPaymentProcessing || _hasNavigatedAway) {
      debugPrint(
        'Google Pay payment already being processed or navigated away, ignoring duplicate event',
      );
      return;
    }

    // Check if widget is still mounted and on the correct page
    if (!mounted) {
      debugPrint('Widget not mounted, ignoring Google Pay result');
      return;
    }

    try {
      _isPaymentProcessing = true;
      setState(() {
        _isSubmitting = true;
      });

      // First, place the order if not already placed
      final orderData = await StorageService.getOrderData();
      String? orderNumber;
      double amount = _totalPayable ?? 0.0;

      if (orderData == null) {
        // Order not placed yet, need to place order first
        final userData = await StorageService.getUserData();
        if (userData == null) {
          throw Exception('User not logged in');
        }

        final cartResponse = await StorageService.getCartData();
        if (cartResponse == null || cartResponse['cart'] == null) {
          throw Exception('Cart is empty');
        }

        final checkoutData = await StorageService.getCheckoutData();
        if (checkoutData == null) {
          throw Exception('Checkout data not found');
        }

        final orderPayload = await _buildOrderPayload(
          userData: userData,
          cartResponse: cartResponse,
          checkoutData: checkoutData,
        );

        orderPayload['payment_method'] = 'Google Pay';

        final response = await _orderService.storeOrder(orderPayload);
        await StorageService.saveOrderData(response);
        // DO NOT clear cart here - cart will be cleared only after successful payment
        await StorageService.clearCheckoutData();

        final order = response['order'] as Map<String, dynamic>?;
        orderNumber = order?['order_number'] as String?;
        amount =
            (_toDouble(order?['pay_amount']) ??
            _toDouble(order?['total']) ??
            amount);
      } else {
        final order = orderData['order'] as Map<String, dynamic>?;
        orderNumber = order?['order_number'] as String?;
        amount =
            (_toDouble(order?['pay_amount']) ??
            _toDouble(order?['total']) ??
            amount);
      }

      if (orderNumber == null) {
        throw Exception('Order number not found');
      }

      debugPrint(
        'Processing Google Pay for order: $orderNumber, amount: $amount',
      );

      // Process Google Pay payment
      final response = await _paymentService.processGooglePay(
        orderNumber: orderNumber,
        amount: amount,
        paymentResult: paymentResult,
      );

      final paymentToken = response['payment_token'] as String?;

      // ===== ONLY TWO PRINTS (with chunking for long tokens) =====
      if (paymentToken != null && paymentToken.isNotEmpty) {
        _printLongString(paymentToken, 'GOOGLE_PAY_TOKEN_RAW');

        final base64Token = base64Encode(utf8.encode(paymentToken));
        _printLongString(base64Token, 'GOOGLE_PAY_TOKEN_BASE64');
      } else {
        debugPrint('=== GOOGLE_PAY_TOKEN_RAW ===');
        debugPrint('null');
        debugPrint('=== GOOGLE_PAY_TOKEN_BASE64 ===');
        debugPrint('null');
      }

      // Check response format: { 'order': {...}, 'process_payment': 0, 'show_order_success': 1 }
      final showOrderSuccess = response['show_order_success'] as int? ?? 0;
      final processPayment = response['process_payment'] as int? ?? 1;

      debugPrint(
        'Google Pay Response - show_order_success: $showOrderSuccess, process_payment: $processPayment',
      );

      // If we reach here, API call was successful (status code 200)
      // Clear cart data ONLY after successful payment
      await StorageService.clearCartData();

      // Cancel payment result subscription to prevent duplicate processing
      _paymentResultSubscription?.cancel();
      _paymentResultSubscription = null;

      // Show success toast and navigate forward
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Payment successful!',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Mark that we're navigating away BEFORE navigation to prevent duplicate processing
        _hasNavigatedAway = true;

        // Navigate to order success page if show_order_success is 1
        if (showOrderSuccess == 1) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/order-placed',
            (route) => false,
            arguments: {
              'payment_token': paymentToken, // Pass token as argument
              'payment_method': 'Google Pay',
            },
          );
        } else {
          // Fallback: still navigate to order-placed if flag is not set
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
      } else {
        // If widget is not mounted, reset flags
        _isPaymentProcessing = false;
        _hasNavigatedAway = false;
      }
    } on ApiException catch (e) {
      // Handle API exceptions - check status code
      debugPrint('Google Pay API error: ${e.message}, Status: ${e.statusCode}');

      if (mounted) {
        // If status code is 200, show success and navigate
        if (e.statusCode == 200) {
          // Clear cart data ONLY after successful payment
          await StorageService.clearCartData();

          // Cancel payment result subscription to prevent duplicate processing
          _paymentResultSubscription?.cancel();
          _paymentResultSubscription = null;

          if (!mounted) {
            _isPaymentProcessing = false;
            _hasNavigatedAway = false;
            return;
          }

          Fluttertoast.showToast(
            msg: 'Payment successful!',
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );

          // Mark that we're navigating away BEFORE navigation to prevent duplicate processing
          _hasNavigatedAway = true;

          // Navigate to order success page
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/order-placed',
            (route) => false,
            arguments: {'payment_method': 'Google Pay'},
          );
        } else {
          // Status code is not 200 - show error toast and stay on page
          Fluttertoast.showToast(
            msg: 'Something went wrong Please try again',
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          // User stays on the same page (no navigation)
          // Reset flag so user can try again
          _isPaymentProcessing = false;
        }
      }
    } catch (e) {
      // Handle other exceptions
      debugPrint('Error handling Google Pay result: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Something went wrong Please try again',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        // User stays on the same page (no navigation)
        // Reset flag so user can try again
        _isPaymentProcessing = false;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      } else {
        // If widget is disposed, reset the flag
        _isPaymentProcessing = false;
      }
    }
  }

  /// Handle Google Pay option click
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

    // Prevent multiple simultaneous payment attempts
    if (_isPaymentProcessing) {
      debugPrint('Google Pay payment already in progress, ignoring click');
      Fluttertoast.showToast(
        msg: 'Payment is already being processed. Please wait...',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    // If we've already navigated away, don't allow new payment
    if (_hasNavigatedAway) {
      debugPrint('Already navigated away, cannot start new payment');
      return;
    }

    try {
      final amount = _totalPayable ?? 0.0;

      final paymentItems = [
        PaymentItem(
          label: 'Total',
          amount: amount.toStringAsFixed(2),
          status: PaymentItemStatus.final_price,
        ),
      ];

      // Don't set _isPaymentProcessing here - it will be set when result is received
      // This allows the first payment result to be processed

      // For Android, use showPaymentSelector (result comes via event channel)
      if (Theme.of(context).platform == TargetPlatform.android) {
        await _payClient!.showPaymentSelector(
          PayProvider.google_pay,
          paymentItems,
        );
      } else {
        // For iOS, result comes directly
        final result = await _payClient!.showPaymentSelector(
          PayProvider.google_pay,
          paymentItems,
        );
        _handleGooglePayResult(result);
      }
    } catch (e) {
      debugPrint('Google Pay error: $e');
      // Reset flag on error so user can try again
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
}
