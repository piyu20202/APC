import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/utils/logger.dart';
import '../models/user_model.dart';

class AuthService {
  /// Login user with email and password
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('Attempting to login with email: $email');

      final response = await ApiClient.post(
        endpoint: ApiEndpoints.login,
        body: {'email': email, 'password': password},
      );

      if (response.isEmpty) {
        throw ApiException(message: 'Invalid response from server');
      }

      Logger.info('Login successful');
      return LoginResponse.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      Logger.error('Login failed', e);
      throw ApiException(message: 'Login failed: ${e.toString()}');
    }
  }
}
