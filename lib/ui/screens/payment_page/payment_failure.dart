import 'package:flutter/material.dart';
import 'package:apcproject/services/storage_service.dart';
import 'package:apcproject/ui/screens/profile_page/myorder.dart';
import 'package:apcproject/main_navigation.dart';

class PaymentFailureScreen extends StatefulWidget {
  final bool isPayLater;
  final String? orderNumber;
  final String? paymentId;

  const PaymentFailureScreen({
    super.key,
    this.isPayLater = false,
    this.orderNumber,
    this.paymentId,
  });

  @override
  State<PaymentFailureScreen> createState() => _PaymentFailureScreenState();
}

class _PaymentFailureScreenState extends State<PaymentFailureScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger cart clearing immediately on initialization as per requirements
    // UNLESS it's a PayLater flow where the cart is unrelated to the order.
    if (!widget.isPayLater) {
      _clearCartData();
    } else {
      debugPrint('PaymentFailureScreen: PayLater flow detected. Cart data preserved.');
    }
  }

  Future<void> _clearCartData() async {
    // Only clear session data if we don't have an order number (meaning it truly failed early)
    // If we have an order number, the user might want to try paying again for that order.
    if (widget.orderNumber == null) {
      await StorageService.clearCartData();
      await StorageService.clearPaymentCartSnapshot();
      await StorageService.clearOrderData();
      await StorageService.clearCheckoutData();
      debugPrint('PaymentFailureScreen: Cart and session data cleared.');
    }
  }

  void _navigateToMyOrders() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(initialTabIndex: 0),
      ),
      (route) => false,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyOrdersPage()),
    );
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(initialTabIndex: 0),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _navigateToHome();
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Transaction Failed',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A365D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your payment could not be verified by our server.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                if (widget.orderNumber != null || widget.paymentId != null) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.orderNumber != null)
                          _buildDetailRow('Order Number:', '#${widget.orderNumber}'),
                        if (widget.orderNumber != null && widget.paymentId != null)
                          const Divider(height: 24),
                        if (widget.paymentId != null)
                          _buildDetailRow('Payment ID:', widget.paymentId!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please share these details with support.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],

                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _navigateToMyOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A365D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Go to My Orders',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _navigateToHome,
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
