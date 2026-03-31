import 'package:flutter/material.dart';
import '../../../services/navigation_service.dart';

class CartFeedbackOverlay {
  static void showSuccess(BuildContext context) {
    // Show a modern, premium BottomSheet for better "WOW" factor
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon with animation container
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              // Message text
              const Text(
                'Item successfully added to your cart!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151D51),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Action Buttons
              Row(
                children: [
                  // Continue Shopping Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF151D51)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue Shopping',
                        style: TextStyle(
                          color: Color(0xFF151D51),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Go to Cart Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Dismiss bottom sheet
                        Navigator.pop(context);
                        
                        // Pop all routes until we reach the main screen (root)
                        // This ensures the user is taken back to the navigation view
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        
                        // Switch to Cart Tab (index 2)
                        NavigationService.instance.switchToTab(2);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF151D51),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Go to Cart',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Safe area padding for bottom-notched devices
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }
}
