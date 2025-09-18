import 'package:flutter/material.dart';
import 'dart:async';
import '../signup_view/signup_new.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Create fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // Create scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Start animation
    _animationController.forward();

    // Navigate to signup screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignupScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                                         // Logo container with transparent background
                     Container(
                       width: 200,
                       height: 100,
                       child: Image.asset(
                         'assets/images/logo.png',
                         fit: BoxFit.contain,
                         errorBuilder: (context, error, stackTrace) {
                           // Fallback widget if image fails to load
                           return Container(
                             decoration: BoxDecoration(
                               gradient: const LinearGradient(
                                 begin: Alignment.topLeft,
                                 end: Alignment.bottomRight,
                                 colors: [
                                   Color(0xFF1a237e), // Dark blue
                                   Color(0xFF0d47a1),
                                 ],
                               ),
                               borderRadius: BorderRadius.circular(10),
                             ),
                             child: const Center(
                               child: Icon(
                                 Icons.business,
                                 size: 50,
                                 color: Color(0xFFFFD700), // Golden yellow
                               ),
                             ),
                           );
                         },
                       ),
                     ),
                    
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
