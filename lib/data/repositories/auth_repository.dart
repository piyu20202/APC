import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/utils/logger.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository({AuthService? authService})
    : _authService = authService ?? AuthService();

  /// Login user
  /// Returns LoginResponse containing user data and access token
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('Repository: Starting login process');

      final response = await _authService.login(
        email: email,
        password: password,
      );

      Logger.info('Repository: Login successful');
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      Logger.error('Repository: Login error', e);
      throw ApiException(message: 'Failed to login: ${e.toString()}');
    }
  }
}
