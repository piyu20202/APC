import 'package:flutter/material.dart';
import '../../../services/user_role_service.dart';
import '../signup_view/trader_upgrade_flow.dart';

class TraderBenefitsShowcase extends StatefulWidget {
  const TraderBenefitsShowcase({super.key});

  @override
  State<TraderBenefitsShowcase> createState() => _TraderBenefitsShowcaseState();
}

class _TraderBenefitsShowcaseState extends State<TraderBenefitsShowcase> {
  bool _isTrader = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTraderStatus();
  }

  Future<void> _checkTraderStatus() async {
    final isTrader = await UserRoleService.isTraderUser();
    setState(() {
      _isTrader = isTrader;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // Don't show if user is already a trader
    if (_isTrader) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange.shade400, Colors.orange.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upgrade to Trade Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Unlock exclusive benefits for professionals',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TraderBenefitsInfoScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Benefits List
            _buildBenefitItem(
              Icons.local_offer,
              'Exclusive Trade Pricing',
              'Get special wholesale rates',
            ),
            const SizedBox(height: 8),
            _buildBenefitItem(
              Icons.speed,
              'Priority Support',
              'Fast-track customer service',
            ),
            const SizedBox(height: 8),
            _buildBenefitItem(
              Icons.inventory,
              'Bulk Ordering',
              'Order in larger quantities',
            ),
            const SizedBox(height: 8),
            _buildBenefitItem(
              Icons.description,
              'Technical Resources',
              'Access manuals and guides',
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const TraderBenefitsInfoScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Learn More',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const TraderUpgradeFlow(isExistingUser: true),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Upgrade Now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TraderBenefitsInfoScreen extends StatelessWidget {
  const TraderBenefitsInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trade Account Benefits',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Why Upgrade to Trade Account?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join thousands of professionals who trust us for their business needs',
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
              'Exclusive Benefits',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF151D51),
              ),
            ),
            const SizedBox(height: 16),

            _buildDetailedBenefit(
              Icons.local_offer,
              'Exclusive Trade Pricing',
              'Get access to wholesale pricing that can save you up to 30% on your orders. Perfect for businesses and professionals who buy in bulk.',
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildDetailedBenefit(
              Icons.speed,
              'Priority Customer Support',
              'Skip the queue with dedicated trade support. Get faster response times and expert assistance for your business needs.',
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildDetailedBenefit(
              Icons.inventory,
              'Bulk Ordering & Inventory',
              'Order larger quantities with special bulk pricing. Access to inventory levels and stock availability for better planning.',
              Colors.purple,
            ),
            const SizedBox(height: 16),
            _buildDetailedBenefit(
              Icons.description,
              'Technical Resources & Manuals',
              'Access to comprehensive technical documentation, installation guides, and product manuals to support your projects.',
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildDetailedBenefit(
              Icons.account_balance,
              'Credit Terms (Qualified Accounts)',
              'Eligible trade accounts can access credit terms to help manage cash flow and grow your business operations.',
              Colors.teal,
            ),
            const SizedBox(height: 16),
            _buildDetailedBenefit(
              Icons.delivery_dining,
              'Dedicated Account Management',
              'Get personalized service with dedicated account managers who understand your business and can provide tailored solutions.',
              Colors.indigo,
            ),

            const SizedBox(height: 24),

            // Who Can Apply Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Who Can Apply?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildEligibilityItem(
                    '• Automatic gate and boom gate installers',
                  ),
                  _buildEligibilityItem(
                    '• Security installers and electricians',
                  ),
                  _buildEligibilityItem(
                    '• Builders and construction professionals',
                  ),
                  _buildEligibilityItem(
                    '• Retail/wholesale supply chain professionals',
                  ),
                  _buildEligibilityItem('• Integrators and system installers'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Application Process
            const Text(
              'Simple Application Process',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF151D51),
              ),
            ),
            const SizedBox(height: 16),

            _buildProcessStep(
              '1',
              'Complete Application',
              'Fill out our simple online form with your business details',
            ),
            _buildProcessStep(
              '2',
              'Verification',
              'We review your application and verify your business credentials',
            ),
            _buildProcessStep(
              '3',
              'Account Activation',
              'Get approved and start enjoying trade benefits immediately',
            ),

            // Ready to Upgrade section is hidden
            // const SizedBox(height: 32),

            // // CTA Section
            // Container(
            //   width: double.infinity,
            //   padding: const EdgeInsets.all(24),
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     borderRadius: BorderRadius.circular(16),
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.grey.withValues(alpha: 0.1),
            //         spreadRadius: 2,
            //         blurRadius: 8,
            //         offset: const Offset(0, 4),
            //       ),
            //     ],
            //   ),
            //   child: Column(
            //     children: [
            //       const Text(
            //         'Ready to Upgrade?',
            //         style: TextStyle(
            //           fontSize: 20,
            //           fontWeight: FontWeight.bold,
            //           color: Color(0xFF151D51),
            //         ),
            //       ),
            //       const SizedBox(height: 8),
            //       Text(
            //         'Join our community of professional traders today',
            //         style: TextStyle(color: Colors.grey[600], fontSize: 16),
            //         textAlign: TextAlign.center,
            //       ),
            //       const SizedBox(height: 20),
            //       SizedBox(
            //         width: double.infinity,
            //         child: ElevatedButton(
            //           onPressed: () {
            //             Navigator.push(
            //               context,
            //               MaterialPageRoute(
            //                 builder: (context) => const TradeWelcomePage(),
            //               ),
            //             );
            //           },
            //           style: ElevatedButton.styleFrom(
            //             backgroundColor: Colors.orange.shade600,
            //             foregroundColor: Colors.white,
            //             shape: RoundedRectangleBorder(
            //               borderRadius: BorderRadius.circular(12),
            //             ),
            //             padding: const EdgeInsets.symmetric(vertical: 16),
            //           ),
            //           child: const Text(
            //             'Start Trade Application',
            //             style: TextStyle(
            //               fontSize: 16,
            //               fontWeight: FontWeight.bold,
            //             ),
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedBenefit(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
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
                    color: Color(0xFF151D51),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, color: Colors.blue.shade700),
      ),
    );
  }

  Widget _buildProcessStep(String number, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
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
                    color: Color(0xFF151D51),
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
}
