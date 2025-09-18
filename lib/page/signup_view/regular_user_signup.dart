import 'package:flutter/material.dart';
import '../signin_view/signin.dart';

class RegularUserSignup extends StatefulWidget {
  const RegularUserSignup({super.key});

  @override
  State<RegularUserSignup> createState() => _RegularUserSignupState();
}

class _RegularUserSignupState extends State<RegularUserSignup> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username Field
          _buildInputField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.person,
            placeholder: 'Designing World',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter username';
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
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
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
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Handle sign up logic for regular users
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Regular User account created successfully!')),
                  );
                  // Navigate to sign in screen after successful signup
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SigninScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF151D51),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
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
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SigninScreen()),
                    );
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
                                _obscureText ? Icons.visibility : Icons.visibility_off,
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
