import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../providers/auth_provider.dart';
import '../forgotpassword_view/forgotpassword.dart';
import '../../../data/services/settings_service.dart';
import '../../../services/storage_service.dart';
import '../../../core/utils/logger.dart';
import '../../../config/environment.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    // Closed testing / internal builds: prefill test credentials (still editable).
    if (BuildConfig.allowTestCreds) {
      final email = BuildConfig.testEmail.trim();
      if (email.isNotEmpty) {
        _emailController.text = email;
      }

      final password = BuildConfig.testPassword;
      if (password.isNotEmpty) {
        _passwordController.text = password;
      }
    }
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (success) {
          // Check if settings already exist (first time login check)
          final existingSettings = await StorageService.getSettings();
          if (!mounted) return;

          if (existingSettings == null) {
            // First time login - fetch settings from API
            await _fetchSettingsFirstTime();
            if (!mounted) return;
          }

          // Get user name from the provider
          final userName = authProvider.currentUser?.name ?? 'User';

          // Show success toast with user name
          Fluttertoast.showToast(
            msg: 'Welcome $userName! Login successful.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          // Navigate to main screen on success
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          // Show error toast message
          Fluttertoast.showToast(
            msg: authProvider.errorMessage ?? 'Login failed. Please try again.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      }
    }
  }

  /// Fetch settings from API only on first login
  Future<void> _fetchSettingsFirstTime() async {
    try {
      Logger.info('First time login - fetching settings from API');

      final settingsService = SettingsService();
      final settings = await settingsService.getSettings();

      // Save settings to shared preferences
      await StorageService.saveSettings(settings);

      Logger.info('Settings fetched and saved successfully');
    } catch (e) {
      Logger.error('Failed to fetch settings on first login', e);
      // Don't block the login process if settings fetch fails
      // Settings might be fetched later or user can continue without them
    }
  }

  // Social login is currently hidden/disabled in the UI (see Visibility(visible: false)),
  // but we keep the handlers for when configuration is completed.
  /// Handle Facebook login
  // ignore: unused_element
  Future<void> _handleFacebookLogin() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Trigger Facebook login
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        // Get user data from Facebook
        final userData = await FacebookAuth.instance.getUserData();
        final accessToken = result.accessToken?.tokenString ?? '';

        Logger.info('Facebook login successful: ${userData.toString()}');

        // Try social login first (for existing users)
        bool success = await authProvider.socialLogin(
          provider: 'facebook',
          accessToken: accessToken,
          email: userData['email']?.toString(),
          name: userData['name']?.toString(),
          phone: userData['phone']?.toString(),
        );

        if (!success && mounted) {
          // If login fails, try registration (for new users)
          success = await authProvider.socialRegister(
            provider: 'facebook',
            accessToken: accessToken,
            email: userData['email']?.toString(),
            name: userData['name']?.toString(),
            phone: userData['phone']?.toString(),
          );
        }

        if (mounted) {
          if (success) {
            // Check if settings already exist (first time login check)
            final existingSettings = await StorageService.getSettings();
            if (!mounted) return;

            if (existingSettings == null) {
              await _fetchSettingsFirstTime();
              if (!mounted) return;
            }

            final userName = authProvider.currentUser?.name ?? 'User';

            Fluttertoast.showToast(
              msg: 'Welcome $userName! Login successful.',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0,
            );

            Navigator.pushReplacementNamed(context, '/main');
          } else {
            Fluttertoast.showToast(
              msg:
                  authProvider.errorMessage ??
                  'Facebook login failed. Please try again.',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }
        }
      } else if (result.status == LoginStatus.cancelled) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Facebook login cancelled',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      } else {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Facebook login failed. Please try again.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      }
    } catch (e) {
      Logger.error('Facebook login error', e);
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  /// Handle Google login
  // ignore: unused_element
  Future<void> _handleGoogleLogin() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Initialize Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Trigger Google sign in
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Google login cancelled',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final accessToken = googleAuth.accessToken ?? '';

      Logger.info('Google login successful: ${googleUser.email}');

      // Try social login first (for existing users)
      bool success = await authProvider.socialLogin(
        provider: 'google',
        accessToken: accessToken,
        email: googleUser.email,
        name: googleUser.displayName,
        phone: null,
      );

      if (!success && mounted) {
        // If login fails, try registration (for new users)
        success = await authProvider.socialRegister(
          provider: 'google',
          accessToken: accessToken,
          email: googleUser.email,
          name: googleUser.displayName,
          phone: null,
        );
      }

      if (mounted) {
        if (success) {
          // Check if settings already exist (first time login check)
          final existingSettings = await StorageService.getSettings();
          if (!mounted) return;

          if (existingSettings == null) {
            await _fetchSettingsFirstTime();
            if (!mounted) return;
          }

          final userName = authProvider.currentUser?.name ?? 'User';

          Fluttertoast.showToast(
            msg: 'Welcome $userName! Login successful.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          Navigator.pushReplacementNamed(context, '/main');
        } else {
          Fluttertoast.showToast(
            msg:
                authProvider.errorMessage ??
                'Google login failed. Please try again.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      }
    } catch (e) {
      Logger.error('Google login error', e);
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF), // White background
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Logo - Responsive sizing
                  Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.of(context).size.width *
                            0.4, // 40% of screen width
                        maxHeight:
                            MediaQuery.of(context).size.height *
                            0.15, // 15% of screen height
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback if image fails to load
                          return Icon(
                            Icons.image,
                            size: 80,
                            color: Colors.grey,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Title
                  const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF151D51),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Email Field
                  _buildInputField(
                    controller: _emailController,
                    label: 'Username',
                    icon: Icons.person,
                    placeholder: 'info@example.com',
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

                  const SizedBox(height: 20),

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

                  const SizedBox(height: 8),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to forgot password screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFF151D51),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Log In Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return ElevatedButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF151D51,
                            ), // Button color
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: authProvider.isLoading
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
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Privacy Policy Text
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          color: Color(0xFF151D51).withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        children: [
                          const TextSpan(
                            text: 'By signing up, you agree to our ',
                          ),
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
                  Visibility(
                    visible: false, // Hidden for now
                    child: Row(
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
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
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
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
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
                  ),
                  const SizedBox(height: 30),
                  // Register Link
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          "Didn't have an account? ",
                          style: TextStyle(
                            color: Color(0xFF151D51).withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/signup');
                          },
                          child: const Text(
                            'Register Now',
                            style: TextStyle(
                              color: Colors.black,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String placeholder,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF151D51), // Title font color
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Color(
              0xFFF2F2F4,
            ), // Lighter shade of gray for text box background
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 2.0,
            ), // Add top padding for the input field
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 12.0,
                  ), // Add left padding for icon
                  child: Icon(icon, color: Color(0xFF151D51), size: 20),
                ),
                const SizedBox(width: 20), // Increased padding after icon
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: TextFormField(
                      controller: controller,
                      obscureText: isPassword ? _obscurePassword : false,
                      style: const TextStyle(
                        color: Color(0xFF151D51),
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: placeholder,
                        hintStyle: TextStyle(
                          color: Color(0xFF151D51).withValues(alpha: 0.6),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        suffixIcon: isPassword
                            ? IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Color(0xFF151D51),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              )
                            : null,
                      ),
                      validator: validator,
                    ),
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
