import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/utils/logger.dart';
import '../models/settings_model.dart';

class SettingsService {
  /// Fetch settings from the server
  Future<SettingsModel> getSettings() async {
    try {
      Logger.info('Fetching settings from server');

      final response = await ApiClient.get(
        endpoint: ApiEndpoints.settings,
        requireAuth: true, // This will automatically add Bearer token
      );

      if (response.isEmpty) {
        throw ApiException(message: 'Invalid response from server');
      }

      Logger.info('Settings fetched successfully');
      return SettingsModel.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      Logger.error('Failed to fetch settings', e);
      throw ApiException(message: 'Failed to fetch settings: ${e.toString()}');
    }
  }
}
