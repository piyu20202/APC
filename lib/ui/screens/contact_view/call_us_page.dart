import 'package:flutter/material.dart';
import '../../../services/storage_service.dart';

class CallUsPage extends StatefulWidget {
  final Future<void> Function() onCallTap;

  const CallUsPage({super.key, required this.onCallTap});

  @override
  State<CallUsPage> createState() => _CallUsPageState();
}

class _CallUsPageState extends State<CallUsPage> {
  String _phoneNumber = '';
  String _contactTitle = '';
  String _contactText = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContactDetails();
  }

  Future<void> _loadContactDetails() async {
    final settings = await StorageService.getSettings();
    if (!mounted) return;

    setState(() {
      _phoneNumber = settings?.pageSettings.phone.trim() ?? '';
      _contactTitle = settings?.pageSettings.contactTitle.trim() ?? '';
      _contactText = settings?.pageSettings.contactText.trim() ?? '';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasPhone = _phoneNumber.isNotEmpty;
    final title = _contactTitle.isNotEmpty ? _contactTitle : 'Call Us';
    final description = _contactText.isNotEmpty
        ? _contactText
        : 'Need help? Our support team is available to assist you.';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const Icon(Icons.support_agent, size: 48, color: Color(0xFF151D51)),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 28),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Support Number',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasPhone ? _phoneNumber : 'Not available',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: hasPhone ? widget.onCallTap : null,
              icon: const Icon(Icons.phone),
              label: const Text('Call Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF151D51),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'If calling is unavailable on this device, the phone number is shown above.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
