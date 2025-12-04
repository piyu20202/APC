import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:apcproject/services/storage_service.dart';
import 'package:apcproject/data/services/order_service.dart';
import 'package:apcproject/data/models/user_model.dart';
import 'package:apcproject/core/exceptions/api_exception.dart';
import 'package:apcproject/providers/auth_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class OrderPriceDetailPage extends StatefulWidget {
  const OrderPriceDetailPage({super.key});

  @override
  State<OrderPriceDetailPage> createState() => _OrderPriceDetailPageState();
}

class _OrderPriceDetailPageState extends State<OrderPriceDetailPage> {
  final OrderService _orderService = OrderService();
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

  @override
  void initState() {
    super.initState();
    _loadCartTotals();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  /// Load cart totals from storage
  Future<void> _loadCartTotals() async {
    try {
      final cartResponse = await StorageService.getCartData();
      if (cartResponse != null) {
        // Get total from cart (GST Incl) - this is the totalPayable
        final totalPrice = (cartResponse['totalPrice'] as num?)?.toDouble() ?? 0.0;

        setState(() {
          _totalPayable = totalPrice;
          // If breakdown not available in cart response, keep others null
          // This way only Total Payable Amount will show
        });
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
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Only show rows if data is available
            if (_subtotalExclGst != null)
              _buildPriceRow(
                'Total Of Items (excl. GST)',
                '\$${_subtotalExclGst!.toStringAsFixed(2)}',
              ),
            if (_shippingCost != null)
              _buildPriceRow(
                'Shipping Cost (excl. GST)',
                '\$${_shippingCost!.toStringAsFixed(2)}',
              ),
            if (_totalExclGst != null)
              _buildPriceRow(
                'Total without GST',
                '\$${_totalExclGst!.toStringAsFixed(2)}',
              ),
            if (_gstAmount != null)
              _buildPriceRow(
                'GST @ 10%',
                '\$${_gstAmount!.toStringAsFixed(2)}',
              ),
            if (_totalInclGst != null)
              _buildPriceRow(
                'Total (incl. GST)',
                '\$${_totalInclGst!.toStringAsFixed(2)}',
              ),

            const SizedBox(height: 16),

            InkWell(
              onTap: () {
                // Handle promo code
                _showPromoCodeDialog();
              },
              child: Row(
                children: [
                  const Icon(Icons.tag, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _couponCode != null && _couponCode!.isNotEmpty
                        ? 'Promo Code: $_couponCode'
                        : 'Have a promo code?',
                    style: TextStyle(
                      color: _couponCode != null && _couponCode!.isNotEmpty
                          ? Colors.green
                          : Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Total Payable Amount (always show)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Payable Amount:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _totalPayable != null
                      ? '\$${_totalPayable!.toStringAsFixed(2)}'
                      : '\$0.00',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),

            // Shipping notice (only show if shipping is free or null)
            if (_shippingCost == 0.0 || _shippingCost == null) ...[
              const SizedBox(height: 16),
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

  Widget _buildOrderSummarySection() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ORDER SUMMARY',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Sample order items
            _buildOrderItem(
              'Telescopic Linear Actuator - Heavy Duty',
              'APC-TLA-HD',
              '\$13',
              '1',
            ),
            _buildOrderItem(
              'Robust Cast Alloy Casing Kit',
              'APC-RCAK-001',
              '\$74',
              '2',
            ),
            _buildOrderItem('Farm Gate Opener Kit', 'APC-FGO-001', '\$59', '1'),
            _buildOrderItem('Gas Automation Kit', 'APC-GAK-001', '\$89', '3'),
            _buildOrderItem(
              'Gate & Fencing Hardware',
              'APC-GFH-001',
              '\$45',
              '2',
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                const Text('\$1,386.36', style: TextStyle(fontSize: 16)),
              ],
            ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(amount)],
      ),
    );
  }

  Widget _buildOrderItem(
    String name,
    String sku,
    String price,
    String quantity,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'SKU: $sku',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text('Qty: $quantity', style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 1,
            child: Text(
              price,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF002e5b).withOpacity(0.1)
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
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF002e5b) : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          if (isSelected)
            Icon(Icons.check_circle, color: const Color(0xFF002e5b), size: 20),
        ],
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

      // Clear cart data after successful order placement
      await StorageService.clearCartData();

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
        debugPrint('Order data saved: ${savedOrderData != null ? "Yes" : "No"}');
        if (savedOrderData != null) {
          debugPrint('Saved order data keys: ${savedOrderData.keys.join(", ")}');
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

        // For other payment methods
        if (_selectedPaymentMethod == 'PayPal' ||
            _selectedPaymentMethod == 'Afterpay' ||
            _selectedPaymentMethod == 'Zip Pay') {
          debugPrint('${_selectedPaymentMethod} selected - Navigating to payment page');
          await StorageService.clearCheckoutData();
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

  void _showPromoCodeDialog() {
    _couponController.clear();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Promo Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _couponController,
                decoration: const InputDecoration(
                  labelText: 'Enter Promo Code',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _couponCode = _couponController.text.trim();
                  // TODO: Calculate coupon discount by calling coupon API
                  _couponDiscount = 0.0;
                });
                Navigator.of(dialogContext).pop();
                if (_couponCode != null && _couponCode!.isNotEmpty) {
                  Fluttertoast.showToast(
                    msg: 'Promo code applied: $_couponCode',
                    toastLength: Toast.LENGTH_SHORT,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002e5b),
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}
