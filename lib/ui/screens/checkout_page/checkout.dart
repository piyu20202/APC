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
  }

  void _prefillDummyBillingDetailsIfEmpty() {
    // Only fill fields that are currently empty, so we don't override user input.
    if (_nameController.text.trim().isEmpty) _nameController.text = 'Vikram';
    if (_emailController.text.trim().isEmpty) {
      _emailController.text = 'vikram@vmail.in';
    }
    if (_mobileController.text.trim().isEmpty) {
      _mobileController.text = '+61 400 000 000';
    }
    if (_companyController.text.trim().isEmpty) {
      _companyController.text = 'ABC PVT LTD';
    }

    // Address details (Australia)
    if (_unitController.text.trim().isEmpty) _unitController.text = 'Unit 10';
    if (_addressController.text.trim().isEmpty) {
      _addressController.text = '1 George St';
    }
    // This field is labeled "Suburb" in the UI; treat it as the city.
    if (_suburbController.text.trim().isEmpty) {
      _suburbController.text = 'Sydney';
    }
    if (_postCodeController.text.trim().isEmpty) {
      _postCodeController.text = '2000';
    }

    // Phone (area code dropdown + landline)
    if (_areaCodeController.text.trim().isEmpty) {
      _areaCodeController.text = '+61';
    }
    if (_landlineController.text.trim().isEmpty) {
      _landlineController.text = '2 1234 5678';
    }

    // Dropdowns
    _selectedState ??= 'NSW';
    _selectedCountry ??= 'Australia';
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
    //
    // NOTE: This app currently doesn't prefill from user profile here.
    // To avoid an empty Order Price Details screen during demos/testing,
    // we fill dummy values when fields are blank (without overriding user input).
    _prefillDummyBillingDetailsIfEmpty();

    setState(() {
      _isLoadingUserData = false;
    });
  }

  @override
  void dispose() {
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
