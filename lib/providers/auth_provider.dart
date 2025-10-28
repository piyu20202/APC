import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';
import '../core/exceptions/api_exception.dart';
import '../core/utils/logger.dart';
import '../../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  // State management
  bool _isLoading = false;
  String? _errorMessage;
  LoginResponse? _loginResponse;
  UserModel? _currentUser;

  AuthProvider({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LoginResponse? get loginResponse => _loginResponse;
  UserModel? get currentUser => _currentUser;
  String? get accessToken => _loginResponse?.accessToken;

  // Check if user is logged in
  bool get isLoggedIn => _loginResponse != null && _currentUser != null;

  // Check if user is trade user
  bool get isTradeUser => _currentUser?.isTradeUser == 1;

  // Check if user is special user
  bool get isSpecialUser => _currentUser?.specialUser == 1;

  /// Login with email and password
  Future<bool> login({required String email, required String password}) async {
    try {
      // Set loading state
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      Logger.info('Provider: Starting login process');

      // Call repository
      final response = await _authRepository.login(
        email: email,
        password: password,
      );

      // Update state
      _loginResponse = response;
      _currentUser = response.user;

      // Save login data to SharedPreferences
      await StorageService.saveLoginData(response);

      // Reset loading state
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      Logger.info('Provider: Login successful for user ${_currentUser?.name}');
      return true;
    } on ApiException catch (e) {
      Logger.error('Provider: Login failed', e);
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      Logger.error('Provider: Unexpected error', e);
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    Logger.info('Provider: Logging out user');
    _loginResponse = null;
    _currentUser = null;
    _errorMessage = null;
    await StorageService.clearAllData(); // Clear both login and settings data
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
