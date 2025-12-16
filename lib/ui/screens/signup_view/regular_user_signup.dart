import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/logger.dart';

class RegularUserSignup extends StatefulWidget {
  const RegularUserSignup({super.key});

  @override
  State<RegularUserSignup> createState() => _RegularUserSignupState();
}

class _RegularUserSignupState extends State<RegularUserSignup> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        name: _nameController.text.trim(),
      );

      if (mounted) {
        if (success) {
          // Success - 200 response
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Navigate to sign in screen after successful signup
          Navigator.pushReplacementNamed(context, '/signin');
        } else {
          // Error - 500 or other error responses
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ??
                    'Registration failed. Please try again.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// Handle Facebook signup
  Future<void> _handleFacebookSignup() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Trigger Facebook login
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        // Get user data from Facebook
        final userData = await FacebookAuth.instance.getUserData();
        final accessToken = result.accessToken?.tokenString ?? '';

        Logger.info('Facebook signup successful: ${userData.toString()}');

        // Try social registration
        final success = await authProvider.socialRegister(
          provider: 'facebook',
          accessToken: accessToken,
          email: userData['email']?.toString(),
          name: userData['name']?.toString(),
          phone: userData['phone']?.toString(),
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            // Navigate to sign in screen after successful signup
            Navigator.pushReplacementNamed(context, '/signin');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  authProvider.errorMessage ??
                      'Facebook signup failed. Please try again.',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else if (result.status == LoginStatus.cancelled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Facebook signup cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Facebook signup failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('Facebook signup error', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle Google signup
  Future<void> _handleGoogleSignup() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Initialize Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Trigger Google sign in
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google signup cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final accessToken = googleAuth.accessToken ?? '';

      Logger.info('Google signup successful: ${googleUser.email}');

      // Try social registration
      final success = await authProvider.socialRegister(
        provider: 'google',
        accessToken: accessToken,
        email: googleUser.email,
        name: googleUser.displayName,
        phone: null,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Navigate to sign in screen after successful signup
          Navigator.pushReplacementNamed(context, '/signin');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ??
                    'Google signup failed. Please try again.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('Google signup error', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Field
              _buildInputField(
                controller: _nameController,
                label: 'Name',
                icon: Icons.person,
                placeholder: 'Enter your name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              // Email Field
              _buildInputField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                placeholder: 'help@example.com',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              // Phone Field
              _buildInputField(
                controller: _phoneController,
                label: 'Phone',
                icon: Icons.phone,
                placeholder: 'Enter your phone number',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              // Password Field
              _buildInputField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock,
                placeholder: 'Password',
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF151D51),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Signup',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Privacy Policy Text
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: Color(0xFF151D51).withOpacity(0.7),
                      fontSize: 14,
                    ),
                    children: [
                      const TextSpan(text: 'By signing up, you agree to our '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: Color(0xFF151D51),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Social Login Section
              // TODO: Enable social login buttons after configuring:
              // - Google Sign-In: Add SHA-1 fingerprint to Firebase Console and configure Info.plist
              // - Facebook Login: Set up Facebook App ID in AndroidManifest.xml and Info.plist
              Row(
                children: [
                  Expanded(
                    child: IgnorePointer(
                      ignoring:
                          true, // Disabled until configuration is complete
                      child: Opacity(
                        opacity:
                            0.5, // Visual indication that button is disabled
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Color(
                                    0xFF1877F2,
                                  ), // Facebook blue color
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    'f',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Facebook',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: IgnorePointer(
                      ignoring:
                          true, // Disabled until configuration is complete
                      child: Opacity(
                        opacity:
                            0.5, // Visual indication that button is disabled
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.g_mobiledata,
                                size: 24,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Google',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Sign In Link
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Color(0xFF151D51).withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/signin');
                      },
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: Color(0xFF151D51),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String placeholder,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF151D51),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 45,
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFFF2F2F4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const SizedBox(width: 20),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    obscureText: isPassword ? _obscureText : false,
                    keyboardType: keyboardType,
                    style: const TextStyle(
                      color: Color(0xFF151D51),
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle: TextStyle(
                        color: Color(0xFF151D51).withOpacity(0.6),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      errorStyle: TextStyle(height: 0),
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      suffixIcon: isPassword
                          ? IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Color(0xFF151D51),
                              ),
                              onPressed: _togglePasswordVisibility,
                            )
                          : null,
                    ),
                    validator: validator,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
