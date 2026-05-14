import 'package:flutter/material.dart';
import 'package:apcproject/services/storage_service.dart';
import 'package:apcproject/ui/screens/profile_page/myorder.dart';
import 'package:apcproject/main_navigation.dart';

class PaymentFailureScreen extends StatefulWidget {
  final bool isPayLater;
  const PaymentFailureScreen({super.key, this.isPayLater = false});

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
    await StorageService.clearCartData();
    await StorageService.clearPaymentCartSnapshot();
    await StorageService.clearOrderData();
    await StorageService.clearCheckoutData();
    debugPrint('PaymentFailureScreen: Cart and session data cleared.');
  }

  void _navigateToMyOrders() {
    // 1. Reset the entire stack and make MainNavigation (Home) the root.
    // This ensures that when the user presses back from MyOrders, they go to Home.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(initialTabIndex: 0),
      ),
      (route) => false,
    );

    // 2. Push MyOrdersPage on top of the Home screen.
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
                // Error Icon
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 100,
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'Transaction Cancelled/Failed',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A365D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Subtitle
                Text(
                  'Your payment could not be completed. Please try again.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Action Button
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
                      elevation: 2,
                    ),
                    child: const Text(
                      'Go to My Orders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
