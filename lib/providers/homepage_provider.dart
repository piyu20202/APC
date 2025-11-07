import 'package:flutter/material.dart';
import '../data/repositories/homepage_repository.dart';
import '../data/models/homepage_model.dart';
import '../core/exceptions/api_exception.dart';
import '../core/utils/logger.dart';

class HomepageProvider extends ChangeNotifier {
  final HomepageRepository _homepageRepository;

  // State management
  bool _isLoading = false;
  bool _isLoadingLatestProducts = false;
  bool _isLoadingSaleProducts = false;
  String? _errorMessage;
  HomepageModel? _homepageData;
  List<LatestProduct> _latestProducts = [];
  List<LatestProduct> _saleProducts = [];

  HomepageProvider({HomepageRepository? homepageRepository})
    : _homepageRepository = homepageRepository ?? HomepageRepository();

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingLatestProducts => _isLoadingLatestProducts;
  bool get isLoadingSaleProducts => _isLoadingSaleProducts;
  String? get errorMessage => _errorMessage;
  HomepageModel? get homepageData => _homepageData;
  List<LatestProduct> get latestProducts => _latestProducts;
  List<LatestProduct> get saleProducts => _saleProducts;
  List<Category> get categories => _homepageData?.categories ?? [];
  List<Partner> get partners => _homepageData?.partners ?? [];
  List<Service> get services => _homepageData?.services ?? [];

  /// Load homepage data from API
  Future<void> loadHomepageData() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      Logger.info('Provider: Loading homepage data');
      _homepageData = await _homepageRepository.getHomepageData();

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      Logger.info('Provider: Homepage data loaded successfully');
    } on ApiException catch (e) {
      Logger.error('Provider: Failed to load homepage data', e);
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      Logger.error('Provider: Unexpected error loading homepage', e);
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
    }
  }

  /// Load latest products from API
  Future<void> loadLatestProducts() async {
    try {
      _isLoadingLatestProducts = true;
      _errorMessage = null;
      notifyListeners();

      Logger.info('Provider: Loading latest products');
      _latestProducts = await _homepageRepository.getLatestProducts();

      _isLoadingLatestProducts = false;
      _errorMessage = null;
      notifyListeners();

      Logger.info('Provider: Latest products loaded successfully');
    } on ApiException catch (e) {
      Logger.error('Provider: Failed to load latest products', e);
      _isLoadingLatestProducts = false;
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      Logger.error('Provider: Unexpected error loading latest products', e);
      _isLoadingLatestProducts = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
    }
  }

  /// Load sale products from API
  Future<void> loadSaleProducts() async {
    try {
      _isLoadingSaleProducts = true;
      _errorMessage = null;
      notifyListeners();

      Logger.info('Provider: Loading sale products');
      _saleProducts = await _homepageRepository.getSaleProducts();

      _isLoadingSaleProducts = false;
      _errorMessage = null;
      notifyListeners();

      Logger.info('Provider: Sale products loaded successfully');
    } on ApiException catch (e) {
      Logger.error('Provider: Failed to load sale products', e);
      _isLoadingSaleProducts = false;
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      Logger.error('Provider: Unexpected error loading sale products', e);
      _isLoadingSaleProducts = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh all homepage data
  Future<void> refresh() async {
    await Future.wait([
      loadHomepageData(),
      loadLatestProducts(),
      loadSaleProducts(),
    ]);
  }
}
