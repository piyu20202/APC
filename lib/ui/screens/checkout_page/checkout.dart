import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:apcproject/services/storage_service.dart';
import '../../../providers/auth_provider.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _companyController = TextEditingController();
  final _areaCodeController = TextEditingController();
  final _landlineController = TextEditingController();
  final _unitController = TextEditingController();
  final _addressController = TextEditingController();
  final _suburbController = TextEditingController();
  final _postCodeController = TextEditingController();
  final _orderNoteController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Shipping method
  String _shippingMethod = 'Ship to Address';
  String? _selectedPickupLocation;

  // Login status
  bool _isLoggedIn = false;
  bool _isLoadingUserData = true;

  // States list
  final List<String> _states = [
    'NSW',
    'VIC',
    'QLD',
    'SA',
    'WA',
    'TAS',
    'NT',
    'ACT',
  ];
  String? _selectedState;

  // Country selection (was previously defaulted)
  String? _selectedCountry;

  // Valid area codes for dropdown
  static const List<String> _validAreaCodes = ['+61', '+1', '+44'];

  // Get valid area code from controller or null (no default prefill)
  String? _getValidAreaCodeOrNull() {
    final areaCode = _areaCodeController.text.trim();
    if (areaCode.isNotEmpty && _validAreaCodes.contains(areaCode)) {
      return areaCode;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _checkLoginAndPrefillForm();
    _addAddressListenersForShippingSummary();
  }

  VoidCallback? _shippingSummaryRebuild;

  void _addAddressListenersForShippingSummary() {
    _shippingSummaryRebuild = () {
      if (mounted) setState(() {});
    };
    _unitController.addListener(_shippingSummaryRebuild!);
    _addressController.addListener(_shippingSummaryRebuild!);
    _suburbController.addListener(_shippingSummaryRebuild!);
    _postCodeController.addListener(_shippingSummaryRebuild!);
  }

  void _prefillDummyBillingDetailsIfEmpty() {
    // No dummy prefill - user enters all fields manually
  }

  /// Check login status and pre-fill form with logged-in user data
  Future<void> _checkLoginAndPrefillForm() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _isLoggedIn = authProvider.isLoggedIn;

    if (!_isLoggedIn) {
      // User is not logged in - redirect to login
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Please login to continue checkout',
          toastLength: Toast.LENGTH_SHORT,
        );
        Navigator.pushReplacementNamed(context, '/signin');
      }
      return;
    }

    // User is logged in - get user data.
    // No dummy prefill - user enters all billing/address fields manually.
    _prefillDummyBillingDetailsIfEmpty();

    setState(() {
      _isLoadingUserData = false;
    });
  }

  @override
  void dispose() {
    if (_shippingSummaryRebuild != null) {
      _unitController.removeListener(_shippingSummaryRebuild!);
      _addressController.removeListener(_shippingSummaryRebuild!);
      _suburbController.removeListener(_shippingSummaryRebuild!);
      _postCodeController.removeListener(_shippingSummaryRebuild!);
    }
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _companyController.dispose();
    _areaCodeController.dispose();
    _landlineController.dispose();
    _unitController.dispose();
    _addressController.dispose();
    _suburbController.dispose();
    _postCodeController.dispose();
    _orderNoteController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking login status
    if (_isLoadingUserData) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F8F8),
          elevation: 0,
          title: const Text(
            'Order Price Details',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        title: const Text(
          'Order Price Details',
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
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shipping Method Section
                _buildShippingMethodSection(),
                const SizedBox(height: 24),

                // Billing Details Section
                _buildBillingDetailsSection(),
                const SizedBox(height: 24),

                // Shipping Details Summary
                _buildShippingDetailsSummary(),
                const SizedBox(height: 24),

                // Order Note
                _buildOrderNoteSection(),
                const SizedBox(height: 24),

                // Account Creation Section - REMOVED for mobile
                // (Mobile users must be logged in, so account creation not needed)

                // Continue Button
                _buildContinueButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShippingMethodSection() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shipping Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _shippingMethod,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Ship to Address',
                  child: Text('Ship to Address'),
                ),
                DropdownMenuItem(value: 'Pickup', child: Text('Pickup')),
              ],
              onChanged: (value) {
                setState(() {
                  _shippingMethod = value!;
                  if (_shippingMethod == 'Ship to Address') {
                    _selectedPickupLocation = null;
                  }
                });
              },
            ),
            if (_shippingMethod == 'Pickup') ...[
              const SizedBox(height: 16),
              const Text(
                'Select your Pick-Up Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              RadioListTile<String>(
                title: const Text('53 Cochranes Road, Moorabbin, VIC 3189'),
                value: '53 Cochranes Road, Moorabbin, VIC 3189',
                groupValue: _selectedPickupLocation,
                onChanged: (value) {
                  setState(() {
                    _selectedPickupLocation = value;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text(
                  'Unit 2, 2 Commercial Dr, Shailer Park QLD 4128',
                ),
                value: 'Unit 2, 2 Commercial Dr, Shailer Park QLD 4128',
                groupValue: _selectedPickupLocation,
                onChanged: (value) {
                  setState(() {
                    _selectedPickupLocation = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShippingDetailsSummary() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.blue[700], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Shipping Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF151D51),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Method', _shippingMethod),
            if (_shippingMethod == 'Ship to Address') ...[
              _buildDetailRow(
                'Address',
                [
                  _unitController.text.trim(),
                  _addressController.text.trim(),
                  _suburbController.text.trim(),
                  _selectedState ?? '',
                  _postCodeController.text.trim(),
                  _selectedCountry ?? '',
                ].where((s) => s.isNotEmpty).join(', '),
              ),
              if (_addressController.text.trim().isEmpty &&
                  _unitController.text.trim().isEmpty)
                Text(
                  'Enter address in Billing Details above',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ] else if (_shippingMethod == 'Pickup' &&
                _selectedPickupLocation != null) ...[
              _buildDetailRow('Pickup Location', _selectedPickupLocation!),
            ] else if (_shippingMethod == 'Pickup') ...[
              Text(
                'Select pickup location above',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: 14,
                color: value.isEmpty ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingDetailsSection() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Billing Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name*',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address*',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Mobile Number
            TextFormField(
              controller: _mobileController,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Company Name
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Landline Number
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _getValidAreaCodeOrNull(),
                    decoration: const InputDecoration(
                      labelText: 'Area Code',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    hint: const Text('Select', overflow: TextOverflow.ellipsis),
                    items: const [
                      DropdownMenuItem(value: '+61', child: Text('+61')),
                      DropdownMenuItem(value: '+1', child: Text('+1')),
                      DropdownMenuItem(value: '+44', child: Text('+44')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _areaCodeController.text = value ?? '';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _landlineController,
                    decoration: const InputDecoration(
                      labelText: 'Landline Number',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Unit/Apartment Number
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: 'Unit/Apartment Number',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address*',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Suburb
            TextFormField(
              controller: _suburbController,
              decoration: const InputDecoration(
                labelText: 'Suburb*',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your suburb';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // State and Post Code
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value:
                        (_selectedState != null &&
                            _states.contains(_selectedState))
                        ? _selectedState
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'State*',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    hint: const Text('Select'),
                    items: _states.map((state) {
                      return DropdownMenuItem(value: state, child: Text(state));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedState = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select state';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _postCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Post Code*',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter post code';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Country
            DropdownButtonFormField<String>(
              value: _selectedCountry,
              decoration: const InputDecoration(
                labelText: 'Country*',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              hint: const Text('Select'),
              items: const [
                DropdownMenuItem(value: 'Australia', child: Text('Australia')),
                DropdownMenuItem(
                  value: 'New Zealand',
                  child: Text('New Zealand'),
                ),
                DropdownMenuItem(
                  value: 'United States',
                  child: Text('United States'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select country';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderNoteSection() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Note (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _orderNoteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Add any special instructions or notes for your order...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          // Validate form
          if (_formKey.currentState!.validate()) {
            // Double-check user is logged in (defensive check)
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            if (!authProvider.isLoggedIn) {
              Fluttertoast.showToast(
                msg: 'Please login to continue',
                toastLength: Toast.LENGTH_SHORT,
              );
              Navigator.pushReplacementNamed(context, '/signin');
              return;
            }

            // Save checkout form data (no account creation needed for mobile)
            final checkoutData = {
              'shipping_method': _shippingMethod,
              'pickup_location': _selectedPickupLocation,
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'mobile': _mobileController.text.trim(),
              'company': _companyController.text.trim(),
              'area_code': _areaCodeController.text.trim(),
              'landline': _landlineController.text.trim(),
              'unit': _unitController.text.trim(),
              'address': _addressController.text.trim(),
              'suburb': _suburbController.text.trim(),
              'state': _selectedState,
              'country': _selectedCountry,
              'post_code': _postCodeController.text.trim(),
              'order_note': _orderNoteController.text.trim(),
            };

            await StorageService.saveCheckoutData(checkoutData);

            // Navigate to order price detail page
            if (mounted) {
              Navigator.pushNamed(context, '/order-price-detail');
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF002e5b),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'CONTINUE',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
