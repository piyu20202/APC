import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../ui/screens/signin_view/signin.dart';
import '../providers/auth_provider.dart';

class UserDeletePage extends StatefulWidget {
  const UserDeletePage({super.key});

  @override
  State<UserDeletePage> createState() => _UserDeletePageState();
}

class _UserDeletePageState extends State<UserDeletePage> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmationModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text(
                'Confirm Deletion',
                style: TextStyle(
                  color: Color(0xFF1A365D),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please enter your password to confirm.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Enter your password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                final password = _passwordController.text.trim();
                                if (password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter your password.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setStateModal(() {
                                  _isLoading = true;
                                });

                                try {
                                  final response = await ApiClient.post(
                                    endpoint: ApiEndpoints.deleteAccount,
                                    body: {'password': password},
                                    contentType: 'application/json',
                                    requireAuth: true,
                                  );

                                  // API call successful
                                  if (!dialogContext.mounted) return;
                                  Navigator.pop(dialogContext); // Close modal
                                  
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(response['message'] ?? 'Your account has been deleted successfully.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );

                                  // Perform logout
                                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                  await authProvider.logout();

                                  if (!context.mounted) return;
                                  // Navigate to signin screen
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SigninScreen(),
                                    ),
                                    (route) => false,
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString().replaceAll('Exception: ', '')),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setStateModal(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('DELETE'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF151D51),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Delete User',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We respect your privacy and your right to control your personal data. If you would like to delete your Automotion Plus account, you can request deletion using the form below.',
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
              _buildSectionTitle('What Happens When You Request Deletion?'),
              _buildBulletPoint('Your account will be deactivated immediately'),
              _buildBulletPoint('Your personal data will be scheduled for permanent deletion after a cooling-off period'),
              _buildBulletPoint('You can cancel your deletion request during this period'),
              _buildSectionTitle('Cooling-Off Period'),
              const Text(
                'Once you submit a deletion request, your account enters a cooling-off period of 14 days. During this time:',
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Your account remains inactive'),
              _buildBulletPoint('You may contact us to cancel the deletion request'),
              const SizedBox(height: 8),
              const Text(
                'After this period, your data will be permanently deleted and cannot be recovered.',
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
              _buildSectionTitle('What Data Will Be Deleted?'),
              const Text(
                'We will permanently delete:',
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('User-Name'),
              _buildBulletPoint('Name'),
              _buildBulletPoint('Email address'),
              _buildBulletPoint('Phone number'),
              _buildBulletPoint('Address'),
              _buildBulletPoint('Account activity and preferences'),
              _buildSectionTitle('What Data Will Be Retained?'),
              const Text(
                'We may retain certain information where required by law, including:',
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Invoice and transaction records (for accounting and legal compliance)'),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showDeleteConfirmationModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'DELETE ACCOUNT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
