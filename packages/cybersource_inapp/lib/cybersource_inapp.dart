
import 'package:flutter/services.dart';

import 'cybersource_inapp_platform_interface.dart';

/// Simple Flutter-facing API for Cybersource In‑app SDK.
///
/// NOTE:
/// - For now this class only exposes the minimal methods we need
///   for mobile-side tokenisation:
///     1) [getCaptureContext]  – will later come from backend, currently dummy.
///     2) [tokenizeCard]       – will later call the native Cybersource SDK,
///        currently returns a dummy transient token for wiring up the flow.
class CybersourceInapp {
  static const MethodChannel _channel = MethodChannel('cybersource_inapp');

  /// Get the platform version.
  Future<String?> getPlatformVersion() {
    return CybersourceInappPlatform.instance.getPlatformVersion();
  }

  /// Get capture context for Cybersource tokenisation.
  ///
  /// In the final integration this should come from the backend via the
  /// native SDK / REST call. For now we just return a dummy value from the
  /// platform side so the Flutter flow can be wired and tested.
  static Future<String> getCaptureContext() async {
    final result = await _channel.invokeMethod<String>('getCaptureContext');
    if (result == null || result.isEmpty) {
      throw PlatformException(
        code: 'NO_CAPTURE_CONTEXT',
        message: 'Failed to obtain capture context from platform code',
      );
    }
    return result;
  }

  /// Tokenise card data into a Cybersource transient token.
  ///
  /// This method will eventually call the native Cybersource In‑app SDK.
  /// Currently the Android/iOS implementations return a dummy token so that
  /// the mobile checkout flow can be exercised end‑to‑end without backend
  /// changes.
  static Future<String> tokenizeCard({
    required String captureContext,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    String? cardholderName,
  }) async {
    final args = <String, dynamic>{
      'captureContext': captureContext,
      'cardNumber': cardNumber,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cvv': cvv,
      if (cardholderName != null) 'cardholderName': cardholderName,
    };

    final token = await _channel.invokeMethod<String>('tokenizeCard', args);
    if (token == null || token.isEmpty) {
      throw PlatformException(
        code: 'TOKENIZATION_FAILED',
        message: 'Failed to tokenize card on platform side',
      );
    }
    return token;
  }
}

