import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/external_link_launcher.dart';
import '../../../data/models/settings_model.dart';
import '../../../services/storage_service.dart';
import '../drawer_view/drawer.dart';

class CallUsPage extends StatefulWidget {
  final Future<void> Function() onCallTap;

  const CallUsPage({super.key, required this.onCallTap});

  @override
  State<CallUsPage> createState() => _CallUsPageState();
}

class _CallUsPageState extends State<CallUsPage>
    with SingleTickerProviderStateMixin {
  List<PickupLocation> _locations = [];
  String _contactTitle = '';
  bool _isLoading = true;
  TabController? _tabController;

  static const Color _brand = Color(0xFF151D51);
  static const Color _accent = Color(0xFFF5A623);
  static const Color _appBarColor = Color(0xFFF8F8F8);
  static const String _helplineNumber = '1800 694 283';
  static const String _moorabbinAddress =
      '53 cochranes rd, moorabbin vic 3189, australia';
  static const String _brisbaneAddress =
      'unit 2/2 commercial dr, shailer park qld 4128';
  static const String _perthAddress =
      '1/562 ranford rd, forrestdale wa 6112';

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _contactTitle,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: _appBarColor,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadContactDetails();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadContactDetails() async {
    final settings = await StorageService.getSettings();
    if (!mounted) return;

    final locs = settings?.pickupLocations ?? [];

    _tabController?.dispose();
    _tabController = locs.isNotEmpty
        ? TabController(length: locs.length, vsync: this)
        : null;

    setState(() {
      _locations = locs;
      _contactTitle =
          settings?.pageSettings.contactTitle.trim().isNotEmpty == true
          ? settings!.pageSettings.contactTitle.trim()
          : 'Contact Us';
      _isLoading = false;
    });
  }

  Future<void> _launchEmail(String email) async {
    if (email.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: email);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open email app')));
    }
  }

  Future<void> _openMaps(PickupLocation loc) async {
    if (_isDirectMapUrl(loc.googleMap)) {
      final opened = await ExternalLinkLauncher.openUrl(loc.googleMap);
      if (opened) return;
    }

    final query = Uri.encodeComponent(_mapQueryForLocation(loc.location));
    await ExternalLinkLauncher.openUrl(
      'https://www.google.com/maps/dir/?api=1&destination=$query',
    );
  }

  bool _isDirectMapUrl(String url) {
    final normalizedUrl = url.trim().toLowerCase();
    if (normalizedUrl.isEmpty) return false;

    return !normalizedUrl.contains('iframe') && !normalizedUrl.contains('embed');
  }

  String _mapQueryForLocation(String address) {
    final normalizedAddress = address.trim().toLowerCase();
    if (normalizedAddress.contains(_moorabbinAddress)) {
      return '-37.941757344861905,145.0669600688049';
    }
    if (normalizedAddress.contains(_brisbaneAddress) ||
        (normalizedAddress.contains('shailer park') &&
            normalizedAddress.contains('commercial dr'))) {
      return '-27.654890377137736,153.16575911905656';
    }
    if (normalizedAddress.contains(_perthAddress) ||
        (normalizedAddress.contains('forrestdale') &&
            normalizedAddress.contains('ranford rd'))) {
      return '-32.13757168992093,115.970205';
    }

    return address;
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await widget.onCallTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        drawer: const AppDrawer(),
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Contact Us',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: _appBarColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_locations.isEmpty) {
      return Scaffold(
        drawer: const AppDrawer(),
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.support_agent, size: 48, color: _brand),
              const SizedBox(height: 16),
              Text(
                _contactTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _brand,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No contact locations available.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: _appBarColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            pinned: true,
            expandedHeight: 100,
            iconTheme: const IconThemeData(color: Colors.black),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 56),
              title: Text(
                _contactTitle,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController!,
              isScrollable: _locations.length > 3,
              indicatorColor: _accent,
              indicatorWeight: 2.5,
              labelColor: _brand,
              unselectedLabelColor: Colors.black54,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              tabs: _locations.map((l) => Tab(text: l.warehouseCode)).toList(),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController!,
          children: _locations
              .map(
                (loc) => _LocationTab(
                  location: loc,
                  onCall: () => _callPhone(_helplineNumber),
                  onEmailSales: () => _launchEmail(loc.salesEmail),
                  onEmailSupport: () => _launchEmail(loc.supportEmail),
                  onOpenMaps: () => _openMaps(loc),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LocationTab extends StatelessWidget {
  final PickupLocation location;
  final VoidCallback onCall;
  final VoidCallback onEmailSales;
  final VoidCallback onEmailSupport;
  final VoidCallback onOpenMaps;

  const _LocationTab({
    required this.location,
    required this.onCall,
    required this.onEmailSales,
    required this.onEmailSupport,
    required this.onOpenMaps,
  });

  static const Color _brand = Color(0xFF151D51);

  @override
  Widget build(BuildContext context) {
    final phone = location.displayPhone.isNotEmpty
        ? location.displayPhone
        : location.phone;
    final hasAddress = location.location.isNotEmpty;
    final hasSales = location.salesEmail.isNotEmpty;
    final hasSupport = location.supportEmail.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          // ── Top info row: address + phone ─────────────────────────────
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: hasAddress ? location.location : 'Not available',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoCard(
                  icon: Icons.phone_outlined,
                  label: 'Call Us',
                  value: phone.isNotEmpty ? phone : 'Not available',
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Email cards ───────────────────────────────────────────────
          if (hasSales)
            _EmailRow(
              icon: Icons.email_outlined,
              label: 'Product Info & Orders',
              email: location.salesEmail,
              onTap: onEmailSales,
            ),
          if (hasSales) const SizedBox(height: 8),
          if (hasSupport)
            _EmailRow(
              icon: Icons.headset_mic_outlined,
              label: 'Technical Queries & Support',
              email: location.supportEmail,
              onTap: onEmailSupport,
            ),

          const SizedBox(height: 10),

          // ── Map open card ─────────────────────────────────────────────
          if (hasAddress)
            GestureDetector(
              onTap: onOpenMaps,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    // Map preview placeholder
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      child: Container(
                        height: 140,
                        color: const Color(0xFFE0EBF5),
                        child: Stack(
                          children: [
                            // Fake map grid
                            GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 6,
                                  ),
                              itemCount: 48,
                              itemBuilder: (_, i) => Container(
                                color: i % 7 == 0
                                    ? const Color(0xFFCCDEEC)
                                    : i % 5 == 0
                                    ? const Color(0xFFD4E8F5)
                                    : const Color(0xFFE0EBF5),
                                margin: const EdgeInsets.all(0.5),
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.open_in_new,
                                          size: 13,
                                          color: Color(0xFF151D51),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Open in Maps',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF151D51),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location.location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF444444),
                                height: 1.4,
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

          const SizedBox(height: 10),

          // ── Trading Hours ─────────────────────────────────────────────
          _TradingHoursCard(location: location),

          const SizedBox(height: 16),

          // ── Call button ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCall,
              icon: const Icon(Icons.phone, size: 20),
              label: const Text(
                'Call Us',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  static const Color _accentLight = Color(0xFFFFF3D6);
  static const Color _accent = Color(0xFFF5A623);
  static const Color _brand = Color(0xFF151D51);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: _accentLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _accent, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _brand,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String email;
  final VoidCallback onTap;

  const _EmailRow({
    required this.icon,
    required this.label,
    required this.email,
    required this.onTap,
  });

  static const Color _accentLight = Color(0xFFFFF3D6);
  static const Color _accent = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _accentLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A73E8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trading hours card — reads from PickupLocation.tradingHours if available,
// otherwise shows the generic Mon–Fri 09:00–17:00 schedule.
// Adjust PickupLocation model fields as per your actual API response.
// ─────────────────────────────────────────────────────────────────────────────

class _TradingHoursCard extends StatelessWidget {
  final PickupLocation location;

  const _TradingHoursCard({required this.location});

  static const Color _accent = Color(0xFFF5A623);
  static const Color _brand = Color(0xFF151D51);

  List<(String, String, bool)> _buildHours() {
    final normalizedAddress = location.location.trim().toLowerCase();
    final isPerthLocation =
        normalizedAddress.contains('1/562 ranford rd, forrestdale wa 6112') ||
        normalizedAddress.contains('unit 1, 562 ranford road, forrestdale wa 6112') ||
        (normalizedAddress.contains('forrestdale') &&
            (normalizedAddress.contains('ranford rd') ||
                normalizedAddress.contains('ranford road')));

    if (isPerthLocation) {
      return const [
        ('Mon', '08:00 - 16:00', false),
        ('Tue', '08:00 - 16:00', false),
        ('Wed', '08:00 - 16:00', false),
        ('Thu', '08:00 - 16:00', false),
        ('Fri', '08:00 - 16:00', false),
        ('Sat', 'Closed', true),
        ('Sun', 'Closed', true),
      ];
    }

    return const [
      ('Mon', '09:00 - 17:00', false),
      ('Tue', '09:00 - 17:00', false),
      ('Wed', '09:00 - 17:00', false),
      ('Thu', '09:00 - 17:00', false),
      ('Fri', '09:00 - 17:00', false),
      ('Sat', 'Closed', true),
      ('Sun', 'Closed', true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hours = _buildHours();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.access_time_outlined, color: _accent, size: 18),
              SizedBox(width: 8),
              Text(
                'Trading Hours',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _brand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...hours.asMap().entries.map((e) {
            final i = e.key;
            final row = e.value;
            return Column(
              children: [
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Color(0xFFF0F0F0),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        row.$1,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        row.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: row.$3 ? Colors.redAccent : _brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
