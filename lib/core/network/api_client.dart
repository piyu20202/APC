import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../exceptions/api_exception.dart';
import 'api_endpoints.dart';
import '../../services/storage_service.dart';

class ApiClient {
  static const Duration _timeout = Duration(seconds: 30);

  /// Make a POST request
  static Future<Map<String, dynamic>> post({
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    String? contentType,
    bool requireAuth = false,
  }) async {
    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');

      // Default headers
      final Map<String, String> defaultHeaders = {
        'Content-Type': contentType ?? 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      };

      // Add authorization header if required
      if (requireAuth) {
        final bearerToken = await StorageService.getBearerToken();
        if (bearerToken != null) {
          defaultHeaders['Authorization'] = bearerToken;
        }
      }

      // Merge custom headers
      if (headers != null) {
        defaultHeaders.addAll(headers);
      }

      // Log request in debug mode
      debugPrint('POST Request: $url');
      debugPrint('Headers: $defaultHeaders');
      if (body != null) {
        debugPrint('Body: $body');
      }

      final response = await http
          .post(
            url,
            body: body != null
                ? (contentType == 'application/json'
                      ? jsonEncode(body)
                      : _encodeFormData(body))
                : null,
            headers: defaultHeaders,
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException(message: 'Network error: ${e.message}');
    } on Exception catch (e) {
      throw ApiException(message: 'Request failed: ${e.toString()}');
    }
  }

  /// Make a GET request
  static Future<Map<String, dynamic>> get({
    required String endpoint,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    String? contentType,
    bool requireAuth = false,
  }) async {
    try {
      Uri url;
      if (queryParameters != null && queryParameters.isNotEmpty) {
        url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint')
            .replace(queryParameters: queryParameters);
      } else {
        url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
      }

      // Default headers
      final Map<String, String> defaultHeaders = {
        'Accept': 'application/json',
      };

      // Add Content-Type if body is provided
      if (body != null) {
        defaultHeaders['Content-Type'] =
            contentType ?? 'application/json';
      }

      // Add authorization header if required
      if (requireAuth) {
        final bearerToken = await StorageService.getBearerToken();
        if (bearerToken != null) {
          defaultHeaders['Authorization'] = bearerToken;
        }
      }

      // Merge custom headers
      if (headers != null) {
        defaultHeaders.addAll(headers);
      }

      // Log request in debug mode
      debugPrint('GET Request: $url');
      debugPrint('Headers: $defaultHeaders');
      if (body != null) {
        debugPrint('Body: $body');
      }

      http.Response response;
      
      // If body is provided, use Request to send GET with body
      if (body != null) {
        final request = http.Request('GET', url);
        request.headers.addAll(defaultHeaders);
        request.body = contentType == 'application/json'
            ? jsonEncode(body)
            : _encodeFormData(body);
        
        final streamedResponse = await http.Client()
            .send(request)
            .timeout(_timeout);
        response = await http.Response.fromStream(streamedResponse);
      } else {
        response = await http
            .get(url, headers: defaultHeaders)
            .timeout(_timeout);
      }

      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException(message: 'Network error: ${e.message}');
    } on Exception catch (e) {
      throw ApiException(message: 'Request failed: ${e.toString()}');
    }
  }

  /// Handle API response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    debugPrint('Response Status: $statusCode');
    debugPrint('Response Body: ${response.body}');

    // Check if response body is empty
    if (response.body.isEmpty) {
      debugPrint('Empty response body received');
      throw ApiException(
        message: 'Empty response from server',
        statusCode: statusCode,
      );
    }

    // Parse response
    Map<String, dynamic> jsonResponse = {};
    try {
      final dynamic parsedJson = jsonDecode(response.body);

      // Check if parsed JSON is null
      if (parsedJson == null) {
        debugPrint('Parsed JSON is null');
        throw ApiException(
          message: 'Server returned null response',
          statusCode: statusCode,
        );
      }

      // Check if it's a Map
      if (parsedJson is Map<String, dynamic>) {
        jsonResponse = parsedJson;
        debugPrint('Parsed JSON keys: ${jsonResponse.keys.join(", ")}');
      } else {
        debugPrint('Parsed JSON is not a Map: ${parsedJson.runtimeType}');
        // Try to wrap non-Map responses
        jsonResponse = {'data': parsedJson};
        debugPrint('Wrapped response in Map');
      }
    } catch (e) {
      debugPrint('Failed to parse JSON: $e');
      debugPrint('Response body: ${response.body}');
      // Throw exception if JSON parsing fails
      throw ApiException(
        message: 'Failed to parse response: $e',
        statusCode: statusCode,
      );
    }

    // Check status code
    if (statusCode >= 200 && statusCode < 300) {
      // Debug log for homepage settings response
      if (response.request?.url.toString().contains('homepage-settings') ==
          true) {
        debugPrint(
          'Homepage settings response structure: ${jsonResponse.keys.join(", ")}',
        );
        if (jsonResponse['categories'] != null) {
          debugPrint(
            'Categories count: ${(jsonResponse['categories'] as List?)?.length ?? 0}',
          );
        }
      }

      return jsonResponse;
    } else if (statusCode == 401) {
      throw ApiException(
        message: 'Unauthorized. Please check your credentials.',
        statusCode: statusCode,
        responseData: jsonResponse,
      );
    } else if (statusCode == 404) {
      throw ApiException(
        message: 'Resource not found.',
        statusCode: statusCode,
        responseData: jsonResponse,
      );
    } else if (statusCode >= 500) {
      throw ApiException(
        message: 'Server error. Please try again later.',
        statusCode: statusCode,
        responseData: jsonResponse,
      );
    } else {
      final errorMessage =
          jsonResponse['message'] ??
          jsonResponse['error'] ??
          'Request failed with status $statusCode';
      throw ApiException(
        message: errorMessage,
        statusCode: statusCode,
        responseData: jsonResponse,
      );
    }
  }

  /// Encode form data
  static String _encodeFormData(Map<String, dynamic> data) {
    return data.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');
  }
}
