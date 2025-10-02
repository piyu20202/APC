import 'package:flutter/material.dart';
import '../signup_view/signup_new.dart';
import '../forgotpassword_view/forgotpassword.dart';
import '../../main_navigation.dart';

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
                  const SizedBox(height: 40),
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
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
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
                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
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
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate directly to main navigation screen
                        Navigator.pushReplacementNamed(context, '/main');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF151D51), // Button color
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                Row(
                  children: [
                    Expanded(
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
                              Icons.apple,
                              size: 24,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Apple',
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
                    const SizedBox(width: 16),
                    Expanded(
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
                  ],
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
                            color: Color(0xFF151D51).withOpacity(0.7),
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
            color: Color(0xFFF2F2F4), // Lighter shade of gray for text box background
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0), // Add top padding for the input field
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12.0), // Add left padding for icon
                  child: Icon(
                    icon,
                    color: Color(0xFF151D51),
                    size: 20,
                  ),
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
                          color: Color(0xFF151D51).withOpacity(0.6),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        suffixIcon: isPassword
                            ? IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
