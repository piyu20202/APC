import 'package:flutter/material.dart';
import 'register_traderuser.dart';
import '../../../services/storage_service.dart';

class TradeWelcomePage extends StatefulWidget {
  const TradeWelcomePage({super.key});

  @override
  State<TradeWelcomePage> createState() => _TradeWelcomePageState();
}

class _TradeWelcomePageState extends State<TradeWelcomePage> {
  bool _agreeToTerms = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main card content
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.yellow.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Welcome Header
              Row(
                children: [
                  Icon(Icons.business, color: Colors.orange, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Welcome to Our New Trade Website!',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Welcome Message
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: 'Hey there! If you\'re an '),
                    TextSpan(
                      text: 'installer or wholesaler',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          ' in our industry, you\'re in the right place. To keep things running smoothly for our existing installers and resellers, all new registrations go through a ',
                    ),
                    TextSpan(
                      text: 'quick confirmation and validation process',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Who can register section
              Text(
                'Who can register?',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeListItem(
                      '• Automatic gate and boom gate installers (including gate and fencing fabricators)',
                    ),
                    _buildWelcomeListItem('• Security installers'),
                    _buildWelcomeListItem('• Electricians'),
                    _buildWelcomeListItem('• Integrators'),
                    _buildWelcomeListItem('• Builders'),
                    _buildWelcomeListItem(
                      '• Retail/wholesale supply chain professionals',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Important notes
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: 'To avoid any hiccups, please '),
                    TextSpan(
                      text:
                          'fill out the application form completely and accurately',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' — incomplete forms may be rejected.'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'A few important things to note:',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeListItem(
                      '• We don\'t offer credit terms.',
                      isBold: true,
                    ),
                    _buildWelcomeListItemWithBold(
                      '• If you\'re placing a one-off or occasional order, please use our regular website ordering process to avoid delays.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Thank you for your understanding — we\'re excited to have you on board!',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 24),

              // Terms checkbox
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreeToTerms = value ?? false;
                      });
                    },
                    activeColor: Colors.yellow,
                    checkColor: Colors.black,
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.black87, fontSize: 14),
                        children: [
                          const TextSpan(text: 'I agree to the '),
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

              // Green registration button (always visible but disabled until checkbox is checked)
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _agreeToTerms
                      ? () {
                          _handleRegistrationButton();
                        }
                      : () {
                          // Show message when button is disabled
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please accept the terms and conditions to enable this button',
                              ),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _agreeToTerms ? Colors.green : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Accept And Proceed For Registration',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // External buttons (outside the card)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/main');
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
                  'CLICK HERE FOR HOMEPAGE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _handleLoginButton();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'LOGIN TO TRADE ACCOUNT',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeListItem(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildWelcomeListItemWithBold(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(text: '• If you\'re placing a '),
            TextSpan(
              text: 'one-off or occasional order',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ', please use our '),
            TextSpan(
              text: 'regular website ordering process',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' to avoid delays.'),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegistrationButton() async {
    // Check if user is already logged in
    final isLoggedIn = await StorageService.isLoggedIn();
    
    if (isLoggedIn) {
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Already Logged In',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF151D51),
              ),
            ),
            content: const Text(
              'You are already logged in. Do you want to logout and proceed with registration?',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text(
                  'No',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Yes, Logout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );

      if (shouldLogout == true) {
        // Logout user
        await StorageService.clearLoginData();
        
        // Navigate to registration page
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegisterTraderUserPage(),
            ),
          );
        }
      }
    } else {
      // User is not logged in, directly navigate to registration
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RegisterTraderUserPage(),
        ),
      );
    }
  }

  Future<void> _handleLoginButton() async {
    // Check if user is already logged in
    final isLoggedIn = await StorageService.isLoggedIn();
    
    if (isLoggedIn) {
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Already Logged In',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF151D51),
              ),
            ),
            content: const Text(
              'You are already logged in. Do you want to logout and proceed to login page?',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text(
                  'No',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Yes, Logout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );

      if (shouldLogout == true) {
        // Logout user
        await StorageService.clearLoginData();
        
        // Navigate to login page
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/signin');
        }
      }
    } else {
      // User is not logged in, directly navigate to login
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }
}
