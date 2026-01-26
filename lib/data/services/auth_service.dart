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

  /// Register user with email, password, phone, and name
  Future<LoginResponse> register({
    required String email,
    required String password,
    required String phone,
    required String name,
  }) async {
    try {
      Logger.info('Attempting to register with email: $email');

      final response = await ApiClient.post(
        endpoint: ApiEndpoints.register,
        body: {
          'email': email,
          'password': password,
          'phone': phone,
          'name': name,
        },
      );

      if (response.isEmpty) {
        throw ApiException(message: 'Invalid response from server');
      }

      Logger.info('Registration successful');
      return LoginResponse.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      Logger.error('Registration failed', e);
      throw ApiException(message: 'Registration failed: ${e.toString()}');
    }
  }

  /// Request password reset link to be sent to the user's email
  Future<void> forgotPassword({required String email}) async {
    try {
      Logger.info('Requesting password reset for email: $email');

      final response = await ApiClient.post(
        endpoint: ApiEndpoints.forgotPassword,
        body: {'email': email},
      );

      if (response.isEmpty) {
        throw ApiException(message: 'Invalid response from server');
      }

      Logger.info('Forgot password request successful');
    } on ApiException {
      rethrow;
    } catch (e) {
      Logger.error('Forgot password request failed', e);
      throw ApiException(message: 'Failed to send reset link: ${e.toString()}');
    }
  }

  /// Social login with Facebook or Google
  Future<LoginResponse> socialLogin({
    required String provider, // 'facebook' or 'google'
    required String accessToken,
    String? email,
    String? name,
    String? phone,
  }) async {
    try {
      Logger.info('Attempting social login with provider: $provider');

      final response = await ApiClient.post(
        endpoint: ApiEndpoints.socialLogin,
        body: {
          'provider': provider,
          'access_token': accessToken,
          if (email != null) 'email': email,
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
        },
      );

      if (response.isEmpty) {
        throw ApiException(message: 'Invalid response from server');
      }

      Logger.info('Social login successful');
      return LoginResponse.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      Logger.error('Social login failed', e);
      throw ApiException(message: 'Social login failed: ${e.toString()}');
    }
  }

  /// Social register with Facebook or Google
  Future<LoginResponse> socialRegister({
    required String provider, // 'facebook' or 'google'
    required String accessToken,
    String? email,
    String? name,
    String? phone,
  }) async {
    try {
      Logger.info('Attempting social registration with provider: $provider');

      final response = await ApiClient.post(
        endpoint: ApiEndpoints.socialRegister,
        body: {
          'provider': provider,
          'access_token': accessToken,
          if (email != null) 'email': email,
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
        },
      );

      if (response.isEmpty) {
        throw ApiException(message: 'Invalid response from server');
      }

      Logger.info('Social registration successful');
      return LoginResponse.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      Logger.error('Social registration failed', e);
      throw ApiException(
        message: 'Social registration failed: ${e.toString()}',
      );
    }
  }

  /// Logout the current user (requires auth token)
  /// Expected 200 response: { "message": "Logged out successfully." }
  Future<String?> logout() async {
    try {
      Logger.info('Attempting to logout');

      final response = await ApiClient.post(
        endpoint: ApiEndpoints.logout,
        body: const {},
        requireAuth: true,
      );

      return response['message']?.toString();
    } on ApiException {
      rethrow;
    } catch (e) {
      Logger.error('Logout failed', e);
      throw ApiException(message: 'Logout failed: ${e.toString()}');
    }
  }

  /// Change password for the current user (requires auth token)
  /// Body: { "current_password": "", "new_password": "" }
  /// Expected 200 response on success
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      Logger.info('Attempting to change password');

      await ApiClient.post(
        endpoint: ApiEndpoints.changePassword,
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        contentType: 'application/json',
        requireAuth: true,
      );

      Logger.info('Change password successful');
    } on ApiException {
      rethrow;
    } catch (e) {
      Logger.error('Change password failed', e);
      throw ApiException(message: 'Change password failed: ${e.toString()}');
    }
  }
}
