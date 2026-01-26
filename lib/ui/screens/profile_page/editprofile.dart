import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/exceptions/api_exception.dart';
import '../../../services/storage_service.dart';
import '../../../data/models/user_model.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _landlineController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();

  String _selectedAreaCode = '02';
  String _selectedState = 'ACT';
  String _selectedCity = '';
  String _selectedCountry = 'AU';

  // Australia States and Cities mapping
  final Map<String, List<String>> _australiaStatesCities = {
    'ACT': ['Canberra'],
    'NSW': [
      'Sydney',
      'Newcastle',
      'Wollongong',
      'Albury',
      'Wagga Wagga',
      'Tamworth',
      'Orange',
      'Dubbo',
      'Nowra',
      'Bathurst',
    ],
    'VIC': [
      'Melbourne',
      'Geelong',
      'Ballarat',
      'Bendigo',
      'Shepparton',
      'Warrnambool',
      'Mildura',
      'Horsham',
      'Traralgon',
      'Sale',
    ],
    'QLD': [
      'Brisbane',
      'Gold Coast',
      'Cairns',
      'Townsville',
      'Toowoomba',
      'Rockhampton',
      'Mackay',
      'Bundaberg',
      'Hervey Bay',
      'Gladstone',
    ],
    'SA': [
      'Adelaide',
      'Mount Gambier',
      'Whyalla',
      'Murray Bridge',
      'Port Augusta',
      'Port Pirie',
      'Port Lincoln',
      'Victor Harbor',
      'Gawler',
      'Kadina',
    ],
    'WA': [
      'Perth',
      'Fremantle',
      'Bunbury',
      'Geraldton',
      'Kalgoorlie',
      'Albany',
      'Broome',
      'Port Hedland',
      'Karratha',
      'Busselton',
    ],
    'TAS': [
      'Hobart',
      'Launceston',
      'Devonport',
      'Burnie',
      'Ulverstone',
      'George Town',
      'Scottsdale',
      'Queenstown',
      'Smithton',
      'Currie',
    ],
    'NT': [
      'Darwin',
      'Alice Springs',
      'Palmerston',
      'Katherine',
      'Nhulunbuy',
      'Tennant Creek',
      'Yulara',
      'Nhulunbuy',
      'Casuarina',
      'Humpty Doo',
    ],
  };

  // Australia area codes
  final List<String> _areaCodes = ['02', '03', '07', '08'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final userData = await StorageService.getUserData();
      if (userData != null) {
        setState(() {
          _nameController.text = userData.name;
          _phoneController.text = userData.phone;
          _landlineController.text = userData.landline ?? '';
          _unitController.text = userData.unitApartmentNo ?? '';
          _addressController.text = userData.address ?? '';
          _zipController.text = userData.zip ?? '';
          _selectedAreaCode = userData.areaCode ?? '02';
          _selectedState = userData.state ?? 'ACT';
          _selectedCity = userData.city ?? '';
          _selectedCountry = userData.country ?? 'AU';

          // Update city list based on state
          if (_australiaStatesCities.containsKey(_selectedState)) {
            final cities = _australiaStatesCities[_selectedState]!;
            if (!cities.contains(_selectedCity) && cities.isNotEmpty) {
              _selectedCity = cities.first;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF1A365D),
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
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name field
                      _buildFormField(
                        label: 'Name',
                        controller: _nameController,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // Phone field
                      _buildFormField(
                        label: 'Phone',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Landline field with area code
                      _buildLandlineField(),
                      const SizedBox(height: 16),

                      // Unit/Apartment field
                      _buildFormField(
                        label: 'Unit/Apartment No',
                        controller: _unitController,
                      ),
                      const SizedBox(height: 16),

                      // Address field
                      _buildFormField(
                        label: 'Address',
                        controller: _addressController,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // State dropdown
                      _buildStateDropdown(),
                      const SizedBox(height: 16),

                      // City dropdown
                      _buildCityDropdown(),
                      const SizedBox(height: 16),

                      // Postcode field
                      _buildFormField(
                        label: 'Postcode',
                        controller: _zipController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Country (fixed as AU)
                      _buildCountryField(),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF151D51),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'SAVE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? '*' : ''),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1A365D),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF1A365D)),
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildLandlineField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Landline',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1A365D),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: DropdownButton<String>(
                value: _selectedAreaCode,
                underline: const SizedBox(),
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                dropdownColor: Colors.white,
                items: _areaCodes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedAreaCode = newValue!;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _landlineController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF1A365D)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'State*',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1A365D),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedState,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            dropdownColor: Colors.white,
            items: _australiaStatesCities.keys.map((String state) {
              return DropdownMenuItem<String>(value: state, child: Text(state));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedState = newValue!;
                // Reset city when state changes
                final cities = _australiaStatesCities[_selectedState]!;
                _selectedCity = cities.isNotEmpty ? cities.first : '';
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a state';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    final cities = _australiaStatesCities[_selectedState] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'City*',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1A365D),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCity.isNotEmpty && cities.contains(_selectedCity)
                ? _selectedCity
                : cities.isNotEmpty
                ? cities.first
                : null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            dropdownColor: Colors.white,
            items: cities.map((String city) {
              return DropdownMenuItem<String>(value: city, child: Text(city));
            }).toList(),
            onChanged: cities.isNotEmpty
                ? (String? newValue) {
                    setState(() {
                      _selectedCity = newValue!;
                    });
                  }
                : null,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a city';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCountryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Country*',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1A365D),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: const Row(
            children: [
              Text(
                'Australia (AU)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare form data - सभी fields UI से map करें
      // POST body: name, phone, landline, area_code, unit_apartmentno, address, city, state, country, zip
      // notes और photo नहीं है - जैसा आपने कहा
      final Map<String, dynamic> formData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'landline': _landlineController.text.trim(),
        'area_code': _selectedAreaCode,
        'unit_apartmentno': _unitController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _selectedCity,
        'state': _selectedState,
        'country': _selectedCountry,
        'zip': _zipController.text.trim(),
      };

      // Remove empty fields
      formData.removeWhere((key, value) => value.toString().isEmpty);

      // Make API call
      await ApiClient.post(
        endpoint: ApiEndpoints.updateProfile,
        body: formData,
        contentType: 'application/x-www-form-urlencoded',
        requireAuth: true,
      );

      // Update local storage with new data
      final userData = await StorageService.getUserData();
      if (userData != null) {
        // Create updated user model
        final updatedUser = userData.copyWith(
          name: formData['name'] ?? userData.name,
          phone: formData['phone'] ?? userData.phone,
          landline: formData['landline'] as String?,
          areaCode: formData['area_code'] as String?,
          unitApartmentNo: formData['unit_apartmentno'] as String?,
          address: formData['address'] as String?,
          city: formData['city'] as String?,
          state: formData['state'] as String?,
          country: formData['country'] as String?,
          zip: formData['zip'] as String?,
        );

        // Save updated user data
        final loginResponse = await StorageService.getLoginResponse();
        if (loginResponse != null) {
          await StorageService.saveLoginData(
            LoginResponse(
              accessToken: loginResponse.accessToken,
              tokenType: loginResponse.tokenType,
              user: updatedUser,
            ),
          );
        }
      }

      if (mounted) {
        // Success message - status code 200
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your profile is updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    } on ApiException {
      // API error - status code 200 के अलावा कुछ भी
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      // Any other error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _landlineController.dispose();
    _unitController.dispose();
    _addressController.dispose();
    _zipController.dispose();
    super.dispose();
  }
}
