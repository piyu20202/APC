import 'package:flutter/material.dart';
import '../../../services/user_role_service.dart';

class TraderActivationScreen extends StatefulWidget {
  const TraderActivationScreen({super.key});

  @override
  State<TraderActivationScreen> createState() => _TraderActivationScreenState();
}

class _TraderActivationScreenState extends State<TraderActivationScreen> {
  bool _isLoading = false;
  bool _isTrader = false;

  @override
  void initState() {
    super.initState();
    _checkTraderStatus();
  }

  Future<void> _checkTraderStatus() async {
    final isTrader = await UserRoleService.isTraderUser();
    setState(() {
      _isTrader = isTrader;
    });
  }

  Future<void> _activateTraderMode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await UserRoleService.setAsTrader();
      setState(() {
        _isTrader = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trader mode activated successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error activating trader mode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Become a Trader',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF151D51),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: const Color(0xFFF8F8F8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF151D51), Color(0xFF2A3B7A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Join as a Trader',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unlock advanced features and grow your business',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Benefits Section
              const Text(
                'Trader Benefits',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF101010),
                ),
              ),
              const SizedBox(height: 16),

              _buildBenefitCard(
                icon: Icons.inventory_2,
                title: 'Product Management',
                description:
                    'List and manage your products with advanced inventory tools',
                color: const Color(0xFF4CAF50),
              ),

              const SizedBox(height: 12),

              _buildBenefitCard(
                icon: Icons.analytics,
                title: 'Sales Analytics',
                description:
                    'Track your sales performance with detailed analytics and reports',
                color: const Color(0xFF2196F3),
              ),

              const SizedBox(height: 12),

              _buildBenefitCard(
                icon: Icons.payment,
                title: 'Payment Management',
                description:
                    'Manage payments, invoices, and track your earnings',
                color: const Color(0xFFFF9800),
              ),

              const SizedBox(height: 12),

              _buildBenefitCard(
                icon: Icons.people,
                title: 'Customer Management',
                description:
                    'Build and maintain relationships with your customers',
                color: const Color(0xFF9C27B0),
              ),

              const SizedBox(height: 12),

              _buildBenefitCard(
                icon: Icons.local_shipping,
                title: 'Shipping Tools',
                description:
                    'Manage deliveries and track shipments efficiently',
                color: const Color(0xFF607D8B),
              ),

              const SizedBox(height: 24),

              // Requirements Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF2196F3),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Requirements',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF101010),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRequirementItem('Valid business registration'),
                    _buildRequirementItem('Bank account for payments'),
                    _buildRequirementItem('Product catalog or inventory'),
                    _buildRequirementItem('Commitment to quality service'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Button
              if (_isTrader)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'You are already a Trader!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Access your trader dashboard to manage your business.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF101010),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to trader dashboard
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Go to Dashboard'),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _activateTraderMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF151D51),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
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
                            'Activate Trader Mode',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF101010),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF4CAF50),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF101010)),
            ),
          ),
        ],
      ),
    );
  }
}
