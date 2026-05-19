import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/exceptions/api_exception.dart';
import '../../../services/storage_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _landlineController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();

  String _selectedAreaCode = '02';
  String _selectedState = 'ACT';
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

  void _applyProfileToForm(Map<String, dynamic> profile) {
    final state = profile['state']?.toString();
    final areaCode = profile['area_code']?.toString();
    final country = profile['country']?.toString();

    _nameController.text = profile['name']?.toString() ?? '';
    _phoneController.text = profile['phone']?.toString() ?? '';
    _landlineController.text = profile['landline']?.toString() ?? '';
    _unitController.text = profile['unit_apartmentno']?.toString() ?? '';
    _addressController.text = profile['address']?.toString() ?? '';
    _cityController.text = profile['city']?.toString() ?? '';
    _zipController.text = profile['zip']?.toString() ?? '';

    if (areaCode != null &&
        areaCode.isNotEmpty &&
        _areaCodes.contains(areaCode)) {
      _selectedAreaCode = areaCode;
    }
    if (state != null && state.isNotEmpty && _australiaStatesCities.containsKey(state)) {
      _selectedState = state;
    }
    if (country != null && country.isNotEmpty) {
      _selectedCountry = country;
    }
  }

  String? _messageFromApi(Map<String, dynamic>? data) {
    final message = data?['message'];
    if (message == null) return null;
    final text = message.toString().trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _loadUserDataFromStorage() async {
    final userData = await StorageService.getUserData();
    if (userData == null) return;
    _applyProfileToForm(userData.toJson());
  }

  /// Loads profile from GET /user/profile; falls back to local session on failure.
  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final profileResponse = await _authService.fetchUserProfile();
      final profileData = UserModel.unwrapProfileData(profileResponse);

      if (profileData != null) {
        setState(() => _applyProfileToForm(profileData));
        await StorageService.mergeUserFromProfileResponse(profileResponse);
        if (mounted) {
          await Provider.of<AuthProvider>(context, listen: false)
              .refreshUserFromStorage();
        }
      } else {
        await _loadUserDataFromStorage();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading profile from API: $e');
      try {
        await _loadUserDataFromStorage();
        if (mounted) setState(() {});
      } catch (storageError) {
        debugPrint('Error loading user data from storage: $storageError');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
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
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: SafeArea(
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

                      // City field
                      _buildFormField(
                        label: 'City',
                        controller: _cityController,
                        isRequired: true,
                        hintText: 'Enter City',
                      ),
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
        ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
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
          cursorColor: const Color(0xFF1A365D),
          showCursor: true,
          cursorWidth: 2.0,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
        'city': _cityController.text.trim(),
        'state': _selectedState,
        'country': _selectedCountry,
        'zip': _zipController.text.trim(),
      };

      // Remove empty fields
      formData.removeWhere((key, value) => value.toString().isEmpty);

      // POST /user/update-profile
      final updateResponse = await _authService.updateUserProfile(formData);

      // GET /user/profile — refresh local session with latest fields
      final profileResponse = await _authService.fetchUserProfile();
      await StorageService.mergeUserFromProfileResponse(profileResponse);

      if (mounted) {
        await Provider.of<AuthProvider>(context, listen: false)
            .refreshUserFromStorage();
      }

      if (mounted) {
        Fluttertoast.showToast(
          msg: _messageFromApi(updateResponse) ??
              'Profile updated successfully',
          toastLength: Toast.LENGTH_LONG,
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: e.message.isNotEmpty
              ? e.message
              : 'Something went wrong',
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (_) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Something went wrong',
          toastLength: Toast.LENGTH_LONG,
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
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }
}
