import 'package:flutter/material.dart';
import '../../services/user_role_service.dart';

class RegisterTraderUserPage extends StatefulWidget {
  const RegisterTraderUserPage({super.key});

  @override
  State<RegisterTraderUserPage> createState() => _RegisterTraderUserPageState();
}

class _RegisterTraderUserPageState extends State<RegisterTraderUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(text: 'vikram@umallin');
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController(text: '******');
  final _confirmPasswordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyWebsiteController = TextEditingController();
  final _abnNumberController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _landlineController = TextEditingController();
  final _suburbController = TextEditingController();
  final _othersController = TextEditingController();
  
  // Billing Address Controllers
  final _billingNameController = TextEditingController();
  final _billingEmailController = TextEditingController();
  final _billingMobileController = TextEditingController();
  final _billingLandlineController = TextEditingController();
  final _unitNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _postCodeController = TextEditingController();
  final _billingSuburbController = TextEditingController();

  String _selectedAreaCode = '02';
  String _selectedBillingAreaCode = '02';
  String _selectedState = 'ACT';
  String _selectedCountry = 'Australia';
  bool _agreeToTerms = false;
  
  // Business Activities
  Map<String, bool> _businessActivities = {
    'Gate and automation installer': false,
    'Fencing installer': false,
    'Gate and Fencing fabricator': false,
    'Electrical installation': false,
    'Intercom installation': false,
    'Security company': false,
    'Property maintenance': false,
    'Builder': false,
    'Others': false,
  };

  final List<String> _areaCodes = ['02', '03', '07', '08'];
  final List<String> _states = ['ACT', 'NSW', 'NT', 'QLD', 'SA', 'TAS', 'VIC', 'WA'];
  final List<String> _countries = ['Australia'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _companyWebsiteController.dispose();
    _abnNumberController.dispose();
    _businessNameController.dispose();
    _landlineController.dispose();
    _suburbController.dispose();
    _othersController.dispose();
    _billingNameController.dispose();
    _billingEmailController.dispose();
    _billingMobileController.dispose();
    _billingLandlineController.dispose();
    _unitNumberController.dispose();
    _addressController.dispose();
    _postCodeController.dispose();
    _billingSuburbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        title: const Text(
          'Register as Trade User',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Center(
                  child: Text(
                    'Register as Trade User',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // User and Company Details Section
                _buildSectionTitle('User and Company Details'),
                const SizedBox(height: 16),
                
                _buildInputField('Name*', _nameController, 'Name*', isRequired: true),
                _buildInputField('Email Address*', _emailController, 'Email Address*', isRequired: true, isEmail: true),
                _buildInputField('Mobile Number*', _mobileController, 'Mobile Number*', isRequired: true, isPhone: true),
                _buildInputField('Password*', _passwordController, 'Password*', isRequired: true, isPassword: true),
                _buildInputField('Confirm Password*', _confirmPasswordController, 'Confirm Password*', isRequired: true, isPassword: true),
                _buildInputField('Company Name*', _companyNameController, 'Company Name', isRequired: true),
                _buildInputField('Company Website', _companyWebsiteController, 'Company Website'),
                _buildInputField('ABN Number*', _abnNumberController, 'ABN Number*', isRequired: true),
                _buildInputField('Business Name', _businessNameController, 'Business Name'),
                
                // Area Code and Landline
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildDropdown('Area Code*', _selectedAreaCode, _areaCodes, (value) {
                        setState(() {
                          _selectedAreaCode = value!;
                        });
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _buildInputField('Landline Number*', _landlineController, 'Landline Number*', isRequired: true, isPhone: true),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Base of Operation Section
                _buildSectionTitle('Base of Operation / Region'),
                const SizedBox(height: 16),
                _buildInputField('Suburb (or Post Code) for area of operations', _suburbController, 'Suburb (or Post Code) for area of operations'),
                const Text(
                  '(Please provide a comma separated list)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Business Activities Section
                _buildSectionTitle('Key Business Activities'),
                const Text(
                  '(Please select at least one and all that apply)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBusinessActivities(),
                
                const SizedBox(height: 24),
                
                // Billing Address Section
                _buildSectionTitle('Billing Address'),
                const SizedBox(height: 16),
                
                _buildInputField('Name*', _billingNameController, 'Name', isRequired: true),
                _buildInputField('Email Address*', _billingEmailController, 'Email Address', isRequired: true, isEmail: true),
                _buildInputField('Mobile Number*', _billingMobileController, 'Mobile Number', isRequired: true, isPhone: true),
                
                // Billing Area Code and Landline
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildDropdown('Area Code*', _selectedBillingAreaCode, _areaCodes, (value) {
                        setState(() {
                          _selectedBillingAreaCode = value!;
                        });
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _buildInputField('Landline Number*', _billingLandlineController, 'Landline Number', isRequired: true, isPhone: true),
                    ),
                  ],
                ),
                
                _buildInputField('Unit / Apartment Number', _unitNumberController, 'Unit/Apartment Number'),
                _buildInputField('Address', _addressController, 'Address'),
                _buildInputField('Post Code*', _postCodeController, 'Post Code*', isRequired: true),
                _buildInputField('Suburb', _billingSuburbController, 'Suburb'),
                
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildDropdown('State', _selectedState, _states, (value) {
                        setState(() {
                          _selectedState = value!;
                        });
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _buildReadOnlyField('Country', 'Australia'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Terms and Conditions
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      activeColor: Colors.orange,
                    ),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _agreeToTerms ? _handleRegister : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _agreeToTerms ? Colors.orange : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'REGISTER',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF151D51),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint, {
    bool isRequired = false,
    bool isEmail = false,
    bool isPhone = false,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF151D51),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: isEmail ? TextInputType.emailAddress : 
                         isPhone ? TextInputType.phone : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return 'This field is required';
              }
              if (isEmail && value != null && value.isNotEmpty) {
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
              }
              if (isPassword && value != null && value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              if (label == 'Confirm Password*' && value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF151D51),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF151D51),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessActivities() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: _businessActivities.entries.map((entry) {
          return CheckboxListTile(
            title: Text(entry.key),
            value: entry.value,
            onChanged: (value) {
              setState(() {
                _businessActivities[entry.key] = value ?? false;
              });
            },
            activeColor: Colors.orange,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  void _handleRegister() async {
    // Check if at least one business activity is selected
    bool hasSelectedActivity = _businessActivities.values.any((value) => value);
    
    if (!hasSelectedActivity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one business activity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Form is valid, proceed with registration
      try {
        // Set user as trader after successful registration
        await UserRoleService.setAsTrader();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trader registration successful! You can now access trader features.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate back to home or show success dialog
        Navigator.pop(context);
        
        // TODO: Implement actual registration logic (API calls, etc.)
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
