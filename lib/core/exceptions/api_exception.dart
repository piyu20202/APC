import 'package:flutter/foundation.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic responseData;

  ApiException({required this.message, this.statusCode, this.responseData});

  @override
  String toString() {
    if (kDebugMode) {
      return 'ApiException: $message (Status: $statusCode)';
    }
    return message;
  }
}
