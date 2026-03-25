import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:apcproject/services/storage_service.dart';

class OrderPlacedPage extends StatelessWidget {
  const OrderPlacedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        title: const Text(
          'Order Placed',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 60.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Company Logo - same as login/signup screen
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.4,
                    maxHeight: MediaQuery.of(context).size.height * 0.15,
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.image, size: 80, color: Colors.grey);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Success Checkbox
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),

              // Order Details (commented out in original code)
              /*
              Container( ... )
              */

              // Thank You Message
              const Text(
                'Thank you for your order!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              FutureBuilder<Map<String, dynamic>?>(
                future: StorageService.getOrderData(),
                builder: (context, snapshot) {
                  String invoiceNumber = '';
                  if (snapshot.hasData && snapshot.data != null) {
                    final order = snapshot.data!['order'] as Map<String, dynamic>?;
                    invoiceNumber = order?['order_number'] as String? ?? '';
                  }
                  
                  if (invoiceNumber.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Text(
                    'Invoice Number: #$invoiceNumber',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  );
                },
              ),

              const SizedBox(height: 40),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Navigate to main with home tab (index 0) as initial tab
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/main',
                          (route) => false,
                          arguments: {'tabIndex': 0},
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF002e5b)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Continue Shopping',
                        style: TextStyle(
                          color: Color(0xFF002e5b),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Show toast message that feature is under development
                        Fluttertoast.showToast(
                          msg: 'Track Order is under development',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.orange,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF002e5b),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Track Order',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
