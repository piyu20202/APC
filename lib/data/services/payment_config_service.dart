import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/utils/logger.dart';
import '../../services/storage_service.dart';
import '../models/payment_config_model.dart';

class PaymentConfigService {
  /// Fetch payment configurations from the API and save them to Storage
  static Future<PaymentConfigModel?> fetchAndSaveConfig() async {
    try {
      Logger.info('Fetching payment configurations from API');

      final response = await ApiClient.get(
        endpoint: ApiEndpoints.paymentConfigurations,
        requireAuth: true,
      );

      final config = PaymentConfigModel.fromJson(response);
      
      // Save to storage
      await StorageService.savePaymentConfig(config);
      
      Logger.info('Payment configurations fetched and saved successfully');
      return config;
    } on ApiException catch (e) {
      Logger.error('API Error fetching payment configurations', e);
      return null;
    } catch (e) {
      Logger.error('Unexpected error fetching payment configurations', e);
      return null;
    }
  }

  /// Get cached payment configuration
  static Future<PaymentConfigModel?> getCachedConfig() async {
    return await StorageService.getPaymentConfig();
  }
}
