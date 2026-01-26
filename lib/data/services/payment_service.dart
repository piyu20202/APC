import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/utils/logger.dart';
import '../../services/storage_service.dart';

class PaymentService {
  // Add this flag to switch between mock and real API
  // Change to false when backend is ready
  static const bool useMockApi = true;

  // Google Pay: Use mock mode (true) or real backend API (false)
  // Set to false to use CyberSource backend integration
  // Set to true to revert to mock mode if any issues occur
  static const bool useMockGooglePay = true; // Reverted to mock mode

  // Google Pay token API (CyberSource): keep OFF until backend endpoint is ready
  // When backend is ready:
  // - set useMockGooglePay = false
  // - set enableGooglePayTokenApi = true
  static const bool enableGooglePayTokenApi = false;

  // Card payment API (raw card fields)
  static const bool enableCardPaymentApi = true;

  // Apple Pay: Use mock mode (true) or real backend API (false)
  // Set to false to use CyberSource backend integration
  static const bool useMockApplePay = true; // Set to false when backend is ready

  // PayPal: Use mock mode (true) or real backend API (false)
  // Set to false when backend PayPal endpoint is ready
  static const bool useMockPayPal = true; // Set to false when backend is ready

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

  /// Process card payment by sending raw card details to backend (JSON body)
  /// NOTE: This is feature-flagged and should remain disabled until backend is ready.
  Future<Map<String, dynamic>> processCardPaymentRaw({
    required int orderId,
    required String orderNumber,
    required double amount,
    required String currency,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required String cardholderName,
  }) async {
    if (!enableCardPaymentApi) {
      throw ApiException(
        message: 'Card payment API not enabled',
        statusCode: 400,
      );
    }

    if (ApiEndpoints.cybersourceCardPayment == '/__TODO_CARD_PAYMENT_URL__') {
      throw ApiException(
        message: 'Card payment endpoint not configured',
        statusCode: 400,
      );
    }

    try {
      // Get user email
      final user = await StorageService.getUserData();
      final email = user?.email;
      if (email == null || email.isEmpty) {
        throw ApiException(message: 'User email not found', statusCode: 400);
      }

      Logger.info('Processing card payment (raw) for order ID: $orderId, order number: $orderNumber');
      final response = await ApiClient.post(
        endpoint: ApiEndpoints.cybersourceCardPayment,
        body: {
          'number': cardNumber,
          'expirationMonth': expiryMonth,
          'expirationYear': expiryYear,
          'securityCode': cvv,
          'cardholderName': cardholderName,
          'orderid': orderId, // Send integer order ID, not order number string
          'email': email,
        },
        contentType: 'application/json',
        requireAuth: true,
      );

      // Validate response format for success case
      // Expected: { 'order': {...}, 'process_payment': 0, 'show_order_success': 1 }
      if (response['order'] != null) {
        final order = response['order'] as Map<String, dynamic>?;
        if (order != null) {
          // Ensure required fields are present
          final requiredFields = [
            'id',
            'user_id',
            'pay_amount',
            'payment_status',
            'order_number',
          ];
          for (final field in requiredFields) {
            if (!order.containsKey(field)) {
              Logger.warning('Missing field in order response: $field');
            }
          }
        }

        // Save updated order data to storage
        await StorageService.saveOrderData(response);
        Logger.info('Order data updated after payment');
      }

      Logger.info('Card payment (raw) processed');
      return response;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Failed to process card payment (raw)', e);
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
      // Extract payment token - handle different Google Pay response formats
      String? token;

      // Method 1: Standard format
      final paymentMethodData =
          paymentResult['paymentMethodData'] as Map<String, dynamic>?;
      if (paymentMethodData != null) {
        final tokenizationData =
            paymentMethodData['tokenizationData'] as Map<String, dynamic>?;
        if (tokenizationData != null) {
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
        final nestedToken =
            paymentResult['paymentMethodData']?['tokenizationData']?['token']
                as String?;
        if (nestedToken != null) {
          token = nestedToken;
        }
      }

      // ===== ONLY TWO PRINTS (with chunking for long tokens) =====
      if (token != null && token.isNotEmpty) {
        _printLongString(token, 'GOOGLE_PAY_TOKEN_RAW');

        final base64Token = base64Encode(utf8.encode(token));
        _printLongString(base64Token, 'GOOGLE_PAY_TOKEN_BASE64');
      } else {
        debugPrint('=== GOOGLE_PAY_TOKEN_RAW ===');
        debugPrint('null');
        debugPrint('=== GOOGLE_PAY_TOKEN_BASE64 ===');
        debugPrint('null');
      }

      // ============ MOCK MODE ============
      if (useMockGooglePay) {
        await Future.delayed(const Duration(seconds: 2));

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

      // ============ PRODUCTION MODE ============
      if (token == null) {
        throw ApiException(
          message: 'Invalid payment token from Google Pay',
          statusCode: 400,
        );
      }

      // Backend requires base64 encoded token for /user/payment/cybersource/googlepay/token
      final tokenBase64 = base64Encode(utf8.encode(token));

      final Map<String, dynamic> response;

      // New endpoint (feature-flagged)
      if (enableGooglePayTokenApi) {
        final user = await StorageService.getUserData();
        final email = user?.email;
        if (email == null || email.isEmpty) {
          throw ApiException(message: 'User email not found', statusCode: 400);
        }

        response = await ApiClient.post(
          endpoint: ApiEndpoints.googlePayToken,
          body: {
            'token': tokenBase64,
            'orderid': orderNumber, // using order_number as orderid
            'email': email,
          },
          contentType: 'application/json',
          requireAuth: true,
        );
      } else {
        // Existing (older) backend integration kept for compatibility
        response = await ApiClient.post(
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
      }

      // Validate response format for success case
      // Expected: { 'order': {...}, 'process_payment': 0, 'show_order_success': 1 }
      if (response['order'] != null) {
        final order = response['order'] as Map<String, dynamic>?;
        if (order != null) {
          // Ensure required fields are present
          final requiredFields = [
            'id',
            'user_id',
            'pay_amount',
            'payment_status',
            'order_number',
          ];
          for (final field in requiredFields) {
            if (!order.containsKey(field)) {
              Logger.warning('Missing field in order response: $field');
            }
          }
        }

        // Save updated order data to storage
        await StorageService.saveOrderData(response);
        Logger.info('Order data updated after Google Pay payment');
      }

      // UI expects 'payment_token' key (used by checkout flow); keep it available.
      return {...response, 'payment_token': token};
    } catch (e, stackTrace) {
      Logger.error('Failed to process Google Pay', e);
      Logger.error('Stack trace', null, stackTrace);
      rethrow;
    }
  }

  /// Process Apple Pay payment
  /// Supports both mock mode (for testing) and real CyberSource backend integration
  Future<Map<String, dynamic>> processApplePay({
    required String orderNumber,
    required double amount,
    required Map<String, dynamic> paymentResult,
  }) async {
    try {
      // Extract payment token from Apple Pay response
      String? token;

      // Apple Pay returns token in paymentData structure
      final paymentData = paymentResult['paymentData'] as Map<String, dynamic>?;
      if (paymentData != null) {
        // Apple Pay token is a JSON object that needs to be encoded
        final tokenData = paymentData['token'] as Map<String, dynamic>?;
        if (tokenData != null) {
          // Convert token to JSON string
          token = jsonEncode(tokenData);
        } else {
          // Fallback: check if token is already a string
          token = paymentData['token'] as String?;
        }
      }

      // Method 2: Direct token in paymentResult
      if (token == null || token.isEmpty) {
        token = paymentResult['token'] as String?;
      }

      // Print token for debugging (with chunking for long tokens)
      if (token != null && token.isNotEmpty) {
        _printLongString(token, 'APPLE_PAY_TOKEN_RAW');

        final base64Token = base64Encode(utf8.encode(token));
        _printLongString(base64Token, 'APPLE_PAY_TOKEN_BASE64');
      } else {
        debugPrint('=== APPLE_PAY_TOKEN_RAW ===');
        debugPrint('null');
        debugPrint('=== APPLE_PAY_TOKEN_BASE64 ===');
        debugPrint('null');
      }

      // ============ MOCK MODE (for testing without backend) ============
      if (useMockApplePay) {
        await Future.delayed(const Duration(seconds: 2));

        return {
          'success': true,
          'transaction_id': 'ap_test_${DateTime.now().millisecondsSinceEpoch}',
          'order_status': 'paid',
          'payment_status': 'completed',
          'message': 'Apple Pay processed successfully (TEST MODE)',
          'order_number': orderNumber,
          'amount': amount,
          'payment_token': token,
        };
      }

      // ============ PRODUCTION MODE ============
      if (token == null || token.isEmpty) {
        throw ApiException(
          message: 'Invalid payment token from Apple Pay',
          statusCode: 400,
        );
      }

      // Backend requires base64 encoded token
      final tokenBase64 = base64Encode(utf8.encode(token));

      // Get user email
      final user = await StorageService.getUserData();
      final email = user?.email;
      if (email == null || email.isEmpty) {
        throw ApiException(message: 'User email not found', statusCode: 400);
      }

      Logger.info('Processing Apple Pay for order: $orderNumber');

      final response = await ApiClient.post(
        endpoint: ApiEndpoints.applePayToken,
        body: {
          'token': tokenBase64,
          'orderid': orderNumber,
          'email': email,
        },
        contentType: 'application/json',
        requireAuth: true,
      );

      // Validate response format for success case
      // Expected: { 'order': {...}, 'process_payment': 0, 'show_order_success': 1 }
      if (response['order'] != null) {
        final order = response['order'] as Map<String, dynamic>?;
        if (order != null) {
          // Ensure required fields are present
          final requiredFields = [
            'id',
            'user_id',
            'pay_amount',
            'payment_status',
            'order_number',
          ];
          for (final field in requiredFields) {
            if (!order.containsKey(field)) {
              Logger.warning('Missing field in order response: $field');
            }
          }
        }

        // Save updated order data to storage
        await StorageService.saveOrderData(response);
        Logger.info('Order data updated after Apple Pay payment');
      }

      // UI expects 'payment_token' key (used by checkout flow)
      return {...response, 'payment_token': token};
    } catch (e, stackTrace) {
      Logger.error('Failed to process Apple Pay', e);
      Logger.error('Stack trace', null, stackTrace);
      rethrow;
    }
  }

  /// Process PayPal payment
  /// Supports both mock mode (for testing) and real backend integration
  /// Similar to Google Pay - extracts token from paymentResult and sends to backend
  Future<Map<String, dynamic>> processPayPal({
    required String orderNumber,
    required int orderId,
    required double amount,
    required String currency,
    Map<String, dynamic>? paymentResult,
  }) async {
    try {
      // Extract payment token from PayPal payment result (similar to Google Pay)
      String? token;

      if (paymentResult != null) {
        // Method 1: PayPal order ID (most common)
        token = paymentResult['orderID'] as String?;
        
        // Method 2: PayPal payment ID
        if (token == null || token.isEmpty) {
          token = paymentResult['paymentID'] as String?;
        }
        
        // Method 3: Direct token in paymentResult
        if (token == null || token.isEmpty) {
          token = paymentResult['token'] as String?;
        }
        
        // Method 4: Check nested structure
        if (token == null || token.isEmpty) {
          final details = paymentResult['details'] as Map<String, dynamic>?;
          if (details != null) {
            token = details['orderID'] as String? ?? details['paymentID'] as String?;
          }
        }
      }

      // ===== Print token for debugging (with chunking for long tokens) =====
      if (token != null && token.isNotEmpty) {
        _printLongString(token, 'PAYPAL_TOKEN_RAW');

        final base64Token = base64Encode(utf8.encode(token));
        _printLongString(base64Token, 'PAYPAL_TOKEN_BASE64');
      } else {
        debugPrint('=== PAYPAL_TOKEN_RAW ===');
        debugPrint('null');
        debugPrint('=== PAYPAL_TOKEN_BASE64 ===');
        debugPrint('null');
      }

      // ============ MOCK MODE (for testing without backend) ============
      if (useMockPayPal) {
        await Future.delayed(const Duration(seconds: 2));

        Logger.info('MOCK: Processing PayPal payment for order: $orderNumber');

        return {
          'success': true,
          'transaction_id': 'pp_test_${DateTime.now().millisecondsSinceEpoch}',
          'order_status': 'paid',
          'payment_status': 'completed',
          'message': 'PayPal payment processed successfully (TEST MODE)',
          'order_number': orderNumber,
          'amount': amount,
          'payment_token': token ?? 'mock_paypal_token',
        };
      }

      // ============ PRODUCTION MODE ============
      // Get user email
      final user = await StorageService.getUserData();
      final email = user?.email;
      if (email == null || email.isEmpty) {
        throw ApiException(message: 'User email not found', statusCode: 400);
      }

      Logger.info('Processing PayPal payment for order: $orderNumber');

      // Prepare request body
      final requestBody = {
        'orderid': orderId,
        'order_number': orderNumber,
        'amount': amount,
        'currency': currency,
        'email': email,
      };

      // Add payment token - REQUIRED for PayPal (like Google Pay)
      if (token != null && token.isNotEmpty) {
        requestBody['payment_token'] = token;
      } else {
        // Token is required for PayPal payment processing
        throw ApiException(
          message: 'Invalid payment token from PayPal',
          statusCode: 400,
        );
      }

      final response = await ApiClient.post(
        endpoint: ApiEndpoints.processPayPal,
        body: requestBody,
        contentType: 'application/json',
        requireAuth: true,
      );

      // Validate response format for success case
      // Expected: { 'order': {...}, 'process_payment': 0, 'show_order_success': 1 }
      if (response['order'] != null) {
        final order = response['order'] as Map<String, dynamic>?;
        if (order != null) {
          // Ensure required fields are present
          final requiredFields = [
            'id',
            'user_id',
            'pay_amount',
            'payment_status',
            'order_number',
          ];
          for (final field in requiredFields) {
            if (!order.containsKey(field)) {
              Logger.warning('Missing field in order response: $field');
            }
          }
        }

        // Save updated order data to storage
        await StorageService.saveOrderData(response);
        Logger.info('Order data updated after PayPal payment');
      }

      // UI expects 'payment_token' key (used by checkout flow)
      // In production mode token is guaranteed non-null (we throw above if invalid).
      // In mock mode, token may be null, so provide empty string fallback.
      final String safeToken = token ?? '';
      return {...response, 'payment_token': safeToken};
    } catch (e, stackTrace) {
      Logger.error('Failed to process PayPal payment', e);
      Logger.error('Stack trace', null, stackTrace);
      rethrow;
    }
  }
}
