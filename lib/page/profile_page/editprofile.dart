import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController(text: 'Vikram Soni');
  final TextEditingController _emailController = TextEditingController(text: 'vikram@vmail.in');
  final TextEditingController _landlineController = TextEditingController(text: '33333333');
  final TextEditingController _unitController = TextEditingController(text: 'Unit/Apartment');
  final TextEditingController _suburbController = TextEditingController(text: 'Sydney');
  final TextEditingController _deliveryNotesController = TextEditingController(text: 'Delivery notes');
  final TextEditingController _companyController = TextEditingController(text: 'Company Name');
  final TextEditingController _mobileController = TextEditingController(text: '0400000000');
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postCodeController = TextEditingController(text: '3000');

  String _selectedAreaCode = '03';
  String _selectedCountry = 'Australia';
  String _selectedState = 'ACT';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vertical form layout
                _buildFormField(
                  label: 'Name*',
                  controller: _nameController,
                  isRequired: true,
                ),
                const SizedBox(height: 20),
                
                _buildFormField(
                  label: 'Email Address*',
                  controller: _emailController,
                  isRequired: true,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                
                _buildFormField(
                  label: 'Company Name',
                  controller: _companyController,
                ),
                const SizedBox(height: 20),
                
                _buildFormField(
                  label: 'Mobile Number',
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                
                _buildLandlineField(),
                const SizedBox(height: 20),
                
                _buildFormField(
                  label: 'Address*',
                  controller: _addressController,
                  isRequired: true,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                
                _buildFormField(
                  label: 'Unit/Apartment',
                  controller: _unitController,
                ),
                const SizedBox(height: 20),
                
                _buildFormField(
                  label: 'Suburb*',
                  controller: _suburbController,
                  isRequired: true,
                ),
                const SizedBox(height: 20),
                
                _buildDropdownField(
                  label: 'State*',
                  value: _selectedState,
                  items: ['ACT', 'NSW', 'VIC', 'QLD', 'SA', 'WA', 'TAS', 'NT'],
                  onChanged: (value) {
                    setState(() {
                      _selectedState = value!;
                    });
                  },
                  isRequired: true,
                ),
                const SizedBox(height: 20),
                
                _buildFormField(
                  label: 'Post Code*',
                  controller: _postCodeController,
                  isRequired: true,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                
                _buildDropdownField(
                  label: 'Country*',
                  value: _selectedCountry,
                  items: ['Australia'],
                  onChanged: (value) {
                    setState(() {
                      _selectedCountry = value!;
                    });
                  },
                  isRequired: true,
                ),
                const SizedBox(height: 20),
                
                _buildFormField(
                  label: 'Delivery notes',
                  controller: _deliveryNotesController,
                  maxLines: 3,
                ),
                
                const SizedBox(height: 40),
                
                // Buttons Row
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 1,
                        ),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Save Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF151D51), // Same as login page button
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
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
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1A365D), // Dark blue color
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
              borderRadius: BorderRadius.circular(4),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF1A365D)),
              borderRadius: BorderRadius.circular(4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: isRequired ? (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          } : null,
        ),
      ],
    );
  }

  Widget _buildLandlineField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '(Area Code) Landline Number*',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1A365D), // Dark blue color
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
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: DropdownButton<String>(
                value: _selectedAreaCode,
                underline: const SizedBox(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                dropdownColor: Colors.white,
                items: ['02', '03', '07', '08']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
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
                    borderRadius: BorderRadius.circular(4),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF1A365D)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1A365D), // Dark blue color
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            dropdownColor: Colors.white,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            validator: isRequired ? (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            } : null,
          ),
        ),
      ],
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _landlineController.dispose();
    _unitController.dispose();
    _suburbController.dispose();
    _deliveryNotesController.dispose();
    _companyController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _postCodeController.dispose();
    super.dispose();
  }
}
