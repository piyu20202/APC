import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../providers/auth_provider.dart';
import '../../../data/services/settings_service.dart';
import '../../../data/services/payment_config_service.dart';
import '../../../services/storage_service.dart';
import '../../../core/utils/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final restored = await authProvider.restoreSession();

    if (!mounted) return;

    // Fetch settings from API after splash screen
    await _fetchSettings();

    if (!mounted) return;
    if (restored && authProvider.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  /// Fetch settings from API right after splash screen
  Future<void> _fetchSettings() async {
    try {
      // Check if settings already exist
      final existingSettings = await StorageService.getSettings();

      if (existingSettings != null) {
        Logger.info('Settings already cached, skipping fetch');
        return;
      }

      Logger.info('Fetching settings from API after splash screen');

      final settingsService = SettingsService();
      final settings = await settingsService.getSettings();

      // Save settings to shared preferences
      await StorageService.saveSettings(settings);

      // Fetch and save payment configurations
      await PaymentConfigService.fetchAndSaveConfig();

      Logger.info('Settings fetched and saved successfully from splash screen');
    } catch (e) {
      Logger.error('Failed to fetch settings from splash screen', e);
      // Don't block the navigation if settings fetch fails
      // Settings can be fetched later or user can continue without them
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Use your app's primary color
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF), // Use your app's primary color
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo image
            Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/logo.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 20),
            // Loading text
            const Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
