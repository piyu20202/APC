import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/exceptions/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';

class ProductInquiryService {
  Future<Map<String, dynamic>> submitInquiry({
    required String sku,
    required String productTitle,
    required String name,
    required String email,
    required String phone,
    required String message,
    List<XFile> images = const [],
  }) async {
    try {
      Logger.info('Submitting contact form for SKU: $sku');

      final files = <http.MultipartFile>[];
      for (final image in images) {
        files.add(
          await http.MultipartFile.fromPath(
            'upload_imgs[]',
            image.path,
          ),
        );
      }

      return await ApiClient.postMultipart(
        endpoint: ApiEndpoints.contactSubmit,
        requireAuth: true,
        fields: {
          'name': name,
          'email': email,
          'phone': phone,
          'message': message,
          'hidden_product_sku': sku,
          'hidden_product_name': productTitle,
        },
        files: files.isEmpty ? null : files,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      Logger.error('Failed to submit contact form', e);
      throw ApiException(
        message: 'Failed to submit inquiry: ${e.toString()}',
      );
    }
  }
}
