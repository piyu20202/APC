import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NetworkChecker {
  /// Check if device has internet connection
  static Future<bool> hasConnection() async {
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Network check failed: $e');
      }
      return false;
    }
  }
}
