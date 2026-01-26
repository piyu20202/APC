import 'package:flutter/material.dart';
import '../../../services/storage_service.dart';
import '../../../data/models/user_model.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  bool _isLoading = true;
  UserModel? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await StorageService.getUserData();
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatAddress() {
    if (_userData == null) return '';

    final parts = <String>[];

    // Add address if exists
    if (_userData!.address != null && _userData!.address!.isNotEmpty) {
      parts.add(_userData!.address!);
    }

    // Add city, state, zip
    final cityStateZip = <String>[];
    if (_userData!.city != null && _userData!.city!.isNotEmpty) {
      cityStateZip.add(_userData!.city!);
    }
    if (_userData!.state != null && _userData!.state!.isNotEmpty) {
      cityStateZip.add(_userData!.state!);
    }
    if (_userData!.zip != null && _userData!.zip!.isNotEmpty) {
      cityStateZip.add(_userData!.zip!);
    }

    if (cityStateZip.isNotEmpty) {
      parts.add(cityStateZip.join(' '));
    }

    // Add country
    if (_userData!.country != null && _userData!.country!.isNotEmpty) {
      parts.add(_userData!.country!);
    }

    return parts.join('\n');
  }

  String _formatLandline() {
    if (_userData == null) return '';

    final areaCode = _userData!.areaCode ?? '';
    final landline = _userData!.landline ?? '';

    if (areaCode.isEmpty && landline.isEmpty) return '';
    if (areaCode.isEmpty) return landline;
    if (landline.isEmpty) return '($areaCode)';

    // Format as (03) 3333 3333
    return '($areaCode) $landline';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Account Information',
          style: TextStyle(
            color: Color(0xFF1A365D), // Dark blue color
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A365D)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Information Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoItem('Name:', _userData?.name ?? ''),
                          const SizedBox(height: 24),

                          _buildInfoItem('Address:', _formatAddress()),
                          const SizedBox(height: 24),

                          _buildInfoItem(
                            'Email Address:',
                            _userData?.email ?? '',
                          ),
                          const SizedBox(height: 24),

                          _buildInfoItem('Landline Number:', _formatLandline()),
                          const SizedBox(height: 24),

                          _buildInfoItem(
                            'Mobile Number:',
                            _userData?.phone ?? '',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1A365D), // Dark blue color
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
