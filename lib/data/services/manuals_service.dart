import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';

class ManualItem {
  final String type; // 'folder' or 'file'
  final String name;
  final String? url;
  final List<ManualItem>? children;

  ManualItem({
    required this.type,
    required this.name,
    this.url,
    this.children,
  });

  factory ManualItem.fromJson(Map<String, dynamic> json) {
    return ManualItem(
      type: json['type'] ?? 'file',
      name: json['name'] ?? '',
      url: json['url'],
      children: (json['children'] as List<dynamic>?)
          ?.map((x) => ManualItem.fromJson(x as Map<String, dynamic>))
          .toList(),
    );
  }
  
  bool get isFolder => type == 'folder';
  bool get isFile => type == 'file';
}

class ManualsService {
  // Set this to false to use the real API
  static const bool useDummyData = false;

  Future<List<ManualItem>> getManuals(String type) async {
    try {
      if (useDummyData) {
        await Future.delayed(const Duration(milliseconds: 800));
        return _getDummyManuals();
      }

      final response = await ApiClient.get(
        endpoint: ApiEndpoints.manuals,
        queryParameters: {'type': type},
        requireAuth: true,
      );

      // Extract the list from the response
      final data = response['data'] ?? response['manuals'] ?? response.values.firstWhere((v) => v is List, orElse: () => null) ?? [];
      
      if (data is List) {
        return data
            .map((item) => ManualItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } catch (e) {
      Logger.error('Failed to fetch manuals', e);
      // Fallback for demo purposes if API fails
      return _getDummyManuals();
    }
  }

  List<ManualItem> _getDummyManuals() {
    return [
      ManualItem(
        type: 'folder',
        name: '01- Swing Gate Manuals',
        children: [
          ManualItem(
            type: 'file',
            name: '01- APC-Logico 24 V1.1.08 Control Panel Manual -Extended.pdf',
            url: 'https://www.gurgaonit.com/apc_production_dev/Installation-Manuals/01-%20Swing%20Gate%20Manuals/01-%20APC-Logico%2024%20V1.1.08%20Control%20Panel%20Manual%20-Extended.pdf',
          ),
          ManualItem(
            type: 'file',
            name: '01- APC-Simply24 V3.02.01 Control Panel Manual.pdf',
            url: 'https://www.gurgaonit.com/apc_production_dev/Installation-Manuals/01-%20Swing%20Gate%20Manuals/01-%20APC-Simply24%20V3.02.01%20Control%20Panel%20Manual.pdf',
          ),
        ],
      ),
      ManualItem(
        type: 'folder',
        name: '02- Sliding Gate Manuals',
        children: [
          ManualItem(
            type: 'file',
            name: 'Sliding Gate Installation Manual.pdf',
            url: 'https://www.gurgaonit.com/apc_production_dev/Installation-Manuals/02-%20Sliding%20Gate%20Manuals/Sliding%20Gate%20Manual.pdf',
          ),
        ],
      ),
    ];
  }
}
