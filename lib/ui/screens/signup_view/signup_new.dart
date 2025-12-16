import 'package:flutter/material.dart';
import 'trade_welcome_page.dart';
import 'regular_user_signup.dart';

class SignupScreen extends StatefulWidget {
  final bool autoSelectTrader;

  const SignupScreen({super.key, this.autoSelectTrader = false});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String _selectedUserType = 'regular'; // 'regular' or 'trader'

  @override
  void initState() {
    super.initState();
    // Auto-select trader if coming from upgrade flow
    if (widget.autoSelectTrader) {
      _selectedUserType = 'trader';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Skip button
                const SizedBox(height: 40),

                // Title
                const Text(
                  'Signup',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF151D51),
                  ),
                ),

                const SizedBox(height: 20),

                // User Type Selection
                _buildUserTypeSelector(),

                const SizedBox(height: 20),

                // Dynamic Content Based on User Type
                _selectedUserType == 'trader'
                    ? const TradeWelcomePage()
                    : const RegularUserSignup(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedUserType = 'regular';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedUserType == 'regular'
                        ? const Color(0xFF151D51)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedUserType == 'regular'
                          ? const Color(0xFF151D51)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person,
                        color: _selectedUserType == 'regular'
                            ? Colors.white
                            : const Color(0xFF151D51),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Regular User',
                        style: TextStyle(
                          color: _selectedUserType == 'regular'
                              ? Colors.white
                              : const Color(0xFF151D51),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedUserType = 'trader';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedUserType == 'trader'
                        ? Colors.yellow
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedUserType == 'trader'
                          ? Colors.yellow
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business,
                        color: _selectedUserType == 'trader'
                            ? Colors.black
                            : const Color(0xFF151D51),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Trade User',
                        style: TextStyle(
                          color: _selectedUserType == 'trader'
                              ? Colors.black
                              : const Color(0xFF151D51),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
