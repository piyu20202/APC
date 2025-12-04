import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/utils/logger.dart';

class PaymentService {
  // Add this flag to switch between mock and real API
  // Change to false when backend is ready
  static const bool useMockApi = true;

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
}
