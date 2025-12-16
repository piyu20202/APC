import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/utils/logger.dart';

class PaymentService {
  // Add this flag to switch between mock and real API
  // Change to false when backend is ready
  static const bool useMockApi = true;
  
  // Google Pay: Use mock mode (true) or real backend API (false)
  // Set to false to use CyberSource backend integration
  // Set to true to revert to mock mode if any issues occur
  static const bool useMockGooglePay = true; // Reverted to mock mode

  /// Create a payment intent for CyberSource
  /// This initializes the payment session and returns payment details
  Future<Map<String, dynamic>> createPaymentIntent({
    required String orderNumber,
    required double amount,
    String currency = 'AUD',
  }) async {
    if (useMockApi) {
      return _mockCreatePaymentIntent(orderNumber, amount, currency);
    }

    try {
      Logger.info('Creating payment intent for order: $orderNumber');
      final response = await ApiClient.post(
        endpoint: ApiEndpoints.createPaymentIntent,
        body: {
          'order_number': orderNumber,
          'amount': amount,
          'currency': currency,
        },
        contentType: 'application/json',
        requireAuth: true,
      );
      Logger.info('Payment intent created successfully');
      return response;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to create payment intent', e);
      Logger.error('Stack trace', null, stackTrace);
      rethrow;
    }
  }

  /// Process payment with CyberSource
  /// This submits the payment for processing after user confirms
  Future<Map<String, dynamic>> processPayment({
    required String orderNumber,
    required Map<String, dynamic> paymentData,
  }) async {
    if (useMockApi) {
      return _mockProcessPayment(orderNumber, paymentData);
    }

    try {
      Logger.info('Processing payment for order: $orderNumber');
      final response = await ApiClient.post(
        endpoint: ApiEndpoints.processPayment,
        body: {'order_number': orderNumber, ...paymentData},
        contentType: 'application/json',
        requireAuth: true,
      );
      Logger.info('Payment processed successfully');
      return response;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to process payment', e);
      Logger.error('Stack trace', null, stackTrace);
      rethrow;
    }
  }

  /// Verify payment status
  /// This checks the current status of a payment
  Future<Map<String, dynamic>> verifyPaymentStatus({
    required String orderNumber,
  }) async {
    if (useMockApi) {
      return _mockVerifyPaymentStatus(orderNumber);
    }

    try {
      Logger.info('Verifying payment status for order: $orderNumber');
      final response = await ApiClient.get(
        endpoint:
            '${ApiEndpoints.verifyPaymentStatus}?order_number=$orderNumber',
        requireAuth: true,
      );
      Logger.info('Payment status verified');
      return response;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to verify payment status', e);
      Logger.error('Stack trace', null, stackTrace);
      rethrow;
    }
  }

  // ============ MOCK METHODS (For Testing) ============
  //
  // VALID TEST CARD NUMBERS (All will work for successful payment):
  // - 4111111111111111 (Visa)
  // - 4242424242424242 (Visa)
  // - 5555555555554444 (Mastercard)
  // - 378282246310005 (Amex)
  // - Any valid 13-19 digit number (except special test cases below)
  //
  // TEST CARD FOR ERRORS:
  // - Card ending in 0002 → Card Declined
  // - Card ending in 0069 → Expired Card
  // - Card ending in 9995 → Insufficient Funds
  // - CVV 000 → Invalid CVV
  //
  // RECOMMENDED TEST CARD (Success):
  // Card Number: 4111111111111111
  // Cardholder Name: Test User
  // Expiry: 12/25 (or any future date)
  // CVV: 123 (or any 3-4 digits except 000)

  Future<Map<String, dynamic>> _mockCreatePaymentIntent(
    String orderNumber,
    double amount,
    String currency,
  ) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    Logger.info('MOCK: Creating payment intent for order: $orderNumber');

    return {
      'success': true,
      'payment_intent_id': 'pi_mock_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'requires_payment_method',
      'message': 'Payment intent created successfully (MOCK)',
    };
  }

  Future<Map<String, dynamic>> _mockProcessPayment(
    String orderNumber,
    Map<String, dynamic> paymentData,
  ) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    Logger.info('MOCK: Processing payment for order: $orderNumber');

    // Simulate card validation
    final cardNumber = paymentData['card_number'] as String? ?? '';
    final cvv = paymentData['cvv'] as String? ?? '';

    // Remove spaces from card number for validation
    final cleanedCardNumber = cardNumber.replaceAll(' ', '');

    // Mock validation - Only reject specific test scenarios
    // For testing declined cards, use card ending in '0002'
    if (cleanedCardNumber.endsWith('0002')) {
      throw ApiException(
        message: 'Your card was declined. Please try a different card.',
        statusCode: 400,
        responseData: {
          'success': false,
          'error': 'card_declined',
          'message': 'Your card was declined. Please try a different card.',
        },
      );
    }

    // For testing invalid CVV, use CVV '000'
    if (cvv == '000') {
      throw ApiException(
        message: 'Invalid CVV. Please check your card details.',
        statusCode: 400,
        responseData: {
          'success': false,
          'error': 'invalid_cvv',
          'message': 'Invalid CVV. Please check your card details.',
        },
      );
    }

    // For testing expired card, use card ending in '0069'
    if (cleanedCardNumber.endsWith('0069')) {
      throw ApiException(
        message: 'Your card has expired. Please use a different card.',
        statusCode: 400,
        responseData: {
          'success': false,
          'error': 'expired_card',
          'message': 'Your card has expired. Please use a different card.',
        },
      );
    }

    // For testing insufficient funds, use card ending in '9995'
    if (cleanedCardNumber.endsWith('9995')) {
      throw ApiException(
        message: 'Insufficient funds. Please try a different card.',
        statusCode: 400,
        responseData: {
          'success': false,
          'error': 'insufficient_funds',
          'message': 'Insufficient funds. Please try a different card.',
        },
      );
    }

    // All other valid cards will succeed (for easy testing)
    // Basic validation - card should be 13-19 digits
    if (cleanedCardNumber.length < 13 || cleanedCardNumber.length > 19) {
      throw ApiException(
        message: 'Invalid card number. Please check and try again.',
        statusCode: 400,
        responseData: {
          'success': false,
          'error': 'invalid_card',
          'message': 'Invalid card number. Please check and try again.',
        },
      );
    }

    // Simulate successful payment
    return {
      'success': true,
      'transaction_id': 'txn_mock_${DateTime.now().millisecondsSinceEpoch}',
      'order_status': 'paid',
      'payment_status': 'completed',
      'message': 'Payment processed successfully (MOCK)',
    };
  }

  Future<Map<String, dynamic>> _mockVerifyPaymentStatus(
    String orderNumber,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    Logger.info('MOCK: Verifying payment status for order: $orderNumber');

    return {
      'success': true,
      'order_number': orderNumber,
      'payment_status': 'completed',
      'transaction_id': 'txn_mock_123456',
      'amount': 1525.00,
      'currency': 'AUD',
      'paid_at': DateTime.now().toIso8601String(),
    };
  }

  /// Process Google Pay payment
  /// Supports both mock mode (for testing) and real CyberSource backend integration
  Future<Map<String, dynamic>> processGooglePay({
    required String orderNumber,
    required double amount,
    required Map<String, dynamic> paymentResult,
  }) async {
    try {
      Logger.info('Processing Google Pay for order: $orderNumber');
      Logger.info('Payment result: ${paymentResult.toString()}');
      
      // FIRST: Convert entire paymentResult to base64 and print immediately
      debugPrint('=== STARTING BASE64 CONVERSION ===');
      try {
        final paymentResultJson = jsonEncode(paymentResult);
        final paymentResultBytes = utf8.encode(paymentResultJson);
        final paymentResultBase64 = base64Encode(paymentResultBytes);
        
        debugPrint('============token =========');
        debugPrint(paymentResultBase64);
        debugPrint('============token =========');
        
        // Force print multiple times to ensure visibility
        print('============token =========');
        print(paymentResultBase64);
        print('============token =========');
        
        Logger.info('============token =========');
        Logger.info(paymentResultBase64);
        Logger.info('============token =========');
      } catch (e) {
        debugPrint('Error encoding paymentResult to base64: $e');
        print('Error encoding paymentResult to base64: $e');
      }
      debugPrint('=== BASE64 CONVERSION COMPLETE ===');
      
      // Debug: Print payment result structure
      debugPrint('=== PAYMENT RESULT STRUCTURE ===');
      debugPrint('Payment result keys: ${paymentResult.keys.toList()}');
      debugPrint('Full payment result: $paymentResult');
      
      // Extract payment token - handle different Google Pay response formats
      String? token;
      
      // Method 1: Standard format
      final paymentMethodData = paymentResult['paymentMethodData'] as Map<String, dynamic>?;
      if (paymentMethodData != null) {
        final tokenizationData = paymentMethodData['tokenizationData'] as Map<String, dynamic>?;
        if (tokenizationData != null) {
          // Token can be a string or JSON string
          final tokenValue = tokenizationData['token'];
          if (tokenValue is String) {
            token = tokenValue;
          } else if (tokenValue != null) {
            token = tokenValue.toString();
          }
        }
      }
      
      // Method 2: Direct token in paymentResult
      if (token == null || token.isEmpty) {
        token = paymentResult['token'] as String?;
      }
      
      // Method 3: Check if token is in nested structure
      if (token == null || token.isEmpty) {
        final nestedToken = paymentResult['paymentMethodData']?['tokenizationData']?['token'] as String?;
        if (nestedToken != null) {
          token = nestedToken;
        }
      }
      
      // Debug: Check token before base64 conversion
      debugPrint('=== TOKEN EXTRACTION CHECK ===');
      debugPrint('Token is null: ${token == null}');
      debugPrint('Token is empty: ${token?.isEmpty ?? true}');
      if (token != null) {
        debugPrint('Token length: ${token.length}');
        debugPrint('Token type: ${token.runtimeType}');
      }
      
      // Convert token to base64 and print with clear delimiters
      if (token != null && token.isNotEmpty) {
        try {
          // If token is already a JSON string, use it directly
          // Otherwise, if it's a Map, convert to JSON string first
          String tokenString = token;
          
          // Try to parse as JSON to check if it's valid JSON string
          try {
            jsonDecode(token); // Validate it's valid JSON
            // If successful, token is already a JSON string, use as is
          } catch (e) {
            // If not valid JSON, might be plain string, use as is
          }
          
          // Convert token string to base64
          final bytes = utf8.encode(tokenString);
          final base64Token = base64Encode(bytes);
          
          // Print with clear delimiters for easy identification
          debugPrint('============token =========');
          debugPrint(base64Token);
          debugPrint('============token =========');
          
          // Also log using Logger
          Logger.info('============token =========');
          Logger.info(base64Token);
          Logger.info('============token =========');
        } catch (e) {
          debugPrint('Error encoding token to base64: $e');
          Logger.error('Error encoding token to base64', e);
        }
      } else {
        debugPrint('Token is null or empty, skipping base64 conversion');
        Logger.info('Token is null or empty, skipping base64 conversion');
      }
      
      // Debug: Print full payment result structure
      debugPrint('=== GOOGLE PAY TOKEN EXTRACTION ===');
      debugPrint('Payment result keys: ${paymentResult.keys}');
      debugPrint('Payment method data: $paymentMethodData');
      debugPrint('Token extracted: ${token != null ? "Yes" : "No"}');
      if (token != null) {
        debugPrint('Token length: ${token.length}');
        debugPrint('Token preview: ${token.length > 50 ? token.substring(0, 50) + "..." : token}');
        Logger.info('Google Pay Token: $token');
      } else {
        debugPrint('Full payment result: $paymentResult');
        Logger.info('Google Pay Token received: No');
      }

      // ============ MOCK MODE (Backup - Set useMockGooglePay = true to use this) ============
      if (useMockGooglePay) {
        // Simulate API delay
        await Future.delayed(const Duration(seconds: 2));
        
        // For testing: Return mock success response
        Logger.info('Using MOCK mode for Google Pay (useMockGooglePay = true)');
        
        // If token was extracted, convert to base64 and print before returning
        if (token != null && token.isNotEmpty) {
          try {
            final bytes = utf8.encode(token);
            final base64Token = base64Encode(bytes);
            
            // Print with clear delimiters for easy identification
            debugPrint('============token =========');
            debugPrint(base64Token);
            debugPrint('============token =========');
            
            // Also log using Logger
            Logger.info('============token =========');
            Logger.info(base64Token);
            Logger.info('============token =========');
          } catch (e) {
            debugPrint('Error encoding token to base64 in MOCK mode: $e');
            Logger.error('Error encoding token to base64 in MOCK mode', e);
          }
        }
        
        return {
          'success': true,
          'transaction_id': 'gp_test_${DateTime.now().millisecondsSinceEpoch}',
          'order_status': 'paid',
          'payment_status': 'completed',
          'message': 'Google Pay processed successfully (TEST MODE)',
          'order_number': orderNumber,
          'amount': amount,
          'payment_token': token,
        };
      }

      // ============ PRODUCTION MODE (CyberSource Backend Integration) ============
      Logger.info('Using PRODUCTION mode for Google Pay (useMockGooglePay = false)');
      
      if (token == null) {
        throw ApiException(
          message: 'Invalid payment token from Google Pay',
          statusCode: 400,
        );
      }

      final response = await ApiClient.post(
        endpoint: ApiEndpoints.processGooglePay,
        body: {
          'order_number': orderNumber,
          'amount': amount,
          'payment_token': token,
          'payment_method': 'google_pay',
        },
        contentType: 'application/json',
        requireAuth: true,
      );
      
      Logger.info('Google Pay processed successfully');
      return response;
    } catch (e, stackTrace) {
      Logger.error('Failed to process Google Pay', e);
      Logger.error('Stack trace', null, stackTrace);
      rethrow;
    }
  }
}
