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

  /// Register user
  /// Returns LoginResponse containing user data and access token
  Future<LoginResponse> register({
    required String email,
    required String password,
    required String phone,
    required String name,
  }) async {
    try {
      Logger.info('Repository: Starting registration process');

      final response = await _authService.register(
        email: email,
        password: password,
        phone: phone,
        name: name,
      );

      Logger.info('Repository: Registration successful');
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      Logger.error('Repository: Registration error', e);
      throw ApiException(message: 'Failed to register: ${e.toString()}');
    }
  }

  /// Social login with Facebook or Google
  Future<LoginResponse> socialLogin({
    required String provider,
    required String accessToken,
    String? email,
    String? name,
    String? phone,
  }) async {
    try {
      Logger.info('Repository: Starting social login process');

      final response = await _authService.socialLogin(
        provider: provider,
        accessToken: accessToken,
        email: email,
        name: name,
        phone: phone,
      );

      Logger.info('Repository: Social login successful');
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      Logger.error('Repository: Social login error', e);
      throw ApiException(
        message: 'Failed to login with social provider: ${e.toString()}',
      );
    }
  }

  /// Social register with Facebook or Google
  Future<LoginResponse> socialRegister({
    required String provider,
    required String accessToken,
    String? email,
    String? name,
    String? phone,
  }) async {
    try {
      Logger.info('Repository: Starting social registration process');

      final response = await _authService.socialRegister(
        provider: provider,
        accessToken: accessToken,
        email: email,
        name: name,
        phone: phone,
      );

      Logger.info('Repository: Social registration successful');
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      Logger.error('Repository: Social registration error', e);
      throw ApiException(
        message: 'Failed to register with social provider: ${e.toString()}',
      );
    }
  }
}
